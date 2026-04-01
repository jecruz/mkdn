# Help System & Markdown Linting Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an in-app Help window, a floating Markdown Guide reference, and an inline Markdown linter to mkdn.

**Architecture:** Three features: (1) Help Window as a SwiftUI `Window` scene with sidebar navigation showing shortcuts, features, CLI usage, and about info. (2) Markdown Guide as a floating utility-style `Window` scene with syntax/result side-by-side panels. (3) MarkdownLinter service that analyzes content and produces inline yellow underline warnings in the editor with a toolbar badge. All features use the existing `AppSettings` theme system.

**Tech Stack:** Swift 6, SwiftUI, `@Observable`, Swift Testing

---

### Task 1: Help Section Model + Help Menu Commands

**Files:**
- Create: `mkdn/Features/Help/Models/HelpSection.swift`
- Modify: `mkdn/App/MkdnCommands.swift`

- [ ] **Step 1: Create HelpSection enum**

```swift
// mkdn/Features/Help/Models/HelpSection.swift
import SwiftUI

/// Sidebar sections for the Help window.
enum HelpSection: String, CaseIterable, Identifiable {
    case shortcuts = "Shortcuts"
    case features = "Features"
    case cliUsage = "CLI Usage"
    case about = "About"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .shortcuts: "keyboard"
        case .features: "sparkles"
        case .cliUsage: "terminal"
        case .about: "info.circle"
        }
    }
}
```

- [ ] **Step 2: Add Help menu commands to MkdnCommands**

Add this `CommandGroup` inside the `body` property of `MkdnCommands`, after the existing `CommandGroup(after: .sidebar)` block:

```swift
        CommandGroup(replacing: .help) {
            Button("mkdn Help") {
                NSApp.sendAction(#selector(NSApplication.showHelp(_:)), to: nil, from: nil)
            }
            .keyboardShortcut("?", modifiers: .command)

            Divider()

            Button("Markdown Guide") {
                NotificationCenter.default.post(name: .openMarkdownGuide, object: nil)
            }
            .keyboardShortcut("m", modifiers: [.command, .shift])
        }
```

Also add a notification name extension at the top of `MkdnCommands.swift`, below the imports:

```swift
extension Notification.Name {
    static let openHelpWindow = Notification.Name("openHelpWindow")
    static let openMarkdownGuide = Notification.Name("openMarkdownGuide")
}
```

And change the "mkdn Help" button action to use the notification instead of `showHelp`:

```swift
            Button("mkdn Help") {
                NotificationCenter.default.post(name: .openHelpWindow, object: nil)
            }
            .keyboardShortcut("?", modifiers: .command)
```

- [ ] **Step 3: Build and verify**

Run: `swift build`
Expected: Build succeeds with no errors related to new files.

- [ ] **Step 4: Commit**

```
git add mkdn/Features/Help/Models/HelpSection.swift mkdn/App/MkdnCommands.swift
git commit -m "feat(help): add HelpSection model and Help menu commands"
```

---

### Task 2: Help Window View

**Files:**
- Create: `mkdn/Features/Help/Views/HelpWindowView.swift`
- Modify: `mkdnEntry/main.swift`

- [ ] **Step 1: Create the Help window view**

```swift
// mkdn/Features/Help/Views/HelpWindowView.swift
import SwiftUI

/// In-app Help window with sidebar navigation.
struct HelpWindowView: View {
    @Environment(AppSettings.self) private var appSettings
    @State private var selectedSection: HelpSection = .shortcuts

    var body: some View {
        NavigationSplitView {
            List(HelpSection.allCases, selection: $selectedSection) { section in
                Label(section.rawValue, systemImage: section.icon)
            }
            .navigationSplitViewColumnWidth(min: 140, ideal: 160, max: 200)
        } detail: {
            ScrollView {
                switch selectedSection {
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
            .background(appSettings.theme.colors.background)
        }
        .frame(minWidth: 500, minHeight: 350)
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
                .foregroundColor(appSettings.theme.colors.headingColor)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(appSettings.theme.colors.foregroundSecondary)
        }
    }

    private func shortcutGroup(_ title: String, shortcuts: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(appSettings.theme.colors.foregroundSecondary)
                .tracking(1)
                .padding(.bottom, 8)

            ForEach(Array(shortcuts.enumerated()), id: \.offset) { _, shortcut in
                HStack {
                    Text(shortcut.0)
                        .font(.callout)
                        .foregroundColor(appSettings.theme.colors.foreground)
                    Spacer()
                    Text(shortcut.1)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(appSettings.theme.colors.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(appSettings.theme.colors.codeBackground)
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
                .foregroundColor(appSettings.theme.colors.headingColor)

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
                .foregroundColor(appSettings.theme.colors.accent)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout.bold())
                    .foregroundColor(appSettings.theme.colors.foreground)
                Text(description)
                    .font(.caption)
                    .foregroundColor(appSettings.theme.colors.foregroundSecondary)
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
                .foregroundColor(appSettings.theme.colors.headingColor)

            cliExample("Open a file", "mkdn README.md")
            cliExample("Open multiple files", "mkdn file1.md file2.md")
            cliExample("Show help", "mkdn --help")

            VStack(alignment: .leading, spacing: 8) {
                Text("SUPPORTED EXTENSIONS")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(appSettings.theme.colors.foregroundSecondary)
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
                    .foregroundColor(appSettings.theme.colors.foregroundSecondary)
                    .tracking(1)

                Text("Use mkdn menu → \"Set as Default Markdown App\" to register mkdn as the system handler for Markdown files.")
                    .font(.caption)
                    .foregroundColor(appSettings.theme.colors.foreground)
            }
        }
        .padding(24)
    }

    private func cliExample(_ label: String, _ command: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.callout)
                .foregroundColor(appSettings.theme.colors.foreground)
            Text(command)
                .font(.system(.callout, design: .monospaced))
                .foregroundColor(appSettings.theme.colors.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(appSettings.theme.colors.codeBackground)
                )
        }
    }

    private func extensionBadge(_ ext: String) -> some View {
        Text(ext)
            .font(.system(.caption, design: .monospaced))
            .foregroundColor(appSettings.theme.colors.accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(appSettings.theme.colors.codeBackground)
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
                .foregroundColor(appSettings.theme.colors.foregroundSecondary)

            Text("mkdn")
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(appSettings.theme.colors.headingColor)

            Text("A native macOS Markdown viewer and editor")
                .font(.callout)
                .foregroundColor(appSettings.theme.colors.foregroundSecondary)

            Text("Built with Swift & SwiftUI")
                .font(.caption)
                .foregroundColor(appSettings.theme.colors.foregroundSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}
```

