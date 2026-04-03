import AppKit
import SwiftUI

/// A plain-text editor backed by `NSTextView` that supports lint underline
/// overlays.
///
/// Functionally equivalent to `TextEditor` for the editor pane, with the
/// addition of a `lintIssues` parameter used to apply dashed yellow underlines
/// to flagged text ranges after each edit.
struct LintAwareEditorView: NSViewRepresentable {
    @Binding var text: String
    let lintIssues: [LintIssue]
    let font: NSFont
    let foregroundColor: NSColor
    let backgroundColor: NSColor

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = NSTextView()
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.allowsUndo = true
        textView.font = font
        textView.textColor = foregroundColor
        textView.backgroundColor = backgroundColor
        textView.drawsBackground = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isGrammarCheckingEnabled = false
        textView.string = text
        textView.delegate = context.coordinator

        // Remove focus ring
        textView.focusRingType = .none

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder

        // Make textView fill scroll view width
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)

        textView.textContainerInset = NSSize(width: 8, height: 8)

        context.coordinator.textView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        // Update colors when theme changes
        textView.font = font
        textView.textColor = foregroundColor
        textView.backgroundColor = backgroundColor
        scrollView.backgroundColor = backgroundColor

        // Only update string content if changed externally (not from user typing)
        if textView.string != text {
            let selectedRange = textView.selectedRange()
            textView.string = text
            // Restore cursor position if within bounds
            let safeRange = NSRange(location: min(selectedRange.location, textView.string.count), length: 0)
            textView.setSelectedRange(safeRange)
        }

        applyLintUnderlines(to: textView)
        applyLintTooltips(to: textView)
    }

    /// Apply dashed yellow underlines to text ranges flagged by the linter.
    private func applyLintUnderlines(to textView: NSTextView) {
        guard let storage = textView.textStorage else { return }
        let fullRange = NSRange(location: 0, length: storage.length)

        // Clear all previous lint underlines in one pass
        storage.removeAttribute(.underlineStyle, range: fullRange)
        storage.removeAttribute(.underlineColor, range: fullRange)

        let content = textView.string

        for issue in lintIssues {
            // Convert String.Index range to NSRange
            guard let nsRange = nsRange(from: issue.range, in: content) else { continue }
            guard nsRange.upperBound <= storage.length else { continue }

            storage.addAttribute(
                .underlineStyle,
                value: NSUnderlineStyle.patternDash.union(.single).rawValue,
                range: nsRange
            )
            storage.addAttribute(
                .underlineColor,
                value: NSColor.systemYellow,
                range: nsRange
            )
        }
    }

    /// Set tooltips on the NSTextView for each lint issue range.
    private func applyLintTooltips(to textView: NSTextView) {
        // Remove all existing tooltips
        textView.removeAllToolTips()

        let content = textView.string
        guard let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return }

        for issue in lintIssues {
            guard let nsRange = nsRange(from: issue.range, in: content) else { continue }
            guard nsRange.upperBound <= content.utf16.count else { continue }

            // Convert character range to glyph range then to bounding rect
            let glyphRange = layoutManager.glyphRange(forCharacterRange: nsRange, actualCharacterRange: nil)
            let boundingRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)

            // Offset by textContainerInset
            let inset = textView.textContainerInset
            let offsetRect = boundingRect.offsetBy(dx: inset.width, dy: inset.height)

            textView.addToolTip(offsetRect, owner: issue.message as NSString, userData: nil)
        }
    }

    private func nsRange(from range: Range<String.Index>, in string: String) -> NSRange? {
        guard let lower = range.lowerBound.samePosition(in: string.utf16),
              let upper = range.upperBound.samePosition(in: string.utf16) else {
            return nil
        }
        let start = string.utf16.distance(from: string.utf16.startIndex, to: lower)
        let length = string.utf16.distance(from: lower, to: upper)
        return NSRange(location: start, length: length)
    }
}

// MARK: - Coordinator

extension LintAwareEditorView {
    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var text: String
        weak var textView: NSTextView?

        init(text: Binding<String>) {
            _text = text
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            // Only update binding if content actually changed to avoid layout loops
            if text != textView.string {
                text = textView.string
            }
        }
    }
}
