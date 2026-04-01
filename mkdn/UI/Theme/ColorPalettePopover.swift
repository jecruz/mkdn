import SwiftUI

/// The main color palette popover shown when View → "Color Palette…" is selected.
struct ColorPalettePopover: View {
    @Binding var isOpen: Bool

    @State private var selection: UserPaletteSelection = .default

    var body: some View {
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

            PaletteGridView(selection: $selection, palettes: PaletteLibrary.builtIns)

            Divider()

            SwatchPickerView(selection: $selection)

            Spacer()
        }
        .padding(16)
        .frame(width: 320, height: 260)
        .onAppear {
            selection = UserPaletteSelection.load()
        }
        .onChange(of: selection) { _, newValue in
            newValue.save()
        }
    }
}