- [ ] **Step 2: Register the Help window scene in MkdnApp**

In `mkdnEntry/main.swift`, add the Help window scene inside the `MkdnApp` body, after the `WindowGroup` scene:

```swift
        Window("mkdn Help", id: "help-window") {
            HelpWindowView()
                .environment(appSettings)
        }
        .defaultSize(width: 600, height: 450)
```

Also add an `onReceive` for the notification on the `WindowGroup`. Add `import Combine` if not already present. Add this inside the `WindowGroup` modifiers, after `.commands { ... }`:

```swift
        // At the top of MkdnApp struct, add:
        @Environment(\.openWindow) private var openWindow
```

Then handle the notification in the `WindowGroup` content. Actually, since `@Environment(\.openWindow)` is not available in `App`, use a different approach. Add the `onReceive` to `DocumentWindow`:

In `mkdn/App/DocumentWindow.swift`, add after the `.onChange(of: FileOpenCoordinator.shared.pendingURLs)` block:

```swift
            .onReceive(NotificationCenter.default.publisher(for: .openHelpWindow)) { _ in
                openWindow(id: "help-window")
            }
```

- [ ] **Step 3: Build and verify**

Run: `swift build`
Expected: Build succeeds. Running the app and selecting Help → mkdn Help opens the help window.

- [ ] **Step 4: Commit**

```
git add mkdn/Features/Help/Views/HelpWindowView.swift mkdnEntry/main.swift mkdn/App/DocumentWindow.swift
git commit -m "feat(help): add Help window with shortcuts, features, CLI, and about sections"
```

---

### Task 3: Guide Section Model

**Files:**
- Create: `mkdn/Features/Help/Models/GuideSection.swift`

- [ ] **Step 1: Create GuideSection enum**

```swift
// mkdn/Features/Help/Models/GuideSection.swift
import SwiftUI

/// Sidebar sections for the Markdown Guide window.
enum GuideSection: String, CaseIterable, Identifiable {
    case headings = "Headings"
    case textStyling = "Text Styling"
    case linksImages = "Links & Images"
    case lists = "Lists"
    case code = "Code"
    case blockquotes = "Blockquotes"
    case tables = "Tables"
    case horizontalRules = "Horizontal Rules"
    case taskLists = "Task Lists"
    case mermaid = "Mermaid"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .headings: "textformat.size"
        case .textStyling: "bold.italic.underline"
        case .linksImages: "link"
        case .lists: "list.bullet"
        case .code: "chevron.left.forwardslash.chevron.right"
        case .blockquotes: "text.quote"
        case .tables: "tablecells"
        case .horizontalRules: "minus"
        case .taskLists: "checklist"
        case .mermaid: "chart.bar.doc.horizontal"
        }
    }
}
```

- [ ] **Step 2: Build and verify**

Run: `swift build`
Expected: Build succeeds.

- [ ] **Step 3: Commit**

```
git add mkdn/Features/Help/Models/GuideSection.swift
git commit -m "feat(help): add GuideSection model for Markdown Guide sidebar"
```

---

### Task 4: Markdown Guide Window View

**Files:**
- Create: `mkdn/Features/Help/Views/MarkdownGuideView.swift`
- Modify: `mkdnEntry/main.swift`
- Modify: `mkdn/App/DocumentWindow.swift`

- [ ] **Step 1: Create the Markdown Guide view**

