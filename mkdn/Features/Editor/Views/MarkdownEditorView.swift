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
                foregroundColor: PlatformTypeConverter.nsColor(from: appSettings.theme.colors.foreground),
                backgroundColor: PlatformTypeConverter.nsColor(from: appSettings.theme.colors.background)
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
