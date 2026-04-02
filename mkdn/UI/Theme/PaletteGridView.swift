import SwiftUI

/// A horizontal row of circular palette previews for one-click theme switching.
struct PaletteGridView: View {
    @Binding var selection: UserPaletteSelection
    let palettes: [PaletteDefinition]

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
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
                            isSelected: selection.builtInPaletteId == palette.id,
                            size: 24,
                            action: {
                                selection.builtInPaletteId = palette.id
                                selection.customBackground = nil
                                selection.customText = nil
                            }
                        )
                        .frame(width: 30, height: 30)
                        .overlay {
                            Text(palette.name)
                                .font(.system(size: 9))
                                .foregroundStyle(Color(hex: palette.text))
                                .opacity(0)
                                .offset(y: 22)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
