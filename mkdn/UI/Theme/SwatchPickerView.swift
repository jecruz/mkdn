import SwiftUI

/// Two rows of square swatches (background + text) for independent color mixing.
struct SwatchPickerView: View {
    @Binding var selection: UserPaletteSelection

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CUSTOM MIX")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .tracking(1)

            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Text("Background")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 70, alignment: .leading)

                    ForEach(PaletteLibrary.backgroundSwatches, id: \.self) { hex in
                        ColorSwatchButton(
                            hex: hex,
                            style: .square,
                            isSelected: selection.customBackground == hex,
                            size: 22,
                            action: {
                                selection.customBackground = hex
                                selection.builtInPaletteId = nil
                                // If text not yet set, derive from this swatch
                                if selection.customText == nil {
                                    selection.customText = PaletteLibrary.textSwatches.first { $0 != hex }
                                }
                            }
                        )
                    }
                }

                HStack(spacing: 6) {
                    Text("Text")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 70, alignment: .leading)

                    ForEach(PaletteLibrary.textSwatches, id: \.self) { hex in
                        ColorSwatchButton(
                            hex: hex,
                            style: .square,
                            isSelected: selection.customText == hex,
                            size: 22,
                            action: {
                                selection.customText = hex
                                selection.builtInPaletteId = nil
                                // If background not yet set, derive from this swatch
                                if selection.customBackground == nil {
                                    selection.customBackground = PaletteLibrary.backgroundSwatches.first { $0 != hex }
                                }
                            }
                        )
                    }
                }
            }
        }
    }
}
