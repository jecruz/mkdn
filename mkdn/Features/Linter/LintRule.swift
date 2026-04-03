import Foundation

/// All lint rules the Markdown linter checks.
public enum LintRule: String, CaseIterable, Sendable {
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
