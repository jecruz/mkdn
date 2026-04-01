#if os(macOS)
    import SwiftUI
    import AppKit
#endif

extension Notification.Name {
    static let toggleEditMode = Notification.Name("toggleEditMode")
    public static let createNewMarkdownFile = Notification.Name("createNewMarkdownFile")
}

/// Welcome screen shown when no file is open.
struct WelcomeView: View {
    @Environment(AppSettings.self) private var appSettings
    @Environment(DocumentState.self) private var documentState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.richtext")
                .font(.system(size: 64))
                .foregroundColor(appSettings.theme.colors.foregroundSecondary)

            Text("mkdn")
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundColor(appSettings.theme.colors.headingColor)

            Text("Open a Markdown file to get started")
                .font(.body)
                .foregroundColor(appSettings.theme.colors.foregroundSecondary)

            VStack(alignment: .leading, spacing: 8) {
                instructionRow(
                    icon: "doc",
                    text: "Drag and drop a .md file here"
                )
                instructionRow(
                    icon: "command",
                    text: "Press Cmd+O to open a file"
                )
                instructionRow(
                    icon: "terminal",
                    text: "Run: mkdn file.md"
                )
            }
            .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(appSettings.theme.colors.background)
        #if os(macOS)
        .contextMenu {
            Button("Close Window") {
                closeWindow()
            }

            Divider()

            Button("New Markdown") {
                createNewMarkdownFile()
            }

            Divider()

            Button("Quit mkdn") {
                NSApp.terminate(nil)
            }
        }
        #endif
    }

    private func instructionRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundColor(appSettings.theme.colors.accent)
            Text(text)
                .font(.callout)
                .foregroundColor(appSettings.theme.colors.foreground)
        }
    }

    #if os(macOS)
    /// Closes the key window.
    private func closeWindow() {
        if let window = NSApp.keyWindow {
            window.close()
        } else {
            // Fallback: try to close any window with WelcomeView
            for window in NSApp.windows {
                if window.contentView is NSHostingView<WelcomeView> {
                    window.close()
                    break
                }
            }
        }
    }

    /// Creates a new markdown file and opens in edit mode.
    private func createNewMarkdownFile() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let newFileURL = documentsURL.appendingPathComponent("Untitled-\(timestamp).md")

        do {
            try "# New Document\n\n".write(to: newFileURL, atomically: true, encoding: .utf8)
            let window = NSApp.keyWindow
            FileOpenCoordinator.shared.openWindowHandler?(newFileURL)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                window?.close()
            }
        } catch {
            print("Failed to create new markdown file: \(error)")
        }
    }
    #endif
}
