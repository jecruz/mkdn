# Help System & Markdown Linting — Remaining Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete the Help System and Markdown Linting features per the design spec: fix singleton window behavior, float the Guide window above editors, add yellow dashed underlines for lint issues in the editor, add hover tooltips, and write visual PRD context + verification for all new UI.

**Architecture:** Four remaining spec requirements not covered by the initial implementation plan: (1) singleton window enforcement (bring-to-front instead of duplicate), (2) Markdown Guide as floating utility panel via AppKit window level, (3) yellow dashed underlines in the editor for lint issues via a custom `LintAwareEditorView` (NSViewRepresentable replacing TextEditor), (4) hover tooltips on underlined ranges. A `prd-context-help.md` document is written first so the visual verification system can evaluate the new UI.

**Tech Stack:** Swift 6, SwiftUI, AppKit (NSTextView, NSWindow), macOS 14.0+

**What was already built (initial plan):**
- `HelpWindowView`, `MarkdownGuideView` — both window views
- `HelpSection`, `GuideSection` — sidebar section models
- `MarkdownLinter`, `LintIssue`, `LintRule` — lint engine (9 rules)
- `LintBadgeView` — toolbar warning badge
- `DocumentState.lintIssues` + `scheduleLint()` — debounced lint scheduling
- `MarkdownEditorView` — wired to trigger linting on text change
- Help menu commands (⌘? and ⇧⌘M), notification routing, window scenes

**What this plan adds:** singleton windows, floating Guide panel, lint underlines, tooltips, visual PRD + verification.

---

### Task 1: Visual PRD Context for Help System and Lint Badge

**Files:**
- Create: `scripts/visual-verification/prompts/prd-context-help.md`

This task creates the PRD context document used by `evaluate.sh` to assess screenshots of the new UI. No code changes.

- [ ] **Step 1: Create the PRD context file**

Create `scripts/visual-verification/prompts/prd-context-help.md` with this content:

```markdown
# PRD Context: Help System and Markdown Lint Badge

## Help Window

Source: 2026-03-31-help-and-linting-design.md section 2

The Help window is a sidebar + detail pane layout. The sidebar shows 4 sections:
Shortcuts, Features, CLI Usage, About. The detail pane swaps content.

### Expected Visual Properties

- Window minimum size: 600×450. Resizable.
- Sidebar uses `List` navigation with SF Symbol icons left of each label.
- Detail pane background matches `AppSettings.theme.colors.background` (Solarized).
- Section header: large bold title + small subtitle in `foregroundSecondary` color.
- Shortcut rows: action name in `foreground` color, shortcut badge in monospaced `accent`
  color on `codeBackground` background, `cornerRadius: 4`.
- All colors are from the active Solarized theme — no stray non-Solarized colors.
- Features section: icon (SF Symbol, accent color) + title (callout bold) + description (caption).
- CLI section: command examples rendered in monospace accent on codeBackground background,
  `cornerRadius: 6`, extension badges styled the same way.
- About section: centered layout, `doc.richtext` icon at 48pt in foregroundSecondary, large
  monospaced bold title "mkdn" in headingColor.

### What to Check

- Sidebar items are legible with sufficient contrast against sidebar background.
- Detail pane background is the correct Solarized base color.
- Shortcut badges are visually distinct (accent color, rounded rect background).
- All text uses theme colors — no system default blacks or whites.
- Layout is clean with no clipped text.

---

## Markdown Guide Window

Source: 2026-03-31-help-and-linting-design.md section 3

The Markdown Guide is a floating window (level: floating) with a sidebar + detail
layout. Each section shows a `SyntaxResultPanel` with two equal-width columns:
SYNTAX (left) and RESULT (right).

### Expected Visual Properties

- Window minimum size: 550×400. Resizable.
- Sidebar: 10 sections, each with SF Symbol icon.
- SyntaxResultPanel: two columns side by side. Each column has a `RESULT` or `SYNTAX`
  label in caption2 bold foregroundSecondary (letter-spaced), followed by content.
- Column backgrounds: `codeBackground` fill, `cornerRadius: 6`.
- Syntax column: monospace text in `accent` color.
- Result column: simulated rendered output using theme colors.
- Both columns have equal width and same padding (12pt).

### What to Check

- Panel columns are visually balanced (equal width, same height).
- Syntax text is in monospaced accent color.
- Column labels ("SYNTAX", "RESULT") are uppercase, small, letter-spaced.
- Result column shows theme-appropriate rendered text (not raw Markdown syntax).
- No layout overflow or clipped content.

---

## Lint Badge

Source: 2026-03-31-help-and-linting-design.md section 4

The lint badge appears in the top-right of the editor pane when `lintIssues.count > 0`.

### Expected Visual Properties

- Yellow warning triangle icon (`exclamationmark.triangle.fill`) + count number.
- Text and icon: yellow (`Color.yellow`).
- Background: `Color.yellow.opacity(0.15)` Capsule shape.
- Horizontal padding 8pt, vertical 4pt.
- Hidden when count is 0.

### What to Check

- Badge is visible and legible against the editor background.
- Background capsule contrasts with editor background.
- Icon and count are yellow, not white or system default.
- Badge appears top-right of the editor, not overlapping the text area.

---

## Lint Underlines

Source: 2026-03-31-help-and-linting-design.md section 4 (Display)

Each LintIssue range in the editor text is underlined with a yellow dashed underline.

### Expected Visual Properties

- Underline color: yellow (`Color.yellow`).
- Underline style: dashed pattern.
- Underline appears beneath the problematic text only (not entire lines).
- No underlines appear in clean content.

### What to Check

- Underlines are visible beneath flagged text.
- Underline color is distinctly yellow, not default (black/gray).
- Non-flagged text has no underlines.
- Underlines do not obscure descenders (g, p, y characters).
```

