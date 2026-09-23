import SwiftUI

@main
struct MisNotasApp: App {
    @StateObject private var store = NotebookStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            LibraryView()
                .environmentObject(store)
        }
        .onChange(of: scenePhase) { _, phase in
            // Guarda todo al salir de la app para no perder ningún trazo.
            if phase != .active {
                store.saveNow()
            }
        }
    }
}
