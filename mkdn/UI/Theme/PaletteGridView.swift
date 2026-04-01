import SwiftUI

/// A horizontal row of circular palette previews for one-click theme switching.
struct PaletteGridView: View {
    @Binding var selection: UserPaletteSelection
    let palettes: [PaletteDefinition]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PALETTES")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .tracking(1)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(palettes) { palette in
                        ColorSwatchButton(
                            hex: palette.background,
                            style: .circle,
                            isSelected: selection.builtInPaletteId == palette.name,
                            action: {
                                selection.builtInPaletteId = palette.name
                                selection.customBackground = nil
                                selection.customText = nil
                            }
                        )
                        .frame(width: 32, height: 32)
                        .overlay {
                            Text(palette.name)
                                .font(.system(size: 9))
                                .foregroundStyle(Color(hex: palette.text))
                                .opacity(0)
                                .offset(y: 22)
                        }
                    }
                }
            }
        }
    }
}