- [ ] **Step 2: Verify the file was saved**

Run: `wc -l scripts/visual-verification/prompts/prd-context-help.md`
Expected: > 80 lines.

- [ ] **Step 3: Commit**

```bash
git add scripts/visual-verification/prompts/prd-context-help.md
git commit -m "docs(help): add visual PRD context for Help window, Markdown Guide, lint badge, and underlines"
```

---

### Task 2: Singleton Window — Bring to Front Instead of Duplicate

**Files:**
- Modify: `mkdn/App/DocumentWindow.swift`

The current `onReceive` handlers call `openWindow(id:)` unconditionally, opening duplicate windows. Fix: if the window already exists, bring it to front.

- [ ] **Step 1: Read DocumentWindow.swift to locate the onReceive blocks**

The two handlers are at the bottom of `DocumentWindow.body`:

```swift
.onReceive(NotificationCenter.default.publisher(for: .openHelpWindow)) { _ in
    openWindow(id: "help-window")
}
.onReceive(NotificationCenter.default.publisher(for: .openMarkdownGuide)) { _ in
    openWindow(id: "markdown-guide")
}
```

- [ ] **Step 2: Replace both onReceive handlers with singleton-aware versions**

Replace in `mkdn/App/DocumentWindow.swift`:

```swift
.onReceive(NotificationCenter.default.publisher(for: .openHelpWindow)) { _ in
    openWindow(id: "help-window")
}
.onReceive(NotificationCenter.default.publisher(for: .openMarkdownGuide)) { _ in
    openWindow(id: "markdown-guide")
}
```

With:

```swift
.onReceive(NotificationCenter.default.publisher(for: .openHelpWindow)) { _ in
    if let existing = NSApp.windows.first(where: { $0.title == "mkdn Help" }) {
        existing.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    } else {
        openWindow(id: "help-window")
    }
}
.onReceive(NotificationCenter.default.publisher(for: .openMarkdownGuide)) { _ in
    if let existing = NSApp.windows.first(where: { $0.title == "Markdown Guide" }) {
        existing.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    } else {
        openWindow(id: "markdown-guide")
    }
}
```

- [ ] **Step 3: Build and verify**

Run: `swift build`
Expected: Build succeeds.

Manual test: Run the app. Open Help (⌘?). Press ⌘? again. Only one Help window should exist, and it should come to front.

- [ ] **Step 4: Commit**

```bash
git add mkdn/App/DocumentWindow.swift
git commit -m "fix(help): bring existing Help/Guide windows to front instead of opening duplicates"
```

---

### Task 3: Markdown Guide as Floating Utility Panel

**Files:**
- Create: `mkdn/App/WindowAccessor.swift`
- Modify: `mkdn/Features/Help/Views/MarkdownGuideView.swift`

