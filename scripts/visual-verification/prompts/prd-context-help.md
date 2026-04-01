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
