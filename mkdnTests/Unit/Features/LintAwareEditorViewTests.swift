import Testing
import AppKit

@testable import mkdnLib

/// Tests for the lint underline coordination logic.
///
/// LintAwareEditorView is an NSViewRepresentable — its view logic can't be
/// directly unit tested. These tests verify the NSRange conversion helper
/// (tested via a small test double) and the MarkdownLinter-to-underline
/// pipeline end-to-end.
@Suite("LintAwareEditorView")
struct LintAwareEditorViewTests {
    let linter = MarkdownLinter()

    @Test("Lint issues from unclosed fence produce non-empty ranges")
    func unclosedFenceRangesAreNonEmpty() {
        let content = "```swift\nlet x = 1\n"
        let issues = linter.lint(content)
        #expect(!issues.isEmpty)
        for issue in issues {
            #expect(issue.range.lowerBound < issue.range.upperBound)
        }
    }

    @Test("Lint issue range lower bound is within content bounds")
    func rangesAreWithinContent() {
        let content = "**unclosed\nsome more text\n"
        let issues = linter.lint(content)
        let emphasisIssues = issues.filter { $0.rule == .unclosedEmphasis }
        #expect(!emphasisIssues.isEmpty)
        for issue in emphasisIssues {
            #expect(issue.range.lowerBound >= content.startIndex)
            #expect(issue.range.upperBound <= content.endIndex)
        }
    }

    @Test("NSRange conversion produces valid range for ASCII content")
    func nsRangeConversionASCII() {
        let content = "Hello world"
        let range = content.index(content.startIndex, offsetBy: 6)..<content.index(content.startIndex, offsetBy: 11)
        let nsRange = _nsRange(from: range, in: content)
        #expect(nsRange != nil)
        #expect(nsRange?.location == 6)
        #expect(nsRange?.length == 5)
    }

    @Test("NSRange conversion produces valid range for multibyte content")
    func nsRangeConversionMultibyte() {
        let content = "Hello 🌍 world"
        // Range covering "world" after the emoji
        guard let worldStart = content.range(of: "world")?.lowerBound,
              let worldEnd = content.range(of: "world")?.upperBound else {
            Issue.record("Could not find 'world' in content")
            return
        }
        let nsRange = _nsRange(from: worldStart..<worldEnd, in: content)
        #expect(nsRange != nil)
        // UTF-16 offset: "Hello " = 6, "🌍" = 2 UTF-16 units, " " = 1 → 9
        #expect(nsRange?.location == 9)
        #expect(nsRange?.length == 5)
    }

    @Test("Empty content produces no lint issues")
    func emptyContentNoIssues() {
        let issues = linter.lint("")
        #expect(issues.isEmpty)
    }

    @Test("Lint issues for multiple problems all produce valid ranges")
    func multipleIssuesAllValid() {
        let content = "```\nunclosed code fence\n**unclosed bold\n"
        let issues = linter.lint(content)
        #expect(!issues.isEmpty)
        for issue in issues {
            #expect(issue.range.lowerBound >= content.startIndex)
            #expect(issue.range.upperBound <= content.endIndex)
            #expect(issue.range.lowerBound < issue.range.upperBound)
        }
    }

    @Test("NSRange conversion handles edge case of single character")
    func nsRangeConversionSingleChar() {
        let content = "a"
        let range = content.startIndex..<content.endIndex
        let nsRange = _nsRange(from: range, in: content)
        #expect(nsRange != nil)
        #expect(nsRange?.location == 0)
        #expect(nsRange?.length == 1)
    }

    @Test("NSRange conversion for range at end of content")
    func nsRangeConversionAtEnd() {
        let content = "Hello world"
        let range = content.index(content.startIndex, offsetBy: 6)..<content.endIndex
        let nsRange = _nsRange(from: range, in: content)
        #expect(nsRange != nil)
        #expect(nsRange?.location == 6)
        #expect(nsRange?.length == 5)
    }

    @Test("Broken link syntax produces valid range")
    func brokenLinkRangeValid() {
        let content = "Click [here](https://example.com\n"
        let issues = linter.lint(content)
        let linkIssues = issues.filter { $0.rule == .brokenLinkSyntax }
        #expect(!linkIssues.isEmpty)
        for issue in linkIssues {
            #expect(issue.range.lowerBound >= content.startIndex)
            #expect(issue.range.upperBound <= content.endIndex)
        }
    }

    @Test("Heading level skip produces valid range")
    func headingLevelSkipRangeValid() {
        let content = "# Heading\n### Skipped level\n"
        let issues = linter.lint(content)
        let skipIssues = issues.filter { $0.rule == .headingLevelSkip }
        #expect(!skipIssues.isEmpty)
        for issue in skipIssues {
            #expect(issue.range.lowerBound >= content.startIndex)
            #expect(issue.range.upperBound <= content.endIndex)
        }
    }
}

/// Test helper exposing the private nsRange conversion from LintAwareEditorView.
/// Duplicates the logic so it can be tested independently.
private func _nsRange(from range: Range<String.Index>, in string: String) -> NSRange? {
    guard let lower = range.lowerBound.samePosition(in: string.utf16),
          let upper = range.upperBound.samePosition(in: string.utf16) else {
        return nil
    }
    let start = string.utf16.distance(from: string.utf16.startIndex, to: lower)
    let length = string.utf16.distance(from: lower, to: upper)
    return NSRange(location: start, length: length)
}
