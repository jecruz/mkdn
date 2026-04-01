import SwiftUI
import UniformTypeIdentifiers
import Combine

/// Application menu commands.
///
/// Uses `AppSettings` for theme operations and `@FocusedValue` to access
/// the active window's `DocumentState` for document operations.
public struct MkdnCommands: Commands {
    public let appSettings: AppSettings
    @FocusedValue(\.documentState) private var documentState

    public init(appSettings: AppSettings) {
        self.appSettings = appSettings
    }

    public var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("About mkdn") {
                NSApp.orderFrontStandardAboutPanel(options: [
                    .applicationIcon: NSApp.applicationIconImage as Any,
                ])
            }
        }

        CommandGroup(after: .appInfo) {
            Button("Set as Default Markdown App") {
                let success = DefaultHandlerService.registerAsDefault()
                if success {
                    documentState?.modeOverlayLabel = "Default Markdown App Set"
                }
            }
        }

        CommandGroup(replacing: .saveItem) {
            Button("Save") {
                try? documentState?.saveFile()
            }
            .keyboardShortcut("s", modifiers: .command)
            .disabled(documentState?.currentFileURL == nil || documentState?.hasUnsavedChanges != true)

            Button("Save As...") {
                documentState?.saveAs()
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])
            .disabled(documentState == nil)
        }

        CommandGroup(after: .pasteboard) {
            // NSFindPanelAction tags: showFindPanel=1, next=2, previous=3, setFindString=7
            Button("Find...") {
                sendFindAction(tag: 1)
            }
            .keyboardShortcut("f", modifiers: .command)

            Button("Find Next") {
                sendFindAction(tag: 2)
            }
            .keyboardShortcut("g", modifiers: .command)

            Button("Find Previous") {
                sendFindAction(tag: 3)
            }
            .keyboardShortcut("g", modifiers: [.command, .shift])

            Button("Use Selection for Find") {
                sendFindAction(tag: 7)
            }
            .keyboardShortcut("e", modifiers: .command)
        }

        CommandGroup(replacing: .printItem) {
            Button("Page Setup...") {
                NSApp.sendAction(
                    #selector(NSDocument.runPageLayout(_:)),
                    to: nil,
                    from: nil
                )
            }
            .keyboardShortcut("P", modifiers: [.command, .shift])

            Button("Print...") {
                NSApp.sendAction(
                    #selector(NSView.printView(_:)),
                    to: nil,
                    from: nil
                )
            }
            .keyboardShortcut("p", modifiers: .command)
        }

        CommandGroup(replacing: .newItem) {
            Button("New Markdown") {
                createNewMarkdownFile()
            }
            .keyboardShortcut("n", modifiers: .command)

            Button("Close Window") {
                NSApplication.shared.keyWindow?.close()
            }
            .keyboardShortcut("w", modifiers: .command)
            .disabled(NSApplication.shared.keyWindow == nil)

            Divider()

            Menu("Open Recent") {
                ForEach(
                    NSDocumentController.shared.recentDocumentURLs,
                    id: \.self
                ) { url in
                    Button(url.lastPathComponent) {
                        FileOpenCoordinator.shared.pendingURLs.append(url)
                    }
                }
                Divider()
                Button("Clear Menu") {
                    NSDocumentController.shared.clearRecentDocuments(nil)
                }
            }

            Divider()

            Button("Open...") {
                openFile()
            }
            .keyboardShortcut("o", modifiers: .command)

            Button("Reload") {
                try? documentState?.reloadFile()
            }
            .keyboardShortcut("r", modifiers: .command)
            .disabled(documentState?.currentFileURL == nil || documentState?.isFileOutdated != true)
        }

        CommandGroup(after: .toolbar) {
            Section {
                Button("Zoom In") {
                    appSettings.zoomIn()
                    documentState?.modeOverlayLabel = appSettings.zoomLabel
                }
                .keyboardShortcut("+", modifiers: .command)

                Button("Zoom Out") {
                    appSettings.zoomOut()
                    documentState?.modeOverlayLabel = appSettings.zoomLabel
                }
                .keyboardShortcut("-", modifiers: .command)

                Button("Actual Size") {
                    appSettings.zoomReset()
                    documentState?.modeOverlayLabel = appSettings.zoomLabel
                }
                .keyboardShortcut("0", modifiers: .command)
            }
        }

        CommandGroup(after: .sidebar) {
            Section {
                Button("Preview Mode") {
                    documentState?.switchMode(to: .previewOnly)
                }
                .keyboardShortcut("1", modifiers: .command)

                Button("Edit Mode") {
                    documentState?.switchMode(to: .sideBySide)
                }
                .keyboardShortcut("2", modifiers: .command)
            }

            Section {
                Button("Cycle Theme") {
                    let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
                    let themeAnimation = reduceMotion
                        ? AnimationConstants.reducedCrossfade
                        : AnimationConstants.crossfade
                    withAnimation(themeAnimation) {
                        appSettings.cycleTheme()
                    }
                    documentState?.modeOverlayLabel = appSettings.themeMode.displayName
                }
                .keyboardShortcut("t", modifiers: .command)
            }
        }
    }

    @MainActor
    private func sendFindAction(tag: Int) {
        let menuItem = NSMenuItem()
        menuItem.tag = tag
        NSApp.sendAction(
            #selector(NSTextView.performFindPanelAction(_:)),
            to: nil,
            from: menuItem
        )
    }

    @MainActor
    private func openFile() {
        let panel = NSOpenPanel()
        if let mdType = UTType(filenameExtension: "md") {
            panel.allowedContentTypes = [mdType]
        }
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? documentState?.loadFile(at: url)
    }

    @MainActor
    private func createNewMarkdownFile() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let newFileURL = documentsURL.appendingPathComponent("Untitled-\(timestamp).md")

        do {
            try "# New Document\n\n".write(to: newFileURL, atomically: true, encoding: .utf8)
            if documentState?.currentFileURL == nil {
                // Welcome screen or no windows: close splash, open new document
                let window = NSApplication.shared.keyWindow
                FileOpenCoordinator.shared.openWindowHandler?(newFileURL)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    window?.close()
                }
            } else {
                // File already open: open in new window
                FileOpenCoordinator.shared.pendingURLs.append(newFileURL)
            }
        } catch {
            print("Failed to create new markdown file: \(error)")
        }
    }
}