```swift
// mkdn/Features/Help/Views/MarkdownGuideView.swift
import SwiftUI

/// Floating read-only Markdown syntax reference window.
struct MarkdownGuideView: View {
    @Environment(AppSettings.self) private var appSettings
    @State private var selectedSection: GuideSection = .headings

    var body: some View {
        NavigationSplitView {
            List(GuideSection.allCases, selection: $selectedSection) { section in
                Label(section.rawValue, systemImage: section.icon)
            }
            .navigationSplitViewColumnWidth(min: 130, ideal: 150, max: 180)
        } detail: {
            ScrollView {
                guideContent(for: selectedSection)
                    .padding(24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(appSettings.theme.colors.background)
        }
        .frame(minWidth: 550, minHeight: 400)
    }

    @ViewBuilder
    private func guideContent(for section: GuideSection) -> some View {
        switch section {
        case .headings: HeadingsGuide()
        case .textStyling: TextStylingGuide()
        case .linksImages: LinksImagesGuide()
        case .lists: ListsGuide()
        case .code: CodeGuide()
        case .blockquotes: BlockquotesGuide()
        case .tables: TablesGuide()
        case .horizontalRules: HorizontalRulesGuide()
        case .taskLists: TaskListsGuide()
        case .mermaid: MermaidGuide()
        }
    }
}

// MARK: - Shared Components

struct GuideSectionHeader: View {
    let title: String
    let subtitle: String
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2.bold())
                .foregroundColor(appSettings.theme.colors.headingColor)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(appSettings.theme.colors.foregroundSecondary)
        }
        .padding(.bottom, 12)
    }
}

struct SyntaxResultPanel: View {
    let syntax: String
    let result: AnyView
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("SYNTAX")
                    .font(.caption2.bold())
                    .foregroundColor(appSettings.theme.colors.foregroundSecondary)
                    .tracking(1)
                Text(syntax)
                    .font(.system(.callout, design: .monospaced))
                    .foregroundColor(appSettings.theme.colors.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(appSettings.theme.colors.codeBackground)
            )

            VStack(alignment: .leading, spacing: 4) {
                Text("RESULT")
                    .font(.caption2.bold())
                    .foregroundColor(appSettings.theme.colors.foregroundSecondary)
                    .tracking(1)
                result
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(appSettings.theme.colors.codeBackground)
            )
        }
    }
}

// MARK: - Section Views

private struct HeadingsGuide: View {
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GuideSectionHeader(title: "Headings", subtitle: "Use # symbols to create headings. More #'s = smaller heading.")
            SyntaxResultPanel(
                syntax: "# Heading 1\n## Heading 2\n### Heading 3\n#### Heading 4",
                result: AnyView(
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Heading 1").font(.system(size: 22, weight: .bold)).foregroundColor(appSettings.theme.colors.headingColor)
                        Text("Heading 2").font(.system(size: 18, weight: .semibold)).foregroundColor(appSettings.theme.colors.headingColor)
                        Text("Heading 3").font(.system(size: 15, weight: .semibold)).foregroundColor(appSettings.theme.colors.headingColor)
                        Text("Heading 4").font(.system(size: 13, weight: .semibold)).foregroundColor(appSettings.theme.colors.foreground)
                    }
                )
            )
        }
    }
}

private struct TextStylingGuide: View {
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GuideSectionHeader(title: "Text Styling", subtitle: "Emphasis, strong, strikethrough, and inline code.")
            SyntaxResultPanel(
                syntax: "*italic*\n**bold**\n***bold italic***\n~~strikethrough~~\n`inline code`",
                result: AnyView(
                    VStack(alignment: .leading, spacing: 6) {
                        Text("italic").italic().foregroundColor(appSettings.theme.colors.foreground)
                        Text("bold").bold().foregroundColor(appSettings.theme.colors.foreground)
                        Text("bold italic").bold().italic().foregroundColor(appSettings.theme.colors.foreground)
                        Text("strikethrough").strikethrough().foregroundColor(appSettings.theme.colors.foregroundSecondary)
                        Text("inline code")
                            .font(.system(.callout, design: .monospaced))
                            .foregroundColor(appSettings.theme.colors.accent)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(RoundedRectangle(cornerRadius: 3).fill(appSettings.theme.colors.codeBackground))
                    }
                )
            )
        }
    }
}

private struct LinksImagesGuide: View {
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GuideSectionHeader(title: "Links & Images", subtitle: "Inline links, reference links, and images.")
            SyntaxResultPanel(
                syntax: "[Link text](https://example.com)\n![Alt text](image.png)\n[Reference link][1]\n\n[1]: https://example.com",
                result: AnyView(
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Link text").underline().foregroundColor(appSettings.theme.colors.linkColor)
                        HStack(spacing: 4) {
                            Image(systemName: "photo")
                                .foregroundColor(appSettings.theme.colors.foregroundSecondary)
                            Text("Alt text").foregroundColor(appSettings.theme.colors.foregroundSecondary)
                        }
                        Text("Reference link").underline().foregroundColor(appSettings.theme.colors.linkColor)
                    }
                )
            )
        }
    }
}

private struct ListsGuide: View {
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GuideSectionHeader(title: "Lists", subtitle: "Ordered, unordered, and nested lists.")
            SyntaxResultPanel(
                syntax: "- Item one\n- Item two\n  - Nested item\n\n1. First\n2. Second\n3. Third",
                result: AnyView(
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Item one").foregroundColor(appSettings.theme.colors.foreground)
                        Text("• Item two").foregroundColor(appSettings.theme.colors.foreground)
                        Text("    ◦ Nested item").foregroundColor(appSettings.theme.colors.foreground)
                        Text("").frame(height: 4)
                        Text("1. First").foregroundColor(appSettings.theme.colors.foreground)
                        Text("2. Second").foregroundColor(appSettings.theme.colors.foreground)
                        Text("3. Third").foregroundColor(appSettings.theme.colors.foreground)
                    }
                )
            )
        }
    }
}

private struct CodeGuide: View {
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GuideSectionHeader(title: "Code", subtitle: "Fenced code blocks with optional language for syntax highlighting.")
            SyntaxResultPanel(
                syntax: "```swift\nlet greeting = \"Hello\"\nprint(greeting)\n```",
                result: AnyView(
                    VStack(alignment: .leading, spacing: 2) {
                        Text("let greeting = \"Hello\"")
                            .font(.system(.callout, design: .monospaced))
                            .foregroundColor(appSettings.theme.colors.codeForeground)
                        Text("print(greeting)")
                            .font(.system(.callout, design: .monospaced))
                            .foregroundColor(appSettings.theme.colors.codeForeground)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 6).fill(appSettings.theme.colors.codeBackground))
                )
            )
        }
    }
}

private struct BlockquotesGuide: View {
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GuideSectionHeader(title: "Blockquotes", subtitle: "Use > for quoted text. Nest with >>.")
            SyntaxResultPanel(
                syntax: "> This is a quote\n>\n>> Nested quote",
                result: AnyView(
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 1).fill(appSettings.theme.colors.blockquoteBorder).frame(width: 3)
                            Text("This is a quote").foregroundColor(appSettings.theme.colors.foreground)
                        }
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 1).fill(appSettings.theme.colors.blockquoteBorder).frame(width: 3)
                            RoundedRectangle(cornerRadius: 1).fill(appSettings.theme.colors.blockquoteBorder).frame(width: 3)
                            Text("Nested quote").foregroundColor(appSettings.theme.colors.foreground)
                        }
                    }
                )
            )
        }
    }
}

