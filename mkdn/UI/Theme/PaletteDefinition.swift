import SwiftUI

// MARK: - Color Extension

extension Color {
    /// Initialize a Color from a hex string.
    /// Supports formats: #RGB, #RRGGBB, #AARRGGBB
    init(hex: String) {
        let hexClean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexClean).scanHexInt64(&int)

        let r, g, b, a: Double
        switch hexClean.count {
        case 3: // RGB (12-bit)
            (r, g, b, a) = (
                Double((int >> 8) & 0xF) / 15,
                Double((int >> 4) & 0xF) / 15,
                Double(int & 0xF) / 15,
                1.0
            )
        case 6: // RRGGBB (24-bit)
            (r, g, b, a) = (
                Double((int >> 16) & 0xFF) / 255,
                Double((int >> 8) & 0xFF) / 255,
                Double(int & 0xFF) / 255,
                1.0
            )
        case 8: // AARRGGBB (32-bit)
            (r, g, b, a) = (
                Double((int >> 16) & 0xFF) / 255,
                Double((int >> 8) & 0xFF) / 255,
                Double(int & 0xFF) / 255,
                Double((int >> 24) & 0xFF) / 255
            )
        default:
            (r, g, b, a) = (0, 0, 0, 1)
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }
}

// MARK: - PaletteDefinition

/// Defines a color palette with name, background, text, and accent colors.
struct PaletteDefinition: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let background: String
    let text: String
    let accent: String
    let isBuiltIn: Bool

    /// Converts the palette hex values into a full ThemeColors struct.
    var colors: ThemeColors {
        let bg = Color(hex: background)
        let fg = Color(hex: text)
        let acc = Color(hex: accent)

        return ThemeColors(
            background: bg,
            backgroundSecondary: bg.opacity(0.95),
            foreground: fg,
            foregroundSecondary: fg.opacity(0.7),
            accent: acc,
            border: fg.opacity(0.2),
            codeBackground: fg.opacity(0.05),
            codeForeground: fg,
            linkColor: acc,
            headingColor: fg,
            blockquoteBorder: acc,
            blockquoteBackground: fg.opacity(0.05),
            findHighlight: acc
        )
    }
}

// MARK: - PaletteLibrary

/// Static library of built-in palettes and swatch options.
enum PaletteLibrary {
    /// 8 built-in color palettes.
    static let builtIns: [PaletteDefinition] = [
        // Solarized Dark
        PaletteDefinition(
            id: "solarized-dark",
            name: "Solarized Dark",
            background: "#002b36",
            text: "#839496",
            accent: "#268bd2",
            isBuiltIn: true
        ),
        // Solarized Light
        PaletteDefinition(
            id: "solarized-light",
            name: "Solarized Light",
            background: "#fdf6e3",
            text: "#657b83",
            accent: "#268bd2",
            isBuiltIn: true
        ),
        // Dracula
        PaletteDefinition(
            id: "dracula",
            name: "Dracula",
            background: "#282a36",
            text: "#f8f8f2",
            accent: "#bd93f9",
            isBuiltIn: true
        ),
        // Nord Dark
        PaletteDefinition(
            id: "nord-dark",
            name: "Nord Dark",
            background: "#2e3440",
            text: "#d8dee9",
            accent: "#88c0d0",
            isBuiltIn: true
        ),
        // GitHub Dark
        PaletteDefinition(
            id: "github-dark",
            name: "GitHub Dark",
            background: "#0d1117",
            text: "#c9d1d9",
            accent: "#58a6ff",
            isBuiltIn: true
        ),
        // Monokai
        PaletteDefinition(
            id: "monokai",
            name: "Monokai",
            background: "#272822",
            text: "#f8f8f2",
            accent: "#f92672",
            isBuiltIn: true
        ),
        // One Dark
        PaletteDefinition(
            id: "one-dark",
            name: "One Dark",
            background: "#282c34",
            text: "#abb2bf",
            accent: "#61afef",
            isBuiltIn: true
        ),
        // GitHub Light
        PaletteDefinition(
            id: "github-light",
            name: "GitHub Light",
            background: "#ffffff",
            text: "#24292e",
            accent: "#0366d6",
            isBuiltIn: true
        )
    ]

    /// 10 background swatch colors.
    static let backgroundSwatches: [String] = [
        "#002b36", // Solarized base03
        "#073642", // Solarized base02
        "#fdf6e3", // Solarized light base3
        "#eee8d5", // Solarized light base2
        "#282a36", // Dracula background
        "#2e3440", // Nord background
        "#0d1117", // GitHub dark background
        "#272822", // Monokai background
        "#282c34", // One Dark background
        "#ffffff"  // GitHub Light background
    ]

    /// 10 text swatch colors.
    static let textSwatches: [String] = [
        "#839496", // Solarized base0
        "#93a1a1", // Solarized base1
        "#657b83", // Solarized light base00
        "#f8f8f2", // Dracula text
        "#d8dee9", // Nord text
        "#c9d1d9", // GitHub dark text
        "#f92672", // Monokai accent (for contrast demo)
        "#abb2bf", // One Dark text
        "#24292e", // GitHub Light text
        "#586e75"  // Solarized base01
    ]

    /// Look up a built-in palette by name.
    static func builtIn(named name: String) -> PaletteDefinition? {
        builtIns.first { $0.name == name }
    }
}

// MARK: - UserPaletteSelection

/// User's palette selection, supporting built-in palettes and custom mixing.
public struct UserPaletteSelection: Codable, Sendable, Equatable {
    /// The ID of the selected built-in palette.
    var builtInPaletteId: String?

    /// Custom background color hex string (optional).
    var customBackground: String?

    /// Custom text color hex string (optional).
    var customText: String?

    /// The resolved built-in palette, if any.
    var builtInPalette: PaletteDefinition? {
        guard let id = builtInPaletteId else { return nil }
        return PaletteLibrary.builtIns.first { $0.id == id }
    }

    /// Whether the user has mixed custom colors with a built-in palette.
    var isCustomMixing: Bool {
        customBackground != nil || customText != nil
    }

    /// Default selection is Solarized Dark.
    static let `default` = UserPaletteSelection(builtInPaletteId: "solarized-dark")

    // MARK: - Persistence

    private static let userDefaultsKey = "userPaletteSelection"

    /// Persist the selection to UserDefaults.
    func save() {
        guard let data = try? JSONEncoder().encode(self) else {
            print("ColorPalette: failed to encode selection")
            return
        }
        UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
    }

    /// Load the selection from UserDefaults.
    /// Returns the default if nothing is stored.
    static func load() -> UserPaletteSelection {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return .default
        }
        if let selection = try? JSONDecoder().decode(UserPaletteSelection.self, from: data) {
            return selection
        } else {
            print("ColorPalette: failed to decode selection, using default")
            return .default
        }
    }
}
