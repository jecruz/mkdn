import SwiftUI

/// Floating read-only Markdown syntax reference window.
public struct MarkdownGuideView: View {
    @Environment(AppSettings.self) private var appSettings
    @State private var selectedSection: GuideSection? = .headings

    public init() {}

    public var body: some View {
        NavigationSplitView {
            List(GuideSection.allCases, selection: $selectedSection) { section in
                Label(section.rawValue, systemImage: section.icon)
                    .tag(section)
            }
            .navigationSplitViewColumnWidth(min: 130, ideal: 150, max: 180)
        } detail: {
            ScrollView {
                guideContent(for: selectedSection ?? .headings)
                    .padding(24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(appSettings.effectiveColors.background)
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
                .foregroundColor(appSettings.effectiveColors.headingColor)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(appSettings.effectiveColors.foregroundSecondary)
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
                    .foregroundColor(appSettings.effectiveColors.foregroundSecondary)
                    .tracking(1)
                Text(syntax)
                    .font(.system(.callout, design: .monospaced))
                    .foregroundColor(appSettings.effectiveColors.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(appSettings.effectiveColors.codeBackground)
            )

            VStack(alignment: .leading, spacing: 4) {
                Text("RESULT")
                    .font(.caption2.bold())
                    .foregroundColor(appSettings.effectiveColors.foregroundSecondary)
                    .tracking(1)
                result
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(appSettings.effectiveColors.codeBackground)
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
                        Text("Heading 1").font(.system(size: 22, weight: .bold)).foregroundColor(appSettings.effectiveColors.headingColor)
                        Text("Heading 2").font(.system(size: 18, weight: .semibold)).foregroundColor(appSettings.effectiveColors.headingColor)
                        Text("Heading 3").font(.system(size: 15, weight: .semibold)).foregroundColor(appSettings.effectiveColors.headingColor)
                        Text("Heading 4").font(.system(size: 13, weight: .semibold)).foregroundColor(appSettings.effectiveColors.foreground)
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
                        Text("italic").italic().foregroundColor(appSettings.effectiveColors.foreground)
                        Text("bold").bold().foregroundColor(appSettings.effectiveColors.foreground)
                        Text("bold italic").bold().italic().foregroundColor(appSettings.effectiveColors.foreground)
                        Text("strikethrough").strikethrough().foregroundColor(appSettings.effectiveColors.foregroundSecondary)
                        Text("inline code")
                            .font(.system(.callout, design: .monospaced))
                            .foregroundColor(appSettings.effectiveColors.accent)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(RoundedRectangle(cornerRadius: 3).fill(appSettings.effectiveColors.codeBackground))
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
                        Text("Link text").underline().foregroundColor(appSettings.effectiveColors.linkColor)
                        HStack(spacing: 4) {
                            Image(systemName: "photo")
                                .foregroundColor(appSettings.effectiveColors.foregroundSecondary)
                            Text("Alt text").foregroundColor(appSettings.effectiveColors.foregroundSecondary)
                        }
                        Text("Reference link").underline().foregroundColor(appSettings.effectiveColors.linkColor)
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
                        Text("• Item one").foregroundColor(appSettings.effectiveColors.foreground)
                        Text("• Item two").foregroundColor(appSettings.effectiveColors.foreground)
                        Text("    ◦ Nested item").foregroundColor(appSettings.effectiveColors.foreground)
                        Text("").frame(height: 4)
                        Text("1. First").foregroundColor(appSettings.effectiveColors.foreground)
                        Text("2. Second").foregroundColor(appSettings.effectiveColors.foreground)
                        Text("3. Third").foregroundColor(appSettings.effectiveColors.foreground)
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
                            .foregroundColor(appSettings.effectiveColors.codeForeground)
                        Text("print(greeting)")
                            .font(.system(.callout, design: .monospaced))
                            .foregroundColor(appSettings.effectiveColors.codeForeground)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 6).fill(appSettings.effectiveColors.codeBackground))
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
                            RoundedRectangle(cornerRadius: 1).fill(appSettings.effectiveColors.blockquoteBorder).frame(width: 3)
                            Text("This is a quote").foregroundColor(appSettings.effectiveColors.foreground)
                        }
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 1).fill(appSettings.effectiveColors.blockquoteBorder).frame(width: 3)
                            RoundedRectangle(cornerRadius: 1).fill(appSettings.effectiveColors.blockquoteBorder).frame(width: 3)
                            Text("Nested quote").foregroundColor(appSettings.effectiveColors.foreground)
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
                    .background(RoundedRectangle(cornerRadius: 4).stroke(appSettings.effectiveColors.border, lineWidth: 1))
                )
            )
        }
    }

    private func tableCell(_ text: String, bold: Bool) -> some View {
        Text(text)
            .font(bold ? .callout.bold() : .callout)
            .foregroundColor(appSettings.effectiveColors.foreground)
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
                            Image(systemName: "square").foregroundColor(appSettings.effectiveColors.foregroundSecondary)
                            Text("Unchecked task").foregroundColor(appSettings.effectiveColors.foreground)
                        }
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.square.fill").foregroundColor(appSettings.effectiveColors.accent)
                            Text("Completed task").foregroundColor(appSettings.effectiveColors.foreground)
                        }
                        HStack(spacing: 6) {
                            Image(systemName: "square").foregroundColor(appSettings.effectiveColors.foregroundSecondary)
                            Text("Another task").foregroundColor(appSettings.effectiveColors.foreground)
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
                            .foregroundColor(appSettings.effectiveColors.foreground)
                    }
                )
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("SUPPORTED DIAGRAM TYPES")
                    .font(.caption2.bold())
                    .foregroundColor(appSettings.effectiveColors.foregroundSecondary)
                    .tracking(1)

                ForEach(["flowchart — Flow diagrams with nodes and edges",
                         "sequenceDiagram — Interaction between components",
                         "classDiagram — Class relationships and hierarchies",
                         "stateDiagram-v2 — State machine transitions"], id: \.self) { item in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(appSettings.effectiveColors.accent)
                            .frame(width: 5, height: 5)
                        Text(item)
                            .font(.caption)
                            .foregroundColor(appSettings.effectiveColors.foreground)
                    }
                }
            }
        }
    }
}
