#if os(macOS)
    import AppKit
    import SwiftUI

    private let themeModeKey = "themeMode"

    private let hasShownDefaultHandlerHintKey = "hasShownDefaultHandlerHint"

    private let autoReloadEnabledKey = "autoReloadEnabled"

    private let scaleFactorKey = "scaleFactor"

    private let windowWidthKey = "windowWidth"

    private let windowHeightKey = "windowHeight"

    /// App-wide settings shared across all windows.
    ///
    /// Manages theme preferences and application-level state that is
    /// independent of any specific document window.
    @MainActor
    @Observable
    public final class AppSettings {
        // MARK: - Theme

        /// User's theme preference: auto (follows system), or a pinned variant.
        /// Persisted to UserDefaults under the `"themeMode"` key.
        public var themeMode: ThemeMode {
            didSet {
                UserDefaults.standard.set(themeMode.rawValue, forKey: themeModeKey)
                effectiveColors = Self.resolveEffectiveColors(
                    themeMode: themeMode,
                    systemColorScheme: systemColorScheme,
                    selection: userPaletteSelection
                )
            }
        }

        /// Current system color scheme, bridged from `@Environment(\.colorScheme)`.
        /// Initialized from `NSApp.effectiveAppearance` to prevent a flash of wrong
        /// theme before the SwiftUI colorScheme bridge fires. Updated by the root
        /// view whenever the OS appearance changes.
        public var systemColorScheme: ColorScheme {
            didSet {
                effectiveColors = Self.resolveEffectiveColors(
                    themeMode: themeMode,
                    systemColorScheme: systemColorScheme,
                    selection: userPaletteSelection
                )
            }
        }

        /// Resolved color theme based on the user's mode preference and system appearance.
        public var theme: AppTheme {
            themeMode.resolved(for: systemColorScheme)
        }

        // MARK: - Color Palette

        /// User's color palette selection (built-in or custom mix).
        /// Persisted to UserDefaults via UserPaletteSelection.save().
        public var userPaletteSelection: UserPaletteSelection {
            didSet {
                userPaletteSelection.save()
                effectiveColors = Self.resolveEffectiveColors(
                    themeMode: themeMode,
                    systemColorScheme: systemColorScheme,
                    selection: userPaletteSelection
                )
            }
        }

        /// Effective theme colors: built-in palette > custom mix > theme default.
        /// Stored so that @Observable can track it and trigger view updates.
        public var effectiveColors: ThemeColors

        /// Resolves the effective colors from inputs. Pure function used by didSet observers.
        private static func resolveEffectiveColors(
            themeMode: ThemeMode,
            systemColorScheme: ColorScheme,
            selection: UserPaletteSelection
        ) -> ThemeColors {
            let theme = themeMode.resolved(for: systemColorScheme)

            // Built-in palette takes priority.
            if let palette = selection.builtInPalette {
                let bg = Color(hex: palette.background)
                let fg = Color(hex: palette.text)
                let accent = Color(hex: palette.accent)
                return ThemeColors(
                    background: bg,
                    backgroundSecondary: bg.opacity(0.85),
                    foreground: fg,
                    foregroundSecondary: fg.opacity(0.7),
                    accent: accent,
                    border: fg.opacity(0.2),
                    codeBackground: bg.opacity(0.6),
                    codeForeground: fg,
                    linkColor: accent,
                    headingColor: fg,
                    blockquoteBorder: fg.opacity(0.4),
                    blockquoteBackground: bg.opacity(0.5),
                    findHighlight: accent
                )
            }

            // Custom mix is second.
            if selection.isCustomMixing,
               let bg = selection.customBackground,
               let fg = selection.customText
            {
                let bgColor = Color(hex: bg)
                let fgColor = Color(hex: fg)
                return ThemeColors(
                    background: bgColor,
                    backgroundSecondary: bgColor.opacity(0.85),
                    foreground: fgColor,
                    foregroundSecondary: fgColor.opacity(0.7),
                    accent: fgColor.opacity(0.6),
                    border: fgColor.opacity(0.2),
                    codeBackground: bgColor.opacity(0.6),
                    codeForeground: fgColor,
                    linkColor: fgColor.opacity(0.8),
                    headingColor: fgColor,
                    blockquoteBorder: fgColor.opacity(0.4),
                    blockquoteBackground: bgColor.opacity(0.5),
                    findHighlight: fgColor.opacity(0.6)
                )
            }

            // Fall back to theme default.
            return theme.colors
        }

        // MARK: - Default Handler Hint

        /// Whether the first-launch default handler hint has been shown.
        /// Persisted to UserDefaults so the hint never reappears.
        public var hasShownDefaultHandlerHint: Bool {
            didSet {
                UserDefaults.standard.set(hasShownDefaultHandlerHint, forKey: hasShownDefaultHandlerHintKey)
            }
        }

        // MARK: - Auto-Reload

        /// Whether to automatically reload unchanged files when they change on disk.
        /// Defaults to `false` (manual reload prompt). Persisted to UserDefaults.
        /// Discovered and toggled in-context from the file-changed popover.
        public var autoReloadEnabled: Bool {
            didSet {
                UserDefaults.standard.set(autoReloadEnabled, forKey: autoReloadEnabledKey)
            }
        }

        // MARK: - Zoom

        /// Zoom scale factor for preview text rendering.
        /// Range: 0.5...3.0, default 1.0. Persisted to UserDefaults.
        public var scaleFactor: CGFloat {
            didSet {
                UserDefaults.standard.set(Double(scaleFactor), forKey: scaleFactorKey)
            }
        }

        // MARK: - Window Size

        /// Last saved window width. Persisted to UserDefaults.
        /// Default: 800 when no saved value exists.
        public var windowWidth: CGFloat {
            didSet {
                UserDefaults.standard.set(Double(windowWidth), forKey: windowWidthKey)
            }
        }

        /// Last saved window height. Persisted to UserDefaults.
        /// Default: 600 when no saved value exists.
        public var windowHeight: CGFloat {
            didSet {
                UserDefaults.standard.set(Double(windowHeight), forKey: windowHeightKey)
            }
        }

        public init() {
            let appearance = NSApp?.effectiveAppearance ?? NSAppearance.currentDrawing()
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let resolvedScheme: ColorScheme = isDark ? .dark : .light
            systemColorScheme = resolvedScheme

            let resolvedMode: ThemeMode
            if let raw = UserDefaults.standard.string(forKey: themeModeKey),
               let mode = ThemeMode(rawValue: raw)
            {
                resolvedMode = mode
            } else {
                resolvedMode = .auto
            }
            themeMode = resolvedMode

            hasShownDefaultHandlerHint = UserDefaults.standard.bool(forKey: hasShownDefaultHandlerHintKey)
            let resolvedSelection = UserPaletteSelection.load()
            userPaletteSelection = resolvedSelection
            autoReloadEnabled = UserDefaults.standard.bool(forKey: autoReloadEnabledKey)

            let storedScale = CGFloat(UserDefaults.standard.double(forKey: scaleFactorKey))
            scaleFactor = storedScale > 0 ? storedScale : 1.0

            let storedWidth = CGFloat(UserDefaults.standard.double(forKey: windowWidthKey))
            windowWidth = storedWidth > 0 ? storedWidth : 800

            let storedHeight = CGFloat(UserDefaults.standard.double(forKey: windowHeightKey))
            windowHeight = storedHeight > 0 ? storedHeight : 600

            effectiveColors = Self.resolveEffectiveColors(
                themeMode: resolvedMode,
                systemColorScheme: resolvedScheme,
                selection: resolvedSelection
            )
        }

        // MARK: - Methods

        /// Cycle to the next theme mode, skipping modes that resolve to
        /// the same visual theme (e.g. Auto and Dark on a dark system).
        public func cycleTheme() {
            let allModes = ThemeMode.allCases
            guard let currentIndex = allModes.firstIndex(of: themeMode) else { return }
            let currentResolved = theme
            for offset in 1 ... allModes.count {
                let candidate = allModes[(currentIndex + offset) % allModes.count]
                if candidate.resolved(for: systemColorScheme) != currentResolved {
                    themeMode = candidate
                    return
                }
            }
        }

        /// Increase zoom by 10%, clamped at 3.0x maximum.
        public func zoomIn() {
            scaleFactor = min(scaleFactor + 0.1, 3.0)
        }

        /// Decrease zoom by 10%, clamped at 0.5x minimum.
        public func zoomOut() {
            scaleFactor = max(scaleFactor - 0.1, 0.5)
        }

        /// Reset zoom to the default 1.0x scale.
        public func zoomReset() {
            scaleFactor = 1.0
        }

        /// Formatted zoom percentage label for display overlay (e.g., "125%").
        public var zoomLabel: String {
            "\(Int(round(scaleFactor * 100)))%"
        }

        // MARK: - Color Palette Popover

        /// Whether the color palette popover is shown.
        public var showColorPalettePopover: Bool = false
    }
#endif
