import SwiftUI

struct ExportFile: Identifiable {
    let id = UUID()
    let url: URL
}

enum PDFExporter {
    /// Crea un PDF tamaño A4 con todas las páginas del cuaderno.
    static func export(_ notebook: Notebook) throws -> URL {
        let a4 = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let k = a4.width / Page.size.width

        let forbidden = CharacterSet(charactersIn: "/\\:?*\"<>|")
        var name = notebook.title.components(separatedBy: forbidden).joined(separator: "-")
        if name.trimmingCharacters(in: .whitespaces).isEmpty { name = "Cuaderno" }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(name).pdf")

        let renderer = UIGraphicsPDFRenderer(bounds: a4)
        try renderer.writePDF(to: url) { context in
            for page in notebook.pages {
                context.beginPage()
                let cg = context.cgContext
                cg.saveGState()
                cg.scaleBy(x: k, y: k)
                page.style.render(in: cg, size: Page.size)
                page.drawing.lightImage(scale: 2).draw(in: CGRect(origin: .zero, size: Page.size))
                cg.restoreGState()
            }
        }
        return url
    }
}

/// Hoja de "Compartir" de iOS (guardar en Archivos, AirDrop, WhatsApp, etc.).
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