private struct TablesGuide: View {
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GuideSectionHeader(title: "Tables", subtitle: "Pipe syntax with header separator. Use colons for alignment.")
            SyntaxResultPanel(
                syntax: "| Left | Center | Right |\n|:-----|:------:|------:|\n| A    | B      | C     |",
                result: AnyView(
                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            tableCell("Left", bold: true)
                            tableCell("Center", bold: true)
                            tableCell("Right", bold: true)
                        }
                        Divider()
                        HStack(spacing: 0) {
                            tableCell("A", bold: false)
                            tableCell("B", bold: false)
                            tableCell("C", bold: false)
                        }
                    }
                    .background(RoundedRectangle(cornerRadius: 4).stroke(appSettings.theme.colors.border, lineWidth: 1))
                )
            )
        }
    }

    private func tableCell(_ text: String, bold: Bool) -> some View {
        Text(text)
            .font(bold ? .callout.bold() : .callout)
            .foregroundColor(appSettings.theme.colors.foreground)
            .frame(maxWidth: .infinity)
            .padding(6)
    }
}

private struct HorizontalRulesGuide: View {
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GuideSectionHeader(title: "Horizontal Rules", subtitle: "Three or more dashes, asterisks, or underscores on their own line.")
            SyntaxResultPanel(
                syntax: "---\n***\n___",
                result: AnyView(
                    VStack(spacing: 12) {
                        Divider()
                        Divider()
                        Divider()
                    }
                )
            )
        }
    }
}

private struct TaskListsGuide: View {
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GuideSectionHeader(title: "Task Lists", subtitle: "Use - [ ] for unchecked and - [x] for checked items.")
            SyntaxResultPanel(
                syntax: "- [ ] Unchecked task\n- [x] Completed task\n- [ ] Another task",
                result: AnyView(
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "square").foregroundColor(appSettings.theme.colors.foregroundSecondary)
                            Text("Unchecked task").foregroundColor(appSettings.theme.colors.foreground)
                        }
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.square.fill").foregroundColor(appSettings.theme.colors.accent)
                            Text("Completed task").foregroundColor(appSettings.theme.colors.foreground)
                        }
                        HStack(spacing: 6) {
                            Image(systemName: "square").foregroundColor(appSettings.theme.colors.foregroundSecondary)
                            Text("Another task").foregroundColor(appSettings.theme.colors.foreground)
                        }
                    }
                )
            )
        }
    }
}

private struct MermaidGuide: View {
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GuideSectionHeader(title: "Mermaid Diagrams", subtitle: "mkdn renders Mermaid diagrams inline. Wrap in a ```mermaid code fence.")

            SyntaxResultPanel(
                syntax: "```mermaid\nflowchart LR\n    A --> B --> C\n```",
                result: AnyView(
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Renders as an interactive flowchart diagram.")
                            .font(.callout)
                            .foregroundColor(appSettings.theme.colors.foreground)
                    }
                )
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("SUPPORTED DIAGRAM TYPES")
                    .font(.caption2.bold())
                    .foregroundColor(appSettings.theme.colors.foregroundSecondary)
                    .tracking(1)

