import Foundation
import SwiftUI

@MainActor
final class DocumentStore: ObservableObject {
    @Published var document = VectorDocument()
    @Published var selectedTool: VectorTool = .brush
    @Published var canvasScale: CGFloat = 1
    @Published var canvasOffset: CGSize = .zero
    @Published var canvasRotation: Angle = .zero

    private var documentURL: URL {
        URL.documentsDirectory.appending(path: "VectorToonz.autosave.json")
    }

    func addLayer() {
        document.addLayer()
        save()
    }

    func selectLayer(_ layerID: UUID) {
        document.selectLayer(layerID)
        save()
    }

    func toggleLayerVisibility(_ layerID: UUID) {
        document.toggleLayerVisibility(layerID)
        save()
    }

    func selectFrame(_ index: Int) {
        document.setCurrentFrame(index)
        save()
    }

    func duplicateFrame() {
        document.duplicateCurrentFrame()
        save()
    }

    func addStroke(points: [VectorPoint]) {
        guard points.count > 1 else { return }
        document.addStroke(VectorStroke(styleID: document.selectedStyleID, points: points))
        save()
    }

    func load() {
        guard let data = try? Data(contentsOf: documentURL),
              let decoded = try? JSONDecoder().decode(VectorDocument.self, from: data) else { return }
        document = decoded
    }

    func save() {
        guard let data = try? JSONEncoder().encode(document) else { return }
        try? data.write(to: documentURL, options: [.atomic])
    }
}