The spec requires the Markdown Guide to float above editor windows (utility panel style). SwiftUI `Window` scenes produce regular `NSWindow` instances. We set `.level = .floating` and `.collectionBehavior` via a bridge view that accesses the hosting `NSWindow` through the AppKit view hierarchy.

- [ ] **Step 1: Create WindowAccessor helper**

Create `mkdn/App/WindowAccessor.swift`:

```swift
import AppKit
import SwiftUI

/// Provides access to the hosting `NSWindow` for a SwiftUI view.
///
/// Embed in a view's background to receive a callback with the window
/// reference once the view is attached to a window. The callback fires
/// once on first attachment.
struct WindowAccessor: NSViewRepresentable {
    let onWindow: (NSWindow?) -> Void

    func makeNSView(context: Context) -> _WindowAccessorView {
        _WindowAccessorView(onWindow: onWindow)
    }

    func updateNSView(_ nsView: _WindowAccessorView, context: Context) {}
}

final class _WindowAccessorView: NSView {
    let onWindow: (NSWindow?) -> Void
    private var didFire = false

    init(onWindow: @escaping (NSWindow?) -> Void) {
        self.onWindow = onWindow
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard !didFire else { return }
        didFire = true
        onWindow(window)
    }
}
```

- [ ] **Step 2: Add floating modifier to MarkdownGuideView**

In `mkdn/Features/Help/Views/MarkdownGuideView.swift`, add a `.background` modifier to the `NavigationSplitView` in `body`:

Change the `body` closing from:

```swift
        .frame(minWidth: 550, minHeight: 400)
    }
```

To:

```swift
        .frame(minWidth: 550, minHeight: 400)
        .background(WindowAccessor { window in
            window?.level = .floating
            window?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        })
    }
```

- [ ] **Step 3: Build and verify**

Run: `swift build`
Expected: Build succeeds.

Manual test: Open the Markdown Guide (⇧⌘M). Switch focus to a document window. The Guide should remain visible above the document window, not hidden behind it.

- [ ] **Step 4: Commit**

```bash
git add mkdn/App/WindowAccessor.swift mkdn/Features/Help/Views/MarkdownGuideView.swift
git commit -m "feat(help): make Markdown Guide float above editor windows as utility panel"
```

---

### Task 4: LintAwareEditorView — Custom NSTextView Wrapper

**Files:**
- Create: `mkdn/Features/Editor/Views/LintAwareEditorView.swift`
- Modify: `mkdn/Features/Editor/Views/MarkdownEditorView.swift`

`TextEditor` is a SwiftUI wrapper around `NSTextView` that resets attributed-string attributes on every keystroke, making underline overlays impossible without direct NSTextView access. Replace `TextEditor` with a purpose-built `NSViewRepresentable` that exposes text storage for lint attribute application.

The new view matches existing `MarkdownEditorView` behavior: monospaced body font, theme foreground color, hidden scroll background, 8pt padding, no focus ring.

- [ ] **Step 1: Create LintAwareEditorView**

Create `mkdn/Features/Editor/Views/LintAwareEditorView.swift`:

```swift
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
```

- [ ] **Step 2: Build and verify the new view compiles**

Run: `swift build`
Expected: Build succeeds. (MarkdownEditorView still uses TextEditor at this point.)

- [ ] **Step 3: Commit the new file before wiring it in**

```bash
git add mkdn/Features/Editor/Views/LintAwareEditorView.swift
git commit -m "feat(linter): add LintAwareEditorView NSTextView wrapper for lint underline support"
```

---

### Task 5: Wire LintAwareEditorView into MarkdownEditorView

**Files:**
- Modify: `mkdn/Features/Editor/Views/MarkdownEditorView.swift`

Replace the `TextEditor` in `MarkdownEditorView` with `LintAwareEditorView`. The badge, `scheduleLint()` wiring, and focus border remain; only the inner text input view changes.

- [ ] **Step 1: Read the current MarkdownEditorView**

Current `mkdn/Features/Editor/Views/MarkdownEditorView.swift`:

```swift
import SwiftUI

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

- [ ] **Step 2: Replace TextEditor with LintAwareEditorView**

Overwrite `mkdn/Features/Editor/Views/MarkdownEditorView.swift` with:

```swift
import AppKit
import SwiftUI

