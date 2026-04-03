import Foundation

/// Analyzes Markdown content and returns lint issues.
public struct MarkdownLinter {
    public init() {}

    /// Lint the given Markdown content and return all issues found.
    public func lint(_ content: String) -> [LintIssue] {
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

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") {
                if openFenceIndex == nil {
                    openFenceIndex = index
                } else {
                    openFenceIndex = nil
                }
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

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") {
                inCodeBlock.toggle()
                headerColumnCount = nil
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
