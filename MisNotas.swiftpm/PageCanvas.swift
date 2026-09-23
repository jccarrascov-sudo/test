import SwiftUI
import PencilKit

/// Da acceso al lienzo desde los botones de SwiftUI (deshacer / rehacer).
final class CanvasController: ObservableObject {
    weak var canvas: PKCanvasView?

    func undo() { canvas?.undoManager?.undo() }
    func redo() { canvas?.undoManager?.redo() }
}

// MARK: - Fondo de la hoja

final class PaperView: UIView {
    var style: PaperStyle = .blank {
        didSet { if oldValue != style { setNeedsLayout() } }
    }

    private let linesLayer = CAShapeLayer()
    private let marginLayer = CAShapeLayer()
    private let dotsLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        isUserInteractionEnabled = false

        linesLayer.fillColor = nil
        linesLayer.strokeColor = PaperStyle.lineColor.cgColor
        marginLayer.fillColor = nil
        marginLayer.strokeColor = PaperStyle.marginColor.cgColor
        dotsLayer.fillColor = PaperStyle.dotColor.cgColor

        layer.addSublayer(linesLayer)
        layer.addSublayer(marginLayer)
        layer.addSublayer(dotsLayer)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no se usa") }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Capas vectoriales: se ven nítidas con cualquier zoom sin gastar memoria.
        let paths = style.paths(for: bounds.size)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        linesLayer.path = paths.lines
        linesLayer.lineWidth = paths.lineWidth
        marginLayer.path = paths.margin
        marginLayer.lineWidth = paths.lineWidth
        dotsLayer.path = paths.dots
        CATransaction.commit()
    }
}

// MARK: - Lienzo con tamaño de hoja y zoom

final class PageCanvasView: PKCanvasView {
    let paper = PaperView()

    /// Espacio que ocupan las barras de vidrio arriba y abajo; la hoja pasa por debajo al hacer scroll.
    var chromeInsets: UIEdgeInsets = .zero {
        didSet { if oldValue != chromeInsets { fittedWidth = 0; setNeedsLayout() } }
    }

    private let pageMargin: CGFloat = 20
    private var fittedWidth: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        // La hoja siempre en modo claro, para que los colores de la tinta sean los reales.
        overrideUserInterfaceStyle = .light
        // Fondo transparente: detrás se ve el degradado de la app.
        backgroundColor = .clear
        isOpaque = false
        alwaysBounceVertical = true
        contentInsetAdjustmentBehavior = .never

        paper.layer.shadowColor = UIColor.black.cgColor
        paper.layer.shadowOpacity = 0.16
        paper.layer.shadowRadius = 18
        paper.layer.shadowOffset = CGSize(width: 0, height: 8)
        insertSubview(paper, at: 0)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no se usa") }

    override func layoutSubviews() {
        super.layoutSubviews()

        // La hoja ocupa el ancho (con un margen); con dos dedos se puede hacer zoom hasta 4x.
        if bounds.width > 0, bounds.width != fittedWidth {
            fittedWidth = bounds.width
            contentInset = UIEdgeInsets(
                top: chromeInsets.top + 16,
                left: pageMargin,
                bottom: chromeInsets.bottom + 24,
                right: pageMargin
            )
            let fit = (bounds.width - pageMargin * 2) / Page.size.width
            minimumZoomScale = fit
            maximumZoomScale = fit * 4
            zoomScale = fit
            contentOffset = CGPoint(x: -contentInset.left, y: -contentInset.top)
        }

        let size = CGSize(width: Page.size.width * zoomScale, height: Page.size.height * zoomScale)
        if contentSize != size { contentSize = size }
        if paper.frame.size != size {
            paper.frame = CGRect(origin: .zero, size: size)
            paper.layer.shadowPath = UIBezierPath(rect: paper.bounds).cgPath
        }
        sendSubviewToBack(paper)
    }

    func scrollToTop() {
        zoomScale = minimumZoomScale
        contentOffset = CGPoint(x: -contentInset.left, y: -contentInset.top)
    }
}

// MARK: - Puente SwiftUI

struct PageCanvas: UIViewRepresentable {
    let page: Page
    let pencilOnly: Bool
    var chromeInsets: UIEdgeInsets = .zero
    let controller: CanvasController
    let onDrawingChange: (UUID, Data) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> PageCanvasView {
        let canvas = PageCanvasView()
        canvas.chromeInsets = chromeInsets
        canvas.delegate = context.coordinator
        canvas.drawingPolicy = pencilOnly ? .pencilOnly : .anyInput
        canvas.tool = PKInkingTool(.pen, color: .black, width: 4)
        context.coordinator.load(page, into: canvas)
        controller.canvas = canvas

        // La paleta de Apple: lapicero, lápiz, resaltador, borrador, lazo, regla y colores.
        let picker = context.coordinator.toolPicker
        picker.addObserver(canvas)
        picker.setVisible(true, forFirstResponder: canvas)
        DispatchQueue.main.async { canvas.becomeFirstResponder() }
        return canvas
    }

    func updateUIView(_ canvas: PageCanvasView, context: Context) {
        context.coordinator.parent = self
        canvas.chromeInsets = chromeInsets
        canvas.drawingPolicy = pencilOnly ? .pencilOnly : .anyInput

        if context.coordinator.pageID != page.id {
            context.coordinator.load(page, into: canvas)
            canvas.undoManager?.removeAllActions()
            canvas.scrollToTop()
        }
        canvas.paper.style = page.style

        // Al cerrar una hoja emergente, vuelve a mostrar la paleta de herramientas.
        if canvas.window != nil, !canvas.isFirstResponder {
            DispatchQueue.main.async { canvas.becomeFirstResponder() }
        }
    }

    static func dismantleUIView(_ canvas: PageCanvasView, coordinator: Coordinator) {
        coordinator.toolPicker.setVisible(false, forFirstResponder: canvas)
        coordinator.toolPicker.removeObserver(canvas)
        canvas.resignFirstResponder()
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: PageCanvas
        let toolPicker = PKToolPicker()
        private(set) var pageID: UUID?
        private var isLoading = false

        init(_ parent: PageCanvas) {
            self.parent = parent
        }

        func load(_ page: Page, into canvas: PageCanvasView) {
            isLoading = true
            pageID = page.id
            canvas.drawing = page.drawing
            canvas.paper.style = page.style
            isLoading = false
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            guard !isLoading, let id = pageID else { return }
            parent.onDrawingChange(id, canvasView.drawing.dataRepresentation())
        }
    }
}
