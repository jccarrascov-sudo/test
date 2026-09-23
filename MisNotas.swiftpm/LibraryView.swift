import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var store: NotebookStore

    @State private var path: [UUID] = []
    @State private var showingNew = false
    @State private var pendingOpen: UUID?
    @State private var renaming: Notebook?
    @State private var newTitle = ""
    @State private var deleting: Notebook?
    @State private var search = ""

    private let columns = [GridItem(.adaptive(minimum: 160, maximum: 210), spacing: 28)]

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if store.notebooks.isEmpty {
                    emptyState(
                        icon: "book.closed",
                        title: "Aún no tienes cuadernos",
                        message: "Toca “Nuevo cuaderno” para empezar."
                    )
                } else if filtered.isEmpty {
                    emptyState(
                        icon: "magnifyingglass",
                        title: "Sin resultados",
                        message: "No hay cuadernos que se llamen “\(search)”."
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 32) {
                            ForEach(filtered) { notebook in
                                NavigationLink(value: notebook.id) {
                                    NotebookCover(notebook: notebook)
                                }
                                .buttonStyle(.plain)
                                .contextMenu { menu(for: notebook) }
                            }
                        }
                        .padding(28)
                        .padding(.bottom, 100)
                    }
                }
            }
            .glassScreen(backdropColors)
            .navigationTitle("Mis cuadernos")
            .searchable(text: $search, prompt: "Buscar cuadernos")
            .overlay(alignment: .bottom) {
                // Botón flotante de vidrio
                Button {
                    showingNew = true
                } label: {
                    Label("Nuevo cuaderno", systemImage: "plus")
                        .font(.headline)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .padding(.bottom, 24)
            }
            .navigationDestination(for: UUID.self) { id in
                if let notebook = store.binding(for: id) {
                    NotebookView(notebook: notebook)
                }
            }
            .sheet(isPresented: $showingNew, onDismiss: openPending) {
                NewNotebookSheet { title, cover, style in
                    pendingOpen = store.create(title: title, coverIndex: cover, style: style).id
                }
            }
            .alert("Cambiar nombre", isPresented: isRenaming) {
                TextField("Nombre", text: $newTitle)
                Button("Guardar") { saveRename() }
                Button("Cancelar", role: .cancel) {}
            }
            .confirmationDialog(
                "¿Eliminar “\(deleting?.title ?? "")”?",
                isPresented: isDeleting,
                titleVisibility: .visible
            ) {
                Button("Eliminar cuaderno", role: .destructive) {
                    if let deleting { store.delete(deleting) }
                }
            } message: {
                Text("Se borrarán todas sus páginas. No se puede deshacer.")
            }
        }
    }

    @ViewBuilder
    private func menu(for notebook: Notebook) -> some View {
        Button {
            newTitle = notebook.title
            renaming = notebook
        } label: {
            Label("Cambiar nombre", systemImage: "pencil")
        }
        Menu {
            ForEach(Notebook.covers.indices, id: \.self) { index in
                Button {
                    var updated = notebook
                    updated.coverIndex = index
                    store.update(updated)
                } label: {
                    if notebook.coverIndex == index {
                        Label(Notebook.coverNames[index], systemImage: "checkmark")
                    } else {
                        Text(Notebook.coverNames[index])
                    }
                }
            }
        } label: {
            Label("Color de tapa", systemImage: "paintpalette")
        }
        Button(role: .destructive) {
            deleting = notebook
        } label: {
            Label("Eliminar", systemImage: "trash")
        }
    }

    private var filtered: [Notebook] {
        let query = search.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return store.notebooks }
        return store.notebooks.filter { $0.title.localizedCaseInsensitiveContains(query) }
    }

    private func emptyState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.tint)
                .frame(width: 88, height: 88)
                .glassEffect(.regular.tint(Color.accentColor.opacity(0.2)), in: .circle)
            Text(title)
                .font(.title3.weight(.semibold))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: 380)
        .glassEffect(.regular, in: .rect(cornerRadius: 32))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// El fondo toma los colores de tus cuadernos más recientes.
    private var backdropColors: [Color] {
        let recent = store.notebooks.prefix(3).map(\.cover)
        return recent.count >= 3 ? recent : [.indigo, .pink, .teal]
    }

    private var isRenaming: Binding<Bool> {
        Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })
    }

    private var isDeleting: Binding<Bool> {
        Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })
    }

    private func saveRename() {
        guard var notebook = renaming else { return }
        let title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !title.isEmpty {
            notebook.title = title
            store.update(notebook)
        }
        renaming = nil
    }

    private func openPending() {
        if let id = pendingOpen {
            path.append(id)
            pendingOpen = nil
        }
    }
}

// MARK: - Tapa del cuaderno

struct NotebookCover: View {
    let notebook: Notebook

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            CoverArt(title: notebook.title, color: notebook.cover)

            Text("\(notebook.pages.count) pág. · \(notebook.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .glassEffect(.regular, in: .capsule)
        }
    }
}

/// Tapa con brillo de vidrio y el título sobre una etiqueta Liquid Glass.
struct CoverArt: View {
    let title: String
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(color.gradient)
            .aspectRatio(0.75, contentMode: .fit)
            .overlay {
                // Reflejo de luz sobre la tapa
                LinearGradient(
                    colors: [.white.opacity(0.35), .clear, .white.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .overlay(alignment: .leading) {
                // Lomo del cuaderno
                Rectangle()
                    .fill(.black.opacity(0.15))
                    .frame(width: 12)
            }
            .overlay(alignment: .bottomLeading) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .glassEffect(.regular.tint(color.opacity(0.3)), in: .rect(cornerRadius: 12))
                    .padding(.leading, 20)
                    .padding([.trailing, .bottom], 10)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(.white.opacity(0.35), lineWidth: 1)
            }
            .shadow(color: color.opacity(0.35), radius: 14, y: 8)
    }
}

// MARK: - Nuevo cuaderno

struct NewNotebookSheet: View {
    var onCreate: (String, Int, PaperStyle) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var cover = 0
    @State private var style: PaperStyle = .lined

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    CoverArt(
                        title: title.isEmpty ? "Cuaderno sin título" : title,
                        color: Notebook.covers[cover]
                    )
                    .frame(width: 150)
                    .animation(.smooth, value: cover)
                    .padding(.vertical, 8)

                    GlassSection(title: "Nombre", systemImage: "character.cursor.ibeam") {
                        GlassTextField(placeholder: "Cuaderno sin título", text: $title)
                    }
                    GlassSection(title: "Color de la tapa", systemImage: "paintpalette") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            GlassColorPicker(selection: $cover)
                                .padding(4)
                        }
                    }
                    GlassSection(title: "Tipo de hoja", systemImage: "doc.plaintext") {
                        GlassPaperPicker(selection: $style)
                    }
                }
                .padding(24)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .glassScreen([Notebook.covers[cover], .white, Notebook.covers[cover]])
            .animation(.smooth, value: cover)
            .navigationTitle("Nuevo cuaderno")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar", systemImage: "xmark", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Crear", systemImage: "checkmark") {
                        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        onCreate(trimmed.isEmpty ? "Cuaderno sin título" : trimmed, cover, style)
                        dismiss()
                    }
                }
            }
        }
    }
}
