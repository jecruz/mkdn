import SwiftUI

/// The main color palette popover shown when View → "Color Palette…" is selected.
struct ColorPalettePopover: View {
    @Binding var isOpen: Bool

    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        @Bindable var settings = appSettings

        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Color Palette")
                    .font(.headline)

                Spacer()

                Button {
                    isOpen = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Divider()

            PaletteGridView(selection: $settings.userPaletteSelection, palettes: PaletteLibrary.builtIns)

            Divider()

            SwatchPickerView(selection: $settings.userPaletteSelection)

            Spacer()
        }
        .padding(16)
        .frame(width: 600, height: 280)
    }
}
