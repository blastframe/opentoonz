import SwiftUI

struct TimelineView: View {
    @EnvironmentObject private var store: DocumentStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Timeline", systemImage: "film")
                    .font(.headline)
                Spacer()
                Button("Duplicate Frame") {
                    store.duplicateFrame()
                }
                .buttonStyle(.bordered)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0..<48, id: \.self) { frame in
                        Button {
                            store.selectFrame(frame)
                        } label: {
                            VStack(spacing: 6) {
                                Text("\(frame + 1)")
                                    .font(.caption.weight(.semibold))
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(hasDrawing(at: frame) ? Color.accentColor : Color.secondary.opacity(0.24))
                                    .frame(width: 42, height: 36)
                            }
                            .frame(width: 56, height: 68)
                            .background(store.document.currentFrameIndex == frame ? Color.accentColor.opacity(0.18) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private func hasDrawing(at frameIndex: Int) -> Bool {
        store.document.layers.contains { layer in
            store.document.frame(layerID: layer.id, index: frameIndex)?.strokes.isEmpty == false
        }
    }
}
