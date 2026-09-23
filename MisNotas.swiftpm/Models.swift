import SwiftUI
import PencilKit

// MARK: - Tipo de hoja

enum PaperStyle: String, Codable, CaseIterable, Identifiable {
    case blank
    case lined
    case grid
    case dotted

    var id: String { rawValue }

    var name: String {
        switch self {
        case .blank: "En blanco"
        case .lined: "Con líneas"
        case .grid: "Cuadriculada"
        case .dotted: "Punteada"
        }
    }

    var icon: String {
        switch self {
        case .blank: "doc"
        case .lined: "text.justify"
        case .grid: "squareshape.split.3x3"
        case .dotted: "circle.grid.3x3"
        }
    }

    static let lineColor = UIColor(red: 0.64, green: 0.76, blue: 0.90, alpha: 1)
    static let marginColor = UIColor(red: 0.93, green: 0.52, blue: 0.52, alpha: 1)
    static let dotColor = UIColor(white: 0.68, alpha: 1)

    struct Paths {
        var lines: CGPath?
        var margin: CGPath?
        var dots: CGPath?
        var lineWidth: CGFloat
    }

    /// Trazos del fondo para una hoja dibujada a `size`. Todo se escala respecto a `Page.size`,
    /// así se ve igual en pantalla (con zoom) y en el PDF.
    func paths(for size: CGSize) -> Paths {
        let s = size.width / Page.size.width
        let spacing = 40 * s
        var result = Paths(lineWidth: max(0.5, 1.2 * s))

        switch self {
        case .blank:
            break

        case .lined:
            let lines = CGMutablePath()
            var y = 150 * s
            while y < size.height - 40 * s {
                lines.move(to: CGPoint(x: 0, y: y))
                lines.addLine(to: CGPoint(x: size.width, y: y))
                y += spacing
            }
            result.lines = lines

            let margin = CGMutablePath()
            margin.move(to: CGPoint(x: 110 * s, y: 0))
            margin.addLine(to: CGPoint(x: 110 * s, y: size.height))
            result.margin = margin

        case .grid:
            let lines = CGMutablePath()
            var x = spacing
            while x < size.width {
                lines.move(to: CGPoint(x: x, y: 0))
                lines.addLine(to: CGPoint(x: x, y: size.height))
                x += spacing
            }
            var y = spacing
            while y < size.height {
                lines.move(to: CGPoint(x: 0, y: y))
                lines.addLine(to: CGPoint(x: size.width, y: y))
                y += spacing
            }
            result.lines = lines
            result.lineWidth = max(0.5, 0.8 * s)

        case .dotted:
            let dots = CGMutablePath()
            let r = 2 * s
            var y = spacing
            while y < size.height {
                var x = spacing
                while x < size.width {
                    dots.addEllipse(in: CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r))
                    x += spacing
                }
                y += spacing
            }
            result.dots = dots
        }
        return result
    }

    /// Dibuja el fondo en un contexto (miniaturas y PDF).
    func render(in ctx: CGContext, size: CGSize) {
        let p = paths(for: size)
        ctx.saveGState()
        ctx.setLineWidth(p.lineWidth)
        if let lines = p.lines {
            ctx.addPath(lines)
            ctx.setStrokeColor(Self.lineColor.cgColor)
            ctx.strokePath()
        }
        if let margin = p.margin {
            ctx.addPath(margin)
            ctx.setStrokeColor(Self.marginColor.cgColor)
            ctx.strokePath()
        }
        if let dots = p.dots {
            ctx.addPath(dots)
            ctx.setFillColor(Self.dotColor.cgColor)
            ctx.fillPath()
        }
        ctx.restoreGState()
    }
}

// MARK: - Página

struct Page: Identifiable, Codable, Hashable {
    /// Tamaño lógico de cada hoja (proporción A4).
    static let size = CGSize(width: 1000, height: 1414)

    var id = UUID()
    var style: PaperStyle
    var drawingData = Data()

    var drawing: PKDrawing {
        (try? PKDrawing(data: drawingData)) ?? PKDrawing()
    }

    func thumbnail(width: CGFloat) -> UIImage {
        let scale = width / Page.size.width
        let size = CGSize(width: width, height: Page.size.height * scale)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            style.render(in: ctx.cgContext, size: size)
            drawing.lightImage(scale: scale * 2).draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

extension PKDrawing {
    /// Imagen de la hoja completa con los colores reales (sin el ajuste de modo oscuro).
    func lightImage(scale: CGFloat) -> UIImage {
        var image = UIImage()
        UITraitCollection(userInterfaceStyle: .light).performAsCurrent {
            image = self.image(from: CGRect(origin: .zero, size: Page.size), scale: scale)
        }
        return image
    }
}

// MARK: - Cuaderno

struct Notebook: Identifiable, Codable, Hashable {
    static let covers: [Color] = [.indigo, .pink, .teal, .orange, .green, .purple, .blue, .red]
    static let coverNames = ["Índigo", "Rosado", "Turquesa", "Naranja", "Verde", "Morado", "Azul", "Rojo"]

    var id = UUID()
    var title: String
    var coverIndex: Int
    var createdAt = Date()
    var updatedAt = Date()
    var pages: [Page]

    var cover: Color {
        Notebook.covers[coverIndex % Notebook.covers.count]
    }

    /// Agrega una hoja nueva después de `index` y devuelve su posición.
    mutating func addPage(after index: Int) -> Int {
        let style = pages.indices.contains(index) ? pages[index].style : .lined
        let newIndex = min(index + 1, pages.count)
        pages.insert(Page(style: style), at: newIndex)
        return newIndex
    }

    mutating func duplicatePage(at index: Int) -> Int {
        var copy = pages[index]
        copy.id = UUID()
        pages.insert(copy, at: index + 1)
        return index + 1
    }

    /// Borra la hoja `index` y devuelve cuál debería quedar seleccionada.
    mutating func deletePage(at index: Int, current: Int) -> Int {
        guard pages.count > 1, pages.indices.contains(index) else { return current }
        pages.remove(at: index)
        let adjusted = index < current ? current - 1 : current
        return min(adjusted, pages.count - 1)
    }
}
