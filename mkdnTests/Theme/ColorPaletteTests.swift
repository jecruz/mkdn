import SwiftUI
import Testing
@testable import mkdnLib

struct ColorPaletteTests {
    @Test
    func paletteDefinitionHasAllBuiltIns() {
        for palette in PaletteLibrary.builtIns {
            #expect(palette.background.hasPrefix("#"))
            #expect(palette.text.hasPrefix("#"))
            #expect(palette.accent.hasPrefix("#"))
            #expect(!palette.name.isEmpty)
        }
    }

    @Test
    func userPaletteSelectionSavesAndLoads() {
        // Clear any previously saved state to ensure test isolation
        UserDefaults.standard.removeObject(forKey: "userPaletteSelection")

        let selection = UserPaletteSelection(
            builtInPaletteId: "dracula",
            customBackground: nil,
            customText: nil
        )
        selection.save()
        let loaded = UserPaletteSelection.load()
        #expect(loaded.builtInPaletteId == "dracula")
    }

    @Test
    func customMixSavesAndLoads() {
        // Clear any previously saved state to ensure test isolation
        UserDefaults.standard.removeObject(forKey: "userPaletteSelection")

        let selection = UserPaletteSelection(
            builtInPaletteId: nil,
            customBackground: "#1e1e2e",
            customText: "#f8f8f2"
        )
        selection.save()
        let loaded = UserPaletteSelection.load()
        #expect(loaded.customBackground == "#1e1e2e")
        #expect(loaded.customText == "#f8f8f2")
        #expect(loaded.isCustomMixing == true)
        #expect(loaded.builtInPalette == nil)
    }

    @Test
    func builtInPaletteLookup() {
        #expect(PaletteLibrary.builtIn(named: "Dracula")?.background == "#282a36")
        #expect(PaletteLibrary.builtIn(named: "Nonexistent") == nil)
    }

    @Test
    func colorFromHex() {
        let red = Color(hex: "#ff0000")
        let blue = Color(hex: "#0000ff")
        // Verify parsing doesn't crash and produces different colors
        #expect(red != blue)
    }

    @Test
    func swatchPoolNotEmpty() {
        #expect(PaletteLibrary.backgroundSwatches.count == 10)
        #expect(PaletteLibrary.textSwatches.count == 10)
    }
}
