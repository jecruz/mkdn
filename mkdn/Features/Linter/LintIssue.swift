import Foundation

/// A single lint warning found in the Markdown content.
public struct LintIssue: Identifiable, Equatable {
    public let id = UUID()
    public let range: Range<String.Index>
    public let message: String
    public let rule: LintRule

    public static func == (lhs: LintIssue, rhs: LintIssue) -> Bool {
        lhs.range == rhs.range && lhs.message == rhs.message && lhs.rule == rhs.rule
    }
}
