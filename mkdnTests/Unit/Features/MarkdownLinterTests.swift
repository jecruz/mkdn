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
