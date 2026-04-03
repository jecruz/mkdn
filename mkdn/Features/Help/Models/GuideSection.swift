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
