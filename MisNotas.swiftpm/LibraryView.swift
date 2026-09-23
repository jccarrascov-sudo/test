import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var store: NotebookStore

    @State private var path: [UUID] = []
    @State private var showingNew = false
    @State private var pendingOpen: UUID?
    @State private var renaming: Notebook?
    @State private var newTitle = ""
    @State private var deleting: Notebook?

    private let columns = [GridItem(.adaptive(minimum: 160, maximum: 210), spacing: 28)]

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if store.notebooks.isEmpty {
                    ContentUnavailableView(
                        "Aún no tienes cuadernos",
                        systemImage: "book.closed",
                        description: Text("Toca “Nuevo cuaderno” para empezar.")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 32) {
                            ForEach(store.notebooks) { notebook in
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
            .background { GlassBackdrop(colors: backdropColors) }
            .navigationTitle("Mis cuadernos")
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
            Form {
                Section {
                    CoverArt(
                        title: title.isEmpty ? "Cuaderno sin título" : title,
                        color: Notebook.covers[cover]
                    )
                    .frame(width: 140)
                    .frame(maxWidth: .infinity)
                    .animation(.smooth, value: cover)
                }
                .listRowBackground(Color.clear)

                Section("Nombre") {
                    TextField("Cuaderno sin título", text: $title)
                }
                Section("Color de la tapa") {
                    HStack(spacing: 14) {
                        ForEach(Notebook.covers.indices, id: \.self) { index in
                            Circle()
                                .fill(Notebook.covers[index].gradient)
                                .frame(width: 32, height: 32)
                                .padding(5)
                                .glassEffect(cover == index ? .regular.interactive() : .identity, in: .circle)
                                .onTapGesture { cover = index }
                                .accessibilityLabel(Notebook.coverNames[index])
                                .accessibilityAddTraits(cover == index ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 8)
                }
                Section("Tipo de hoja") {
                    Picker("Tipo de hoja", selection: $style) {
                        ForEach(PaperStyle.allCases) { style in
                            Label(style.name, systemImage: style.icon).tag(style)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
            }
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
