import SwiftUI

/// Guarda cada cuaderno como un archivo JSON dentro de la app (carpeta Documentos/Cuadernos).
final class NotebookStore: ObservableObject {
    @Published private(set) var notebooks: [Notebook] = []

    private let folder: URL
    private var pendingSaves: [UUID: DispatchWorkItem] = [:]

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        folder = documents.appendingPathComponent("Cuadernos", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        load()
    }

    // MARK: Consultas

    func binding(for id: UUID) -> Binding<Notebook>? {
        guard let initial = notebooks.first(where: { $0.id == id }) else { return nil }
        return Binding(
            get: { [weak self] in self?.notebooks.first(where: { $0.id == id }) ?? initial },
            set: { [weak self] in self?.update($0) }
        )
    }

    // MARK: Cambios

    @discardableResult
    func create(title: String, coverIndex: Int, style: PaperStyle) -> Notebook {
        let notebook = Notebook(title: title, coverIndex: coverIndex, pages: [Page(style: style)])
        notebooks.insert(notebook, at: 0)
        write(notebook)
        return notebook
    }

    func update(_ notebook: Notebook) {
        guard let index = notebooks.firstIndex(where: { $0.id == notebook.id }) else { return }
        var notebook = notebook
        notebook.updatedAt = Date()
        notebooks[index] = notebook
        scheduleSave(notebook)
    }

    func delete(_ notebook: Notebook) {
        pendingSaves.removeValue(forKey: notebook.id)?.cancel()
        notebooks.removeAll { $0.id == notebook.id }
        try? FileManager.default.removeItem(at: url(for: notebook.id))
    }

    /// Escribe de inmediato lo que esté pendiente (por ejemplo, al cerrar la app).
    func saveNow() {
        let items = pendingSaves.values
        pendingSaves.removeAll()
        for item in items {
            item.perform()
            item.cancel()
        }
    }

    // MARK: Disco

    private func url(for id: UUID) -> URL {
        folder.appendingPathComponent("\(id.uuidString).json")
    }

    private func load() {
        let files = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
        let decoder = JSONDecoder()
        notebooks = files
            .filter { $0.pathExtension == "json" }
            .compactMap { file in
                guard let data = try? Data(contentsOf: file) else { return nil }
                return try? decoder.decode(Notebook.self, from: data)
            }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    /// Espera un ratito antes de guardar para no escribir en disco en cada trazo.
    private func scheduleSave(_ notebook: Notebook) {
        pendingSaves[notebook.id]?.cancel()
        let item = DispatchWorkItem { [weak self] in
            self?.write(notebook)
        }
        pendingSaves[notebook.id] = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard !item.isCancelled else { return }
            item.perform()
            self?.pendingSaves.removeValue(forKey: notebook.id)
        }
    }

    private func write(_ notebook: Notebook) {
        do {
            let data = try JSONEncoder().encode(notebook)
            try data.write(to: url(for: notebook.id), options: .atomic)
        } catch {
            print("No se pudo guardar \(notebook.title): \(error)")
        }
    }
}