                ForEach(["flowchart — Flow diagrams with nodes and edges",
                         "sequenceDiagram — Interaction between components",
                         "classDiagram — Class relationships and hierarchies",
                         "stateDiagram-v2 — State machine transitions"], id: \.self) { item in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(appSettings.theme.colors.accent)
                            .frame(width: 5, height: 5)
                        Text(item)
                            .font(.caption)
                            .foregroundColor(appSettings.theme.colors.foreground)
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 2: Register the Markdown Guide window scene in MkdnApp**

In `mkdnEntry/main.swift`, add after the Help window scene:

```swift
        Window("Markdown Guide", id: "markdown-guide") {
            MarkdownGuideView()
                .environment(appSettings)
        }
        .defaultSize(width: 650, height: 500)
        .windowStyle(.titleBar)
```

- [ ] **Step 3: Add notification handler in DocumentWindow**

In `mkdn/App/DocumentWindow.swift`, add after the `.onReceive` for `openHelpWindow`:

```swift
            .onReceive(NotificationCenter.default.publisher(for: .openMarkdownGuide)) { _ in
                openWindow(id: "markdown-guide")
            }
```

- [ ] **Step 4: Build and verify**

Run: `swift build`
Expected: Build succeeds. Help → Markdown Guide opens the guide window with sidebar and syntax/result panels.

- [ ] **Step 5: Commit**

```
git add mkdn/Features/Help/Views/MarkdownGuideView.swift mkdnEntry/main.swift mkdn/App/DocumentWindow.swift
git commit -m "feat(help): add Markdown Guide window with syntax reference for all elements"
```

---

### Task 5: Lint Data Model and Rule Engine

**Files:**
- Create: `mkdn/Features/Linter/LintIssue.swift`
- Create: `mkdn/Features/Linter/LintRule.swift`
- Create: `mkdn/Features/Linter/MarkdownLinter.swift`
- Create: `mkdnTests/Unit/Features/MarkdownLinterTests.swift`

- [ ] **Step 1: Create LintIssue model**

```swift
// mkdn/Features/Linter/LintIssue.swift
import Foundation

/// A single lint warning found in the Markdown content.
struct LintIssue: Identifiable, Equatable {
    let id = UUID()
    let range: Range<String.Index>
    let message: String
    let rule: LintRule

    static func == (lhs: LintIssue, rhs: LintIssue) -> Bool {
        lhs.range == rhs.range && lhs.message == rhs.message && lhs.rule == rhs.rule
    }
}
```

- [ ] **Step 2: Create LintRule enum**

```swift
// mkdn/Features/Linter/LintRule.swift
import Foundation

/// All lint rules the Markdown linter checks.
enum LintRule: String, CaseIterable, Sendable {
    // Essential
    case unclosedCodeFence
    case brokenLinkSyntax
    case malformedTable
    case unclosedEmphasis

    // Style
    case mixedListMarkers
    case headingLevelSkip
    case missingBlankLine
    case consecutiveBlankLines
    case noLanguageOnCodeFence
}
```

- [ ] **Step 3: Create MarkdownLinter engine**

```swift
// mkdn/Features/Linter/MarkdownLinter.swift
import Foundation

/// Analyzes Markdown content and returns lint issues.
struct MarkdownLinter {
    /// Lint the given Markdown content and return all issues found.
    func lint(_ content: String) -> [LintIssue] {
        var issues: [LintIssue] = []
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

        issues.append(contentsOf: checkUnclosedCodeFences(content, lines: lines))
        issues.append(contentsOf: checkNoLanguageOnCodeFence(content, lines: lines))
        issues.append(contentsOf: checkBrokenLinkSyntax(content))
        issues.append(contentsOf: checkUnclosedEmphasis(content, lines: lines))
        issues.append(contentsOf: checkMalformedTables(content, lines: lines))
        issues.append(contentsOf: checkMixedListMarkers(content, lines: lines))
        issues.append(contentsOf: checkHeadingLevelSkip(content, lines: lines))
        issues.append(contentsOf: checkMissingBlankLines(content, lines: lines))
        issues.append(contentsOf: checkConsecutiveBlankLines(content, lines: lines))

        return issues
    }

    // MARK: - Essential Rules

    private func checkUnclosedCodeFences(_ content: String, lines: [String]) -> [LintIssue] {
        var issues: [LintIssue] = []
        var openFenceIndex: Int?
        var offset = content.startIndex

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") {
                if openFenceIndex == nil {
                    openFenceIndex = index
                } else {
                    openFenceIndex = nil
                }
            }
            if index < lines.count - 1 {
                offset = content.index(offset, offsetBy: line.count + 1, limitedBy: content.endIndex) ?? content.endIndex
            }
        }

        if let openIndex = openFenceIndex {
            let lineStart = lineStartIndex(for: openIndex, in: content, lines: lines)
            let lineEnd = content.index(lineStart, offsetBy: lines[openIndex].count, limitedBy: content.endIndex) ?? content.endIndex
            issues.append(LintIssue(
                range: lineStart..<lineEnd,
                message: "Unclosed code fence — add closing ```",
                rule: .unclosedCodeFence
            ))
        }

        return issues
    }

    private func checkNoLanguageOnCodeFence(_ content: String, lines: [String]) -> [LintIssue] {
        var issues: [LintIssue] = []
        var inCodeBlock = false

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") {
                if !inCodeBlock {
                    let afterBackticks = trimmed.dropFirst(3).trimmingCharacters(in: .whitespaces)
                    if afterBackticks.isEmpty {
                        let lineStart = lineStartIndex(for: index, in: content, lines: lines)
                        let lineEnd = content.index(lineStart, offsetBy: line.count, limitedBy: content.endIndex) ?? content.endIndex
                        issues.append(LintIssue(
                            range: lineStart..<lineEnd,
                            message: "Code fence has no language — add one for syntax highlighting",
                            rule: .noLanguageOnCodeFence
                        ))
                    }
                    inCodeBlock = true
                } else {
                    inCodeBlock = false
                }
            }
        }

        return issues
    }

    private func checkBrokenLinkSyntax(_ content: String) -> [LintIssue] {
        var issues: [LintIssue] = []

        // Find [ not followed by proper ](url) pattern
        var searchStart = content.startIndex
        while let openBracket = content[searchStart...].firstIndex(of: "[") {
            // Skip if inside a code fence
            let prefix = content[content.startIndex..<openBracket]
            let backtickCount = prefix.components(separatedBy: "```").count - 1
            if backtickCount % 2 != 0 {
                searchStart = content.index(after: openBracket)
                continue
            }

            // Skip image syntax ![
            if openBracket > content.startIndex {
                let before = content.index(before: openBracket)
                if content[before] == "!" {
                    searchStart = content.index(after: openBracket)
                    continue
                }
            }

            // Look for closing ] and then (
            if let closeBracket = content[content.index(after: openBracket)...].firstIndex(of: "]") {
                let afterClose = content.index(after: closeBracket)
                if afterClose < content.endIndex {
                    if content[afterClose] == "(" {
                        // Check for closing )
                        if content[afterClose...].firstIndex(of: ")") == nil {
                            issues.append(LintIssue(
                                range: openBracket..<content.index(after: afterClose),
                                message: "Broken link — missing closing parenthesis",
                                rule: .brokenLinkSyntax
                            ))
                        }
                    } else if content[afterClose] != "[" {
                        // ] not followed by ( or [ — likely broken
                        // Skip reference-style [text][ref] and footnotes
                    }
                }
                searchStart = content.index(after: closeBracket)
            } else {
                // No closing bracket found
                let end = content.index(openBracket, offsetBy: min(20, content.distance(from: openBracket, to: content.endIndex)))
                issues.append(LintIssue(
                    range: openBracket..<end,
                    message: "Broken link — missing closing bracket ]",
                    rule: .brokenLinkSyntax
                ))
                searchStart = content.index(after: openBracket)
            }
        }

        return issues
    }

    private func checkUnclosedEmphasis(_ content: String, lines: [String]) -> [LintIssue] {
        var issues: [LintIssue] = []
        var inCodeBlock = false

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") {
                inCodeBlock.toggle()
                continue
            }
            if inCodeBlock { continue }

            // Check for unmatched ** (bold)
            let boldCount = line.components(separatedBy: "**").count - 1
            if boldCount % 2 != 0 {
                let lineStart = lineStartIndex(for: index, in: content, lines: lines)
                let lineEnd = content.index(lineStart, offsetBy: line.count, limitedBy: content.endIndex) ?? content.endIndex
                issues.append(LintIssue(
                    range: lineStart..<lineEnd,
                    message: "Unclosed bold — add closing **",
                    rule: .unclosedEmphasis
                ))
            }
        }

        return issues
    }

    private func checkMalformedTables(_ content: String, lines: [String]) -> [LintIssue] {
        var issues: [LintIssue] = []
        var inCodeBlock = false
        var headerColumnCount: Int?
        var tableStartLine: Int?

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") {
                inCodeBlock.toggle()
                headerColumnCount = nil
                tableStartLine = nil
                continue
            }
            if inCodeBlock { continue }

            if trimmed.contains("|") && !trimmed.isEmpty {
                let columns = trimmed.split(separator: "|", omittingEmptySubsequences: false)
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                    .count

                // Check if this is a separator row (---|---) — skip column check
                let isSeparator = trimmed.allSatisfy { $0 == "|" || $0 == "-" || $0 == ":" || $0 == " " }

                if headerColumnCount == nil {
                    headerColumnCount = columns
                    tableStartLine = index
                } else if !isSeparator && columns != headerColumnCount {
                    let lineStart = lineStartIndex(for: index, in: content, lines: lines)
                    let lineEnd = content.index(lineStart, offsetBy: line.count, limitedBy: content.endIndex) ?? content.endIndex
                    issues.append(LintIssue(
                        range: lineStart..<lineEnd,
                        message: "Table row has \(columns) columns, header has \(headerColumnCount!)",
                        rule: .malformedTable
                    ))
                }
            } else {
                headerColumnCount = nil
                tableStartLine = nil
            }
        }

        return issues
    }

    // MARK: - Style Rules

    private func checkMixedListMarkers(_ content: String, lines: [String]) -> [LintIssue] {
        var issues: [LintIssue] = []
        var inCodeBlock = false
        var listMarker: Character?
        var listStarted = false

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") {
                inCodeBlock.toggle()
                continue
            }
            if inCodeBlock { continue }

            if let first = trimmed.first, (first == "-" || first == "*" || first == "+"),
               trimmed.count > 1, trimmed.dropFirst().first == " " {
                if !listStarted {
                    listMarker = first
                    listStarted = true
                } else if let marker = listMarker, first != marker {
                    let lineStart = lineStartIndex(for: index, in: content, lines: lines)
                    let lineEnd = content.index(lineStart, offsetBy: line.count, limitedBy: content.endIndex) ?? content.endIndex
                    issues.append(LintIssue(
                        range: lineStart..<lineEnd,
                        message: "Mixed list markers — use \"\(marker)\" consistently",
                        rule: .mixedListMarkers
                    ))
                }
            } else if trimmed.isEmpty {
                // Allow blank lines within lists
            } else {
                listStarted = false
                listMarker = nil
            }
        }

        return issues
    }

    private func checkHeadingLevelSkip(_ content: String, lines: [String]) -> [LintIssue] {
        var issues: [LintIssue] = []
        var inCodeBlock = false
        var lastHeadingLevel = 0

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") {
                inCodeBlock.toggle()
                continue
            }
            if inCodeBlock { continue }

            if trimmed.hasPrefix("#") {
                let level = trimmed.prefix(while: { $0 == "#" }).count
                if level <= 6 && trimmed.dropFirst(level).first == " " {
                    if lastHeadingLevel > 0 && level > lastHeadingLevel + 1 {
                        let expected = String(repeating: "#", count: lastHeadingLevel + 1)
                        let lineStart = lineStartIndex(for: index, in: content, lines: lines)
                        let lineEnd = content.index(lineStart, offsetBy: line.count, limitedBy: content.endIndex) ?? content.endIndex
                        issues.append(LintIssue(
                            range: lineStart..<lineEnd,
                            message: "Heading level skipped — expected \(expected) before \(String(repeating: "#", count: level))",
                            rule: .headingLevelSkip
                        ))
                    }
                    lastHeadingLevel = level
                }
            }
        }

        return issues
    }

    private func checkMissingBlankLines(_ content: String, lines: [String]) -> [LintIssue] {
        var issues: [LintIssue] = []
        var inCodeBlock = false

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") {
                inCodeBlock.toggle()
                continue
            }
            if inCodeBlock { continue }

            // Check heading preceded by non-blank content
            if trimmed.hasPrefix("#") && trimmed.dropFirst(trimmed.prefix(while: { $0 == "#" }).count).first == " " {
                if index > 0 {
                    let prevLine = lines[index - 1].trimmingCharacters(in: .whitespaces)
                    if !prevLine.isEmpty && !prevLine.hasPrefix("#") && !prevLine.hasPrefix("```") {
                        let lineStart = lineStartIndex(for: index, in: content, lines: lines)
                        let lineEnd = content.index(lineStart, offsetBy: line.count, limitedBy: content.endIndex) ?? content.endIndex
                        issues.append(LintIssue(
                            range: lineStart..<lineEnd,
                            message: "Missing blank line before heading",
                            rule: .missingBlankLine
                        ))
                    }
                }
            }
        }

        return issues
    }

    private func checkConsecutiveBlankLines(_ content: String, lines: [String]) -> [LintIssue] {
        var issues: [LintIssue] = []
        var consecutiveCount = 0
        var blankRunStart: Int?

        for (index, line) in lines.enumerated() {
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                consecutiveCount += 1
                if consecutiveCount == 1 {
                    blankRunStart = index
                }
            } else {
                if consecutiveCount >= 3, let start = blankRunStart {
                    let lineStart = lineStartIndex(for: start, in: content, lines: lines)
                    let endLine = start + consecutiveCount - 1
                    let lineEnd = lineStartIndex(for: endLine, in: content, lines: lines)
                    let actualEnd = content.index(lineEnd, offsetBy: lines[endLine].count, limitedBy: content.endIndex) ?? content.endIndex
                    issues.append(LintIssue(
                        range: lineStart..<actualEnd,
                        message: "Multiple consecutive blank lines",
                        rule: .consecutiveBlankLines
                    ))
                }
                consecutiveCount = 0
                blankRunStart = nil
            }
        }

        return issues
    }

    // MARK: - Helpers

    private func lineStartIndex(for lineNumber: Int, in content: String, lines: [String]) -> String.Index {
        var index = content.startIndex
        for i in 0..<lineNumber {
            index = content.index(index, offsetBy: lines[i].count + 1, limitedBy: content.endIndex) ?? content.endIndex
        }
        return index
    }
}
```

- [ ] **Step 4: Write tests for the linter**

```swift
// mkdnTests/Unit/Features/MarkdownLinterTests.swift
import Testing

