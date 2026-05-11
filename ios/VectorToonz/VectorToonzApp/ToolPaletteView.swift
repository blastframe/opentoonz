import SwiftUI

struct ToolPaletteView: View {
    @Binding var selectedTool: VectorTool

    var body: some View {
        VStack(spacing: 10) {
            ForEach(VectorTool.allCases) { tool in
                Button {
                    selectedTool = tool
                } label: {
                    Label(tool.displayName, systemImage: tool.systemImageName)
                        .labelStyle(.iconOnly)
                        .font(.title3)
                        .frame(width: 52, height: 52)
                        .background(selectedTool == tool ? Color.accentColor.opacity(0.22) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .accessibilityLabel(tool.displayName)
            }
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