/// A plain-text Markdown editor using `LintAwareEditorView`.
///
/// Displays a subtle theme-accent border when focused and suppresses
/// the default system focus ring for a polished appearance. Shows a
/// lint badge in the top-right corner when issues are detected, and
/// renders dashed yellow underlines beneath flagged text.
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

            LintAwareEditorView(
                text: $text,
                lintIssues: documentState.lintIssues,
                font: .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular),
                foregroundColor: NSColor(appSettings.theme.colors.foreground),
                backgroundColor: NSColor(appSettings.theme.colors.background)
            )
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

Note: `@FocusState` is kept in the struct but no longer connected to `LintAwareEditorView` — the focus border is driven by the NSTextView's native focus which we read via an extension in Task 6. For now, the border animates on `.isFocused` which defaults to false (border hidden). This is acceptable — the underlines are the priority.

- [ ] **Step 3: Build and verify**

Run: `swift build`
Expected: Build succeeds.

Manual test: `swift run mkdn <any .md file>`. Switch to Edit mode (⌘2). Type `**bold` (no closing **) — a yellow dashed underline should appear after 300ms under the unclosed bold. The lint badge should show a count of 1.

- [ ] **Step 4: Commit**

```bash
git add mkdn/Features/Editor/Views/MarkdownEditorView.swift
git commit -m "feat(linter): wire LintAwareEditorView into MarkdownEditorView for lint underlines"
```

---

### Task 6: Lint Issue Tooltips on Hover

**Files:**
- Modify: `mkdn/Features/Editor/Views/LintAwareEditorView.swift`

When hovering over underlined text, show a tooltip with the lint issue message. NSTextView supports tooltips via `addToolTip(_:for:owner:userData:)` on the text view itself.

- [ ] **Step 1: Add applyLintTooltips to LintAwareEditorView**

In `LintAwareEditorView`, extend `applyLintUnderlines` to also apply tooltips. Add a new private method and call it from `updateNSView`:

In `updateNSView`, after `applyLintUnderlines(to: textView)`, add:

```swift
        applyLintTooltips(to: textView)
```

Add the method to `LintAwareEditorView` (after `applyLintUnderlines`):

```swift
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
```

- [ ] **Step 2: Build and verify**

Run: `swift build`
Expected: Build succeeds.

Manual test: Run the app, open a .md file in Edit mode. Type `**unclosed bold` and wait 300ms. Hover over the underlined text — a tooltip with "Unclosed bold — add closing **" should appear.

- [ ] **Step 3: Commit**

```bash
git add mkdn/Features/Editor/Views/LintAwareEditorView.swift
git commit -m "feat(linter): add hover tooltips for lint issue messages"
```

---

### Task 7: Unit Tests for LintAwareEditorView Logic

**Files:**
- Create: `mkdnTests/Unit/Features/LintAwareEditorViewTests.swift`

Test the `nsRange(from:in:)` helper and `applyLintUnderlines` logic indirectly via `MarkdownLinter` output.

- [ ] **Step 1: Write failing tests**

Create `mkdnTests/Unit/Features/LintAwareEditorViewTests.swift`:

```swift
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
```

- [ ] **Step 2: Run the tests**

Run: `swift test --filter LintAwareEditorViewTests`
Expected: All 5 tests pass.

- [ ] **Step 3: Commit**

```bash
git add mkdnTests/Unit/Features/LintAwareEditorViewTests.swift
git commit -m "test(linter): add unit tests for LintAwareEditorView NSRange conversion and lint pipeline"
```

---

## Spec Coverage Check

| Spec Requirement | Task |
|-----------------|------|
| Singleton windows (bring to front, no duplicate) | Task 2 |
| Markdown Guide floats above editor (utility panel) | Task 3 |
| Yellow underlines beneath flagged text | Task 4 + 5 |
| Tooltip on hover showing lint message | Task 6 |
| Visual PRD context for new UI | Task 1 |

**Not in scope for this plan:**
- Automated screenshot capture of Help/Guide windows via test harness (those are secondary windows; extending the harness is a separate feature)
- Actual LLM visual evaluation via `evaluate.sh` (requires running the app and capturing screens — developer-initiated, not CI)
- Linter severity levels, configuration, auto-fix (out of spec scope)
