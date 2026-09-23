import SwiftUI

struct NotebookView: View {
    @Binding var notebook: Notebook

    @StateObject private var controller = CanvasController()
    @AppStorage("soloLapiz") private var pencilOnly = false
    @State private var pageIndex = 0
    @State private var showingPages = false
    @State private var exportFile: ExportFile?
    @State private var exportError: String?

    private var safeIndex: Int {
        min(max(pageIndex, 0), notebook.pages.count - 1)
    }

    private var currentPage: Page {
        notebook.pages[safeIndex]
    }

    var body: some View {
        GeometryReader { geo in
            // La hoja llega hasta los bordes y las barras de vidrio flotan encima.
            PageCanvas(
                page: currentPage,
                pencilOnly: pencilOnly,
                chromeInsets: UIEdgeInsets(
                    top: geo.safeAreaInsets.top,
                    left: 0,
                    bottom: geo.safeAreaInsets.bottom,
                    right: 0
                ),
                controller: controller
            ) { id, data in
                guard let index = notebook.pages.firstIndex(where: { $0.id == id }) else { return }
                notebook.pages[index].drawingData = data
            }
            .ignoresSafeArea()
        }
        // Con esto `geo.safeAreaInsets` trae la altura real de las barras.
        .ignoresSafeArea()
        .glassScreen([notebook.cover, .gray, notebook.cover], animated: false)
        .navigationTitle(notebook.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                Button {
                    showingPages = true
                } label: {
                    Label("Ver páginas", systemImage: "square.grid.2x2")
                }
            }
            ToolbarSpacer(.fixed, placement: .topBarLeading)
            ToolbarItemGroup(placement: .topBarLeading) {
                Button {
                    pageIndex = safeIndex - 1
                } label: {
                    Label("Página anterior", systemImage: "chevron.left")
                }
                .disabled(safeIndex == 0)
                Text("\(safeIndex + 1) / \(notebook.pages.count)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                Button {
                    pageIndex = safeIndex + 1
                } label: {
                    Label("Página siguiente", systemImage: "chevron.right")
                }
                .disabled(safeIndex == notebook.pages.count - 1)
            }

            // Cada grupo es una cápsula de vidrio separada.
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(action: controller.undo) {
                    Label("Deshacer", systemImage: "arrow.uturn.backward")
                }
                Button(action: controller.redo) {
                    Label("Rehacer", systemImage: "arrow.uturn.forward")
                }
            }
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    withAnimation(.bouncy) { pencilOnly.toggle() }
                } label: {
                    Label(
                        pencilOnly ? "Solo Apple Pencil" : "Dibujar con el dedo",
                        systemImage: pencilOnly ? "applepencil.tip" : "hand.draw"
                    )
                    .contentTransition(.symbolEffect(.replace))
                }
                Button {
                    pageIndex = notebook.addPage(after: safeIndex)
                } label: {
                    Label("Nueva página", systemImage: "doc.badge.plus")
                }
            }
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
            ToolbarItem(placement: .topBarTrailing) {
                moreMenu
            }
        }
        .sheet(isPresented: $showingPages) {
            PagesSheet(notebook: $notebook, selection: $pageIndex)
                .presentationDetents([.medium, .large])
        }
        .sheet(item: $exportFile) { file in
            ShareSheet(items: [file.url])
        }
        .alert("No se pudo exportar", isPresented: Binding(get: { exportError != nil }, set: { if !$0 { exportError = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportError ?? "")
        }
    }

    private var moreMenu: some View {
        Menu {
            Picker("Tipo de hoja", selection: pageStyle) {
                ForEach(PaperStyle.allCases) { style in
                    Label(style.name, systemImage: style.icon).tag(style)
                }
            }
            Button {
                let style = currentPage.style
                for index in notebook.pages.indices {
                    notebook.pages[index].style = style
                }
            } label: {
                Label("Usar esta hoja en todas", systemImage: "doc.on.doc")
            }

            Divider()

            Button {
                pageIndex = notebook.duplicatePage(at: safeIndex)
            } label: {
                Label("Duplicar página", systemImage: "plus.square.on.square")
            }
            Button(role: .destructive) {
                pageIndex = notebook.deletePage(at: safeIndex, current: safeIndex)
            } label: {
                Label("Eliminar página", systemImage: "trash")
            }
            .disabled(notebook.pages.count == 1)

            Divider()

            Button(action: exportPDF) {
                Label("Exportar PDF", systemImage: "square.and.arrow.up")
            }
        } label: {
            Label("Más opciones", systemImage: "ellipsis.circle")
        }
    }

    private var pageStyle: Binding<PaperStyle> {
        Binding(
            get: { currentPage.style },
            set: { notebook.pages[safeIndex].style = $0 }
        )
    }

    private func exportPDF() {
        do {
            exportFile = ExportFile(url: try PDFExporter.export(notebook))
        } catch {
            exportError = error.localizedDescription
        }
    }
}

// MARK: - Vista de todas las páginas

struct PagesSheet: View {
    @Binding var notebook: Notebook
    @Binding var selection: Int
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 20)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(Array(notebook.pages.enumerated()), id: \.element.id) { index, page in
                        Button {
                            selection = index
                            dismiss()
                        } label: {
                            VStack(spacing: 6) {
                                PageThumbnail(page: page)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(
                                                index == selection ? Color.accentColor : Color.gray.opacity(0.3),
                                                lineWidth: index == selection ? 3 : 1
                                            )
                                    }
                                Text("\(index + 1)")
                                    .font(.caption.weight(.semibold).monospacedDigit())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .glassEffect(
                                        index == selection ? .regular.tint(.accentColor).interactive() : .regular.interactive(),
                                        in: .capsule
                                    )
                            }
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button {
                                selection = notebook.duplicatePage(at: index)
                            } label: {
                                Label("Duplicar", systemImage: "plus.square.on.square")
                            }
                            Button(role: .destructive) {
                                selection = notebook.deletePage(at: index, current: selection)
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
                            .disabled(notebook.pages.count == 1)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Páginas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo", systemImage: "checkmark") { dismiss() }
                }
            }
        }
    }
}

struct PageThumbnail: View {
    let page: Page
    var width: CGFloat = 150

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image).resizable()
            } else {
                Color.white
            }
        }
        .aspectRatio(Page.size.width / Page.size.height, contentMode: .fit)
        .frame(width: width)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
        .task(id: page) {
            image = page.thumbnail(width: width)
        }
    }
}
