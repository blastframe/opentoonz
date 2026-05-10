import SwiftUI

@main
struct VectorToonzApp: App {
    @StateObject private var documentStore = DocumentStore()

    var body: some Scene {
        WindowGroup {
            EditorView()
                .environmentObject(documentStore)
        }
    }
}
