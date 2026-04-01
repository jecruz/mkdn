# Help System & Markdown Linting — Design Spec

## Overview

Add an in-app Help system and Markdown linter to mkdn. Three components:

1. **Help Window** — keyboard shortcuts, features, CLI usage, about
2. **Markdown Guide Window** — read-only syntax reference that floats alongside the editor
3. **Markdown Linter** — inline lint warnings in the editor with toolbar badge

## 1. Window Architecture

### Help Menu Structure

```
Help menu
├── mkdn Help (Cmd+?)        → HelpWindow
└── Markdown Guide (Cmd+Shift+M) → MarkdownGuideWindow
```

### Window Behavior

- Both are **singleton windows** — selecting the menu item again brings the existing window to front, no duplicates.
- Both are **read-only, non-editable**.
- Both use the **current app theme** (dark/light matches the editor).
- Markdown Guide opens as a **utility panel** (`NSPanel` style) so it floats above editor windows.
- Help Window is a standard SwiftUI `Window` scene.

### Implementation

- Register both as SwiftUI `Window` scenes in `MkdnApp.body`.
- Add a `CommandGroup(replacing: .help)` in `MkdnCommands` with menu items that call `openWindow(id:)`.
- Use `@Environment(\.openWindow)` to open from menu commands.

## 2. Help Window

### Layout

Sidebar + detail pane. Sidebar uses `List` with `selection` binding. Detail pane swaps content based on selection.

Window size: ~600x450, resizable.

### Sections

| Section | Content |
|---------|---------|
| **Shortcuts** | All keyboard shortcuts grouped by category (File, View, Find, Print). Each entry shows action name and shortcut badge. |
| **Features** | Brief overview of capabilities: preview/edit modes, themes, Mermaid diagrams, drag-and-drop, syntax highlighting. |
| **CLI Usage** | `mkdn file.md`, `mkdn --help`, supported file extensions (`.md`, `.markdown`), default app registration. |
| **About** | Version number, credits, project link. |

### Design Details

- No search — content is small enough to browse.
- Shortcut badges styled with monospace font, subtle background (matches mockup).
- Shortcuts grouped by category: File, View, Find, Print.
- Features section uses icon + description rows.

## 3. Markdown Guide Window

### Layout

Sidebar + detail pane with syntax/result side-by-side panels per section. Floats as utility panel above editor windows.

Window size: ~650x500, resizable.

### Sections

| Section | Coverage |
|---------|----------|
| **Headings** | `#` through `######` |
| **Text Styling** | Bold, italic, bold italic, strikethrough, inline code |
| **Links & Images** | `[text](url)`, `![alt](path)`, reference-style links |
| **Lists** | Ordered, unordered, nested |
| **Code** | Fenced blocks with language identifier, indented blocks |
| **Blockquotes** | Single and nested `>` |
| **Tables** | Pipe syntax, column alignment (`:---`, `:---:`, `---:`) |
| **Horizontal Rules** | `---`, `***`, `___` |
| **Task Lists** | `- [ ]` unchecked, `- [x]` checked |
| **Mermaid** | Basic diagram types mkdn supports (flowchart, sequence, class, state) |

### Per-Section Layout

```
┌──────────────────────────────────────────┐
│  Syntax (monospace)    │  Result          │
│  # Heading 1           │  Heading 1       │
│  ## Heading 2          │  Heading 2       │
└──────────────────────────────────────────┘
```

- Left panel: monospace font, Markdown symbols highlighted in accent color.
- Right panel: rendered output styled to match mkdn's preview theme.
- Scrollable content area per section.

## 4. Markdown Linter

### Architecture

```
DocumentState.markdownContent (changes)
    → MarkdownLinter.lint(content)
    → [LintIssue]
    → LintOverlayView (underlines in editor)
    → Toolbar badge (issue count)
```

### Data Model

```swift
struct LintIssue {
    let range: Range<String.Index>  // location in content
    let message: String             // human-readable description
    let rule: LintRule              // which rule triggered
}

enum LintRule: String, CaseIterable {
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

### Lint Rules — Essential

| Rule | Trigger | Message |
|------|---------|---------|
| `unclosedCodeFence` | Opening ` ``` ` without matching close | "Unclosed code fence — add closing ` ``` `" |
| `brokenLinkSyntax` | `[text(url)` — missing `]` or `)` | "Broken link — check brackets and parentheses" |
| `malformedTable` | Mismatched column counts between rows | "Table row has N columns, header has M" |
| `unclosedEmphasis` | `**bold` without closing `**` | "Unclosed bold — add closing `**`" |

### Lint Rules — Style

| Rule | Trigger | Message |
|------|---------|---------|
| `mixedListMarkers` | `-` and `*` in the same list | "Mixed list markers — use `-` consistently" |
| `headingLevelSkip` | `#` followed by `###` (skipped `##`) | "Heading level skipped — expected `##` before `###`" |
| `missingBlankLine` | Content directly before/after heading or code block | "Missing blank line before heading" |
| `consecutiveBlankLines` | 3+ blank lines in a row | "Multiple consecutive blank lines" |
| `noLanguageOnCodeFence` | ` ``` ` without language identifier | "Code fence has no language — add one for syntax highlighting" |

### Display

- **Yellow wavy underline** beneath problematic text in the editor.
- **Tooltip on hover** showing the issue message and suggestion.
- **Toolbar badge** showing issue count with warning icon. Hidden when count is 0.

### Timing

- Linting runs **debounced** — 300ms after the user stops typing.
- Runs on the main actor since it reads `markdownContent` from `DocumentState`.
- Results stored as `[LintIssue]` on `DocumentState` (or a dedicated `LintState`).

### Scope Boundaries

- No severity levels — everything is a warning.
- No configuration or rule toggles.
- No auto-fix — suggestions only.
- No gutter markers or bottom panel.

## 5. File Structure

```
mkdn/
├── App/
│   └── MkdnCommands.swift          # Add Help menu items
├── Features/
│   ├── Help/
│   │   ├── Views/
│   │   │   ├── HelpWindow.swift         # Help window scene + content
│   │   │   └── MarkdownGuideWindow.swift # Markdown guide window scene
│   │   └── Models/
│   │       ├── HelpSection.swift        # Enum for help sidebar sections
│   │       └── GuideSection.swift       # Enum for guide sidebar sections
│   ├── Linter/
│   │   ├── MarkdownLinter.swift         # Lint engine, returns [LintIssue]
│   │   ├── LintIssue.swift              # Issue data model
│   │   ├── LintRule.swift               # Rule enum + detection logic
│   │   └── Views/
│   │       └── LintBadgeView.swift      # Toolbar warning badge
│   └── Editor/
│       └── Views/
│           └── MarkdownEditorView.swift # Add lint underline overlay
└── mkdnEntry/
    └── main.swift                       # Register Help + Guide window scenes
```

## 6. Integration Points

- `MkdnApp` (main.swift): Register `HelpWindow` and `MarkdownGuideWindow` as `Window` scenes.
- `MkdnCommands`: Replace `.help` command group with "mkdn Help" and "Markdown Guide" menu items.
- `DocumentState`: Add `lintIssues: [LintIssue]` property, updated by debounced linter.
- `MarkdownEditorView`: Overlay lint underlines based on `lintIssues`.
- Toolbar: Add `LintBadgeView` showing issue count.