@testable import mkdnLib

@Suite("MarkdownLinter")
struct MarkdownLinterTests {
    let linter = MarkdownLinter()

    // MARK: - Essential Rules

    @Test("Detects unclosed code fence")
    func unclosedCodeFence() {
        let content = "Some text\n```swift\nlet x = 1\n"
        let issues = linter.lint(content)
        let match = issues.first { $0.rule == .unclosedCodeFence }
        #expect(match != nil)
        #expect(match?.message.contains("Unclosed code fence") == true)
    }

    @Test("No issue for properly closed code fence")
    func closedCodeFence() {
        let content = "```swift\nlet x = 1\n```\n"
        let issues = linter.lint(content)
        #expect(issues.filter { $0.rule == .unclosedCodeFence }.isEmpty)
    }

    @Test("Detects broken link missing closing paren")
    func brokenLinkMissingParen() {
        let content = "Click [here](https://example.com to visit\n"
        let issues = linter.lint(content)
        let match = issues.first { $0.rule == .brokenLinkSyntax }
        #expect(match != nil)
    }

    @Test("No issue for valid link")
    func validLink() {
        let content = "Click [here](https://example.com) to visit\n"
        let issues = linter.lint(content)
        #expect(issues.filter { $0.rule == .brokenLinkSyntax }.isEmpty)
    }

