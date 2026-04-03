#if os(macOS)
    import AppKit
    import SwiftUI

    extension Notification.Name {
        public static let createNewMarkdownFile = Notification.Name("createNewMarkdownFile")
    }

    /// Welcome screen shown when no file is open.
    struct WelcomeView: View {
        @Environment(AppSettings.self) private var appSettings
        @Environment(\.isDirectoryMode) private var isDirectoryMode
        @State private var hostWindow: NSWindow?

        var body: some View {
            VStack(spacing: 20) {
                Image(systemName: isDirectoryMode ? "sidebar.left" : "doc.richtext")
                    .font(.system(size: 64))
                    .foregroundColor(appSettings.effectiveColors.foregroundSecondary)

                Text("mkdn")
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(appSettings.effectiveColors.headingColor)

                Text(
                    isDirectoryMode
                        ? "Select a file from the sidebar to begin reading"
                        : "Open a Markdown file to get started"
                )
                .font(.body)
                .foregroundColor(appSettings.effectiveColors.foregroundSecondary)

                if !isDirectoryMode {
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
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(appSettings.effectiveColors.background)
            .background(WindowAccessor { window in hostWindow = window })
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
        }

        private func instructionRow(icon: String, text: String) -> some View {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .frame(width: 20)
                    .foregroundColor(appSettings.effectiveColors.accent)
                Text(text)
                    .font(.callout)
                    .foregroundColor(appSettings.effectiveColors.foreground)
            }
        }

        private func closeWindow() {
            if let window = hostWindow ?? NSApp.keyWindow {
                window.close()
            }
        }

        private func createNewMarkdownFile() {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
            let newFileURL = documentsURL.appendingPathComponent("Untitled-\(timestamp).md")

            do {
                try "# New Document\n\n".write(to: newFileURL, atomically: true, encoding: .utf8)
                let window = hostWindow ?? NSApp.keyWindow
                FileOpenService.shared.openFileWindow?(newFileURL)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    window?.close()
                }
            } catch {
                print("Failed to create new markdown file: \(error)")
            }
        }
    }
#endif
