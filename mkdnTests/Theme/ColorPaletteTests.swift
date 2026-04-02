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

    // MARK: - Regression: builtInPaletteId uses id, not name

    @Test
    func builtInPaletteResolvesById() {
        // The UI stores palette.id (e.g. "dracula"), not palette.name ("Dracula").
        // builtInPalette must resolve using id, not name.
        let selection = UserPaletteSelection(
            builtInPaletteId: "dracula",
            customBackground: nil,
            customText: nil
        )
        let resolved = selection.builtInPalette
        #expect(resolved != nil, "builtInPalette should resolve id 'dracula'")
        #expect(resolved?.name == "Dracula")
        #expect(resolved?.background == "#282a36")
    }

    @Test
    func allBuiltInIdsResolve() {
        // Every built-in palette's id should round-trip through UserPaletteSelection.
        for palette in PaletteLibrary.builtIns {
            let selection = UserPaletteSelection(
                builtInPaletteId: palette.id,
                customBackground: nil,
                customText: nil
            )
            #expect(
                selection.builtInPalette?.id == palette.id,
                "Palette id '\(palette.id)' should resolve correctly"
            )
        }
    }

    @Test
    func builtInPaletteDoesNotResolveByName() {
        // Storing a display name should NOT resolve — only ids are valid.
        let selection = UserPaletteSelection(
            builtInPaletteId: "Dracula",
            customBackground: nil,
            customText: nil
        )
        #expect(selection.builtInPalette == nil, "Display name should not resolve as id")
    }

    @Test
    func defaultSelectionResolvesToSolarizedDark() {
        let defaultSel = UserPaletteSelection.default
        #expect(defaultSel.builtInPaletteId == "solarized-dark")
        let resolved = defaultSel.builtInPalette
        #expect(resolved != nil)
        #expect(resolved?.name == "Solarized Dark")
    }

    @Test
    func paletteColorsConversion() {
        // Ensure PaletteDefinition.colors produces a valid ThemeColors struct.
        let dracula = PaletteLibrary.builtIn(named: "Dracula")!
        let colors = dracula.colors
        // Background and foreground should be different.
        #expect(colors.background != colors.foreground)
    }
}