    @Test("Detects unclosed bold emphasis")
    func unclosedEmphasis() {
        let content = "This is **bold text without closing\n"
        let issues = linter.lint(content)
        let match = issues.first { $0.rule == .unclosedEmphasis }
        #expect(match != nil)
        #expect(match?.message.contains("Unclosed bold") == true)
    }

    @Test("No issue for matched bold emphasis")
    func matchedEmphasis() {
        let content = "This is **bold** text\n"
        let issues = linter.lint(content)
        #expect(issues.filter { $0.rule == .unclosedEmphasis }.isEmpty)
    }

    @Test("Detects malformed table with mismatched columns")
    func malformedTable() {
        let content = "| A | B | C |\n|---|---|---|\n| 1 | 2 |\n"
        let issues = linter.lint(content)
        let match = issues.first { $0.rule == .malformedTable }
        #expect(match != nil)
        #expect(match?.message.contains("columns") == true)
    }

    @Test("No issue for valid table")
    func validTable() {
        let content = "| A | B |\n|---|---|\n| 1 | 2 |\n"
        let issues = linter.lint(content)
        #expect(issues.filter { $0.rule == .malformedTable }.isEmpty)
    }

    // MARK: - Style Rules

    @Test("Detects mixed list markers")
    func mixedListMarkers() {
        let content = "- Item one\n* Item two\n"
        let issues = linter.lint(content)
        let match = issues.first { $0.rule == .mixedListMarkers }
        #expect(match != nil)
        #expect(match?.message.contains("Mixed list markers") == true)
    }

    @Test("No issue for consistent list markers")
    func consistentListMarkers() {
        let content = "- Item one\n- Item two\n- Item three\n"
        let issues = linter.lint(content)
        #expect(issues.filter { $0.rule == .mixedListMarkers }.isEmpty)
    }

    @Test("Detects heading level skip")
    func headingLevelSkip() {
        let content = "# Title\n\n### Subsection\n"
        let issues = linter.lint(content)
        let match = issues.first { $0.rule == .headingLevelSkip }
        #expect(match != nil)
        #expect(match?.message.contains("expected ##") == true)
    }

    @Test("No issue for sequential heading levels")
    func sequentialHeadingLevels() {
        let content = "# Title\n\n## Section\n\n### Subsection\n"
        let issues = linter.lint(content)
        #expect(issues.filter { $0.rule == .headingLevelSkip }.isEmpty)
    }

    @Test("Detects missing blank line before heading")
    func missingBlankLine() {
        let content = "Some text\n## Heading\n"
        let issues = linter.lint(content)
        let match = issues.first { $0.rule == .missingBlankLine }
        #expect(match != nil)
    }

    @Test("No issue when blank line before heading")
    func blankLineBeforeHeading() {
        let content = "Some text\n\n## Heading\n"
        let issues = linter.lint(content)
        #expect(issues.filter { $0.rule == .missingBlankLine }.isEmpty)
    }

    @Test("Detects consecutive blank lines")
    func consecutiveBlankLines() {
        let content = "Text\n\n\n\nMore text\n"
        let issues = linter.lint(content)
        let match = issues.first { $0.rule == .consecutiveBlankLines }
        #expect(match != nil)
    }

    @Test("No issue for two blank lines")
    func twoBlankLines() {
        let content = "Text\n\nMore text\n"
        let issues = linter.lint(content)
        #expect(issues.filter { $0.rule == .consecutiveBlankLines }.isEmpty)
    }

    @Test("Detects code fence without language")
    func noLanguageOnCodeFence() {
        let content = "```\nsome code\n```\n"
        let issues = linter.lint(content)
        let match = issues.first { $0.rule == .noLanguageOnCodeFence }
        #expect(match != nil)
    }

    @Test("No issue for code fence with language")
    func codeFenceWithLanguage() {
        let content = "```python\nprint('hello')\n```\n"
        let issues = linter.lint(content)
        #expect(issues.filter { $0.rule == .noLanguageOnCodeFence }.isEmpty)
    }

    @Test("No lint issues inside code blocks")
    func noIssuesInsideCodeBlocks() {
        let content = "```markdown\n# Not a real heading\n**unclosed bold\n```\n"
        let issues = linter.lint(content)
        #expect(issues.filter { $0.rule == .unclosedEmphasis }.isEmpty)
        #expect(issues.filter { $0.rule == .headingLevelSkip }.isEmpty)
    }

