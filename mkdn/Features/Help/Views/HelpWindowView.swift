import SwiftUI

/// In-app Help window with sidebar navigation.
public struct HelpWindowView: View {
    @Environment(AppSettings.self) private var appSettings
    @State private var selectedSection: HelpSection? = .shortcuts

    public init() {}

    public var body: some View {
        NavigationSplitView {
            List(HelpSection.allCases, selection: $selectedSection) { section in
                Label(section.rawValue, systemImage: section.icon)
                    .tag(section)
            }
            .navigationSplitViewColumnWidth(min: 140, ideal: 160, max: 200)
        } detail: {
            ScrollView {
                switch selectedSection ?? .shortcuts {
                case .shortcuts:
                    ShortcutsSection()
                case .features:
                    FeaturesSection()
                case .cliUsage:
                    CLIUsageSection()
                case .about:
                    AboutSection()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(appSettings.effectiveColors.background)
        }
        .frame(minWidth: 600, minHeight: 450)
    }
}

// MARK: - Shortcuts Section

private struct ShortcutsSection: View {
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader("Keyboard Shortcuts", subtitle: "Quick reference for all available shortcuts")

            shortcutGroup("File", shortcuts: [
                ("New Markdown", "⌘N"),
                ("Open...", "⌘O"),
                ("Close Window", "⌘W"),
                ("Save", "⌘S"),
                ("Save As...", "⇧⌘S"),
                ("Reload", "⌘R"),
            ])

            shortcutGroup("View", shortcuts: [
                ("Preview Mode", "⌘1"),
                ("Edit Mode", "⌘2"),
                ("Cycle Theme", "⌘T"),
                ("Zoom In", "⌘+"),
                ("Zoom Out", "⌘−"),
                ("Actual Size", "⌘0"),
            ])

            shortcutGroup("Find", shortcuts: [
                ("Find...", "⌘F"),
                ("Find Next", "⌘G"),
                ("Find Previous", "⇧⌘G"),
                ("Use Selection for Find", "⌘E"),
            ])

            shortcutGroup("Print", shortcuts: [
                ("Print...", "⌘P"),
                ("Page Setup...", "⇧⌘P"),
            ])
        }
        .padding(24)
    }

    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2.bold())
                .foregroundColor(appSettings.effectiveColors.headingColor)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(appSettings.effectiveColors.foregroundSecondary)
        }
    }

    private func shortcutGroup(_ title: String, shortcuts: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(appSettings.effectiveColors.foregroundSecondary)
                .tracking(1)
                .padding(.bottom, 8)

            ForEach(Array(shortcuts.enumerated()), id: \.offset) { _, shortcut in
                HStack {
                    Text(shortcut.0)
                        .font(.callout)
                        .foregroundColor(appSettings.effectiveColors.foreground)
                    Spacer()
                    Text(shortcut.1)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(appSettings.effectiveColors.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(appSettings.effectiveColors.codeBackground)
                        )
                }
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - Features Section

private struct FeaturesSection: View {
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Features")
                .font(.title2.bold())
                .foregroundColor(appSettings.effectiveColors.headingColor)

            featureRow("doc.richtext", "Preview & Edit Modes",
                       "Switch between rendered preview (⌘1) and side-by-side editor (⌘2).")
            featureRow("paintpalette", "Themes",
                       "Cycle through Solarized Dark and Light themes (⌘T). Auto mode follows system appearance.")
            featureRow("chart.bar.doc.horizontal", "Mermaid Diagrams",
                       "Render Mermaid diagrams inline. Supports flowcharts, sequence diagrams, class diagrams, and state diagrams.")
            featureRow("cursorarrow.and.square.on.square.dashed", "Drag & Drop",
                       "Drag .md or .markdown files onto the window to open them.")
            featureRow("text.word.spacing", "Syntax Highlighting",
                       "Code blocks are syntax-highlighted with language detection.")
            featureRow("magnifyingglass", "Find & Replace",
                       "Find text with ⌘F. Navigate matches with ⌘G / ⇧⌘G.")
        }
        .padding(24)
    }

    private func featureRow(_ icon: String, _ title: String, _ description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(appSettings.effectiveColors.accent)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout.bold())
                    .foregroundColor(appSettings.effectiveColors.foreground)
                Text(description)
                    .font(.caption)
                    .foregroundColor(appSettings.effectiveColors.foregroundSecondary)
            }
        }
    }
}

// MARK: - CLI Usage Section

private struct CLIUsageSection: View {
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("CLI Usage")
                .font(.title2.bold())
                .foregroundColor(appSettings.effectiveColors.headingColor)

            cliExample("Open a file", "mkdn README.md")
            cliExample("Open multiple files", "mkdn file1.md file2.md")
            cliExample("Show help", "mkdn --help")

            VStack(alignment: .leading, spacing: 8) {
                Text("SUPPORTED EXTENSIONS")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(appSettings.effectiveColors.foregroundSecondary)
                    .tracking(1)

                HStack(spacing: 12) {
                    extensionBadge(".md")
                    extensionBadge(".markdown")
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("DEFAULT APP")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(appSettings.effectiveColors.foregroundSecondary)
                    .tracking(1)

                Text("Use mkdn menu → \"Set as Default Markdown App\" to register mkdn as the system handler for Markdown files.")
                    .font(.caption)
                    .foregroundColor(appSettings.effectiveColors.foreground)
            }
        }
        .padding(24)
    }

    private func cliExample(_ label: String, _ command: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.callout)
                .foregroundColor(appSettings.effectiveColors.foreground)
            Text(command)
                .font(.system(.callout, design: .monospaced))
                .foregroundColor(appSettings.effectiveColors.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(appSettings.effectiveColors.codeBackground)
                )
        }
    }

    private func extensionBadge(_ ext: String) -> some View {
        Text(ext)
            .font(.system(.caption, design: .monospaced))
            .foregroundColor(appSettings.effectiveColors.accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(appSettings.effectiveColors.codeBackground)
            )
    }
}

// MARK: - About Section

private struct AboutSection: View {
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.richtext")
                .font(.system(size: 48))
                .foregroundColor(appSettings.effectiveColors.foregroundSecondary)

            Text("mkdn")
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(appSettings.effectiveColors.headingColor)

            Text("A native macOS Markdown viewer and editor")
                .font(.callout)
                .foregroundColor(appSettings.effectiveColors.foregroundSecondary)

            Text("Built with Swift & SwiftUI")
                .font(.caption)
                .foregroundColor(appSettings.effectiveColors.foregroundSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}
