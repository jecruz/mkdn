#if os(macOS)
    import AppKit
    import SwiftUI

    /// Main editor view for Markdown content.
    ///
    /// Provides a syntax-highlighted text editor with live linting feedback.
    /// Uses @FocusState for managing keyboard focus and responds to changes
    /// in document text and styling settings.
    struct MarkdownEditorView: View {
        @Binding var text: String
        @Environment(DocumentState.self) private var documentState
        @Environment(AppSettings.self) private var appSettings
        @FocusState private var isFocused: Bool

        var body: some View {
            ZStack(alignment: .topTrailing) {
                LintAwareEditorView(
                    text: $text,
                    lintIssues: documentState.lintIssues,
                    font: PlatformTypeConverter.monospacedFont(),
                    foregroundColor: PlatformTypeConverter.color(from: appSettings.effectiveColors.foreground),
                    backgroundColor: PlatformTypeConverter.color(from: appSettings.effectiveColors.background)
                )
                .focused($isFocused)

                if !documentState.lintIssues.isEmpty {
                    LintBadgeView(count: documentState.lintIssues.count)
                        .padding(12)
                }
            }
            .background(appSettings.effectiveColors.background)
            .onAppear {
                isFocused = true
            }
        }
    }
#endif