    @Test("Empty content returns no issues")
    func emptyContent() {
        let issues = linter.lint("")
        #expect(issues.isEmpty)
    }
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `swift test --filter MarkdownLinterTests`
Expected: All tests pass. Some tests may need adjustment based on exact linter behavior — fix any failures before proceeding.

- [ ] **Step 6: Commit**

```
git add mkdn/Features/Linter/LintIssue.swift mkdn/Features/Linter/LintRule.swift mkdn/Features/Linter/MarkdownLinter.swift mkdnTests/Unit/Features/MarkdownLinterTests.swift
git commit -m "feat(linter): add MarkdownLinter engine with essential and style rules"
```

---

### Task 6: Integrate Linter with DocumentState

**Files:**
- Modify: `mkdn/App/DocumentState.swift`

- [ ] **Step 1: Add lintIssues property and debounced linting to DocumentState**

Add these properties to `DocumentState`, after the `modeOverlayLabel` property:

```swift
    // MARK: - Lint State

    public var lintIssues: [LintIssue] = []
    private let linter = MarkdownLinter()
    private var lintTask: Task<Void, Never>?
```

Add a method to trigger debounced linting, after the `switchMode(to:)` method:

```swift
    /// Runs the linter after a 300ms debounce. Called when `markdownContent` changes.
    public func scheduleLint() {
        lintTask?.cancel()
        lintTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            lintIssues = linter.lint(markdownContent)
        }
    }
```

- [ ] **Step 2: Build and verify**

Run: `swift build`
Expected: Build succeeds.

- [ ] **Step 3: Commit**

```
git add mkdn/App/DocumentState.swift
git commit -m "feat(linter): integrate MarkdownLinter with DocumentState via debounced scheduling"
```

---

### Task 7: Lint Badge View

**Files:**
- Create: `mkdn/Features/Linter/Views/LintBadgeView.swift`
- Modify: `mkdn/Features/Editor/Views/MarkdownEditorView.swift`

- [ ] **Step 1: Create LintBadgeView**

```swift
// mkdn/Features/Linter/Views/LintBadgeView.swift
import SwiftUI

/// Warning badge showing lint issue count. Hidden when count is 0.
struct LintBadgeView: View {
    let count: Int
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        if count > 0 {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
                Text("\(count)")
                    .font(.system(.caption2, design: .monospaced).bold())
            }
            .foregroundColor(.yellow)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.yellow.opacity(0.15))
            )
        }
    }
}
```

- [ ] **Step 2: Add lint badge and onChange to MarkdownEditorView**

Replace the full content of `mkdn/Features/Editor/Views/MarkdownEditorView.swift` with:

```swift
import SwiftUI

/// A plain-text Markdown editor using a native `TextEditor`.
///
/// Displays a subtle theme-accent border when focused and suppresses
/// the default system focus ring for a polished appearance.
struct MarkdownEditorView: View {
    @Binding var text: String
    @Environment(AppSettings.self) private var appSettings
    @Environment(DocumentState.self) private var documentState
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                LintBadgeView(count: documentState.lintIssues.count)
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)

            TextEditor(text: $text)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(appSettings.theme.colors.foreground)
                .scrollContentBackground(.hidden)
                .background(appSettings.theme.colors.background)
                .focused($isFocused)
                .focusEffectDisabled()
                .padding(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(
                            appSettings.theme.colors.accent.opacity(isFocused ? 0.3 : 0),
                            lineWidth: 1.5
                        )
                )
                .animation(AnimationConstants.quickShift, value: isFocused)
                .onChange(of: text) {
                    documentState.scheduleLint()
                }
        }
    }
}
```

- [ ] **Step 3: Build and verify**

Run: `swift build`
Expected: Build succeeds. When editing Markdown with lint issues, the yellow badge appears in the top-right of the editor pane.

- [ ] **Step 4: Commit**

```
git add mkdn/Features/Linter/Views/LintBadgeView.swift mkdn/Features/Editor/Views/MarkdownEditorView.swift
git commit -m "feat(linter): add lint badge and wire onChange to trigger linting"
```

---

### Task 8: Help Window and Guide Tests

**Files:**
- Create: `mkdnTests/Unit/Features/HelpSectionTests.swift`
- Create: `mkdnTests/Unit/Features/GuideSectionTests.swift`

- [ ] **Step 1: Write HelpSection tests**

```swift
// mkdnTests/Unit/Features/HelpSectionTests.swift
import Testing

@testable import mkdnLib

@Suite("HelpSection")
struct HelpSectionTests {
    @Test("All sections have unique IDs")
    func uniqueIDs() {
        let ids = HelpSection.allCases.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test("All sections have SF Symbol icons")
    func allHaveIcons() {
        for section in HelpSection.allCases {
            #expect(!section.icon.isEmpty)
        }
    }

    @Test("Has exactly 4 sections")
    func sectionCount() {
        #expect(HelpSection.allCases.count == 4)
    }
}
```

- [ ] **Step 2: Write GuideSection tests**

```swift
// mkdnTests/Unit/Features/GuideSectionTests.swift
import Testing

@testable import mkdnLib

@Suite("GuideSection")
struct GuideSectionTests {
    @Test("All sections have unique IDs")
    func uniqueIDs() {
        let ids = GuideSection.allCases.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test("All sections have SF Symbol icons")
    func allHaveIcons() {
        for section in GuideSection.allCases {
            #expect(!section.icon.isEmpty)
        }
    }

    @Test("Has exactly 10 sections")
    func sectionCount() {
        #expect(GuideSection.allCases.count == 10)
    }

    @Test("Mermaid section exists")
    func mermaidExists() {
        #expect(GuideSection.allCases.contains(.mermaid))
    }
}
```

- [ ] **Step 3: Run all new tests**

Run: `swift test --filter "HelpSectionTests|GuideSectionTests|MarkdownLinterTests"`
Expected: All tests pass.

- [ ] **Step 4: Commit**

```
git add mkdnTests/Unit/Features/HelpSectionTests.swift mkdnTests/Unit/Features/GuideSectionTests.swift
git commit -m "test(help): add tests for HelpSection, GuideSection, and MarkdownLinter"
```
