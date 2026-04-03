#if os(macOS)
    import SwiftUI
    import UniformTypeIdentifiers
    import Combine

    extension Notification.Name {
        static let openHelpWindow = Notification.Name("openHelpWindow")
        static let openMarkdownGuide = Notification.Name("openMarkdownGuide")
    }

    /// Application menu commands.
    ///
    /// Uses `AppSettings` for theme operations and `@FocusedValue` to access
    /// the active window's `DocumentState` for document operations.
    public struct MkdnCommands: Commands {
        public let appSettings: AppSettings
        @FocusedValue(\.documentState) private var documentState
        @FocusedValue(\.findState) private var findState
        @FocusedValue(\.outlineState) private var outlineState
        @FocusedValue(\.directorySetup) private var directorySetup

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
                            FileOpenService.shared.openFileWindow?(url)
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
                
                Button("Open Directory...") {
                    openDirectory()
                }
                .keyboardShortcut("O", modifiers: [.command, .shift])

                Button("Reload") {
                    try? documentState?.reloadFile()
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(documentState?.currentFileURL == nil || documentState?.isFileOutdated != true)
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
                Button("Find...") {
                    withAnimation(motionAnimation(.springSettle)) {
                        findState?.show()
                    }
                }
                .keyboardShortcut("f", modifiers: .command)

                Button("Find Next") {
                    findState?.nextMatch()
                }
                .keyboardShortcut("g", modifiers: .command)

                Button("Find Previous") {
                    findState?.previousMatch()
                }
                .keyboardShortcut("g", modifiers: [.command, .shift])

                Button("Use Selection for Find") {
                    guard let textView = Self.findTextView() else { return }
                    let range = textView.selectedRange()
                    guard range.length > 0,
                          let swiftRange = Range(range, in: textView.string)
                    else { return }
                    let selectedText = String(textView.string[swiftRange])
                    withAnimation(motionAnimation(.springSettle)) {
                        findState?.useSelection(selectedText)
                    }
                }
                .keyboardShortcut("e", modifiers: .command)
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
                    Button("Toggle Sidebar") {
                        withAnimation(motionAnimation(.sidebarSlide)) {
                            documentState?.toggleSidebar()
                        }
                    }
                    .keyboardShortcut("l", modifiers: [.command, .shift])
                }

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
                        appSettings.cycleTheme()
                        documentState?.modeOverlayLabel = appSettings.themeMode.displayName
                    }
                    .keyboardShortcut("t", modifiers: [.command, .shift])

                    Button("Color Palette\u{2026}") {
                        documentState?.showColorPalettePopover = true
                    }
                    .keyboardShortcut("k", modifiers: [.command, .shift])
                }

                Section {
                    Button("Document Outline") {
                        NotificationCenter.default.post(name: .outlineToggle, object: outlineState)
                    }
                    .keyboardShortcut("j", modifiers: .command)
                    .disabled(outlineState?.headingTree.isEmpty ?? true)
                }
            }

            CommandGroup(replacing: .help) {
                Button("mkdn Help") {
                    NotificationCenter.default.post(name: .openHelpWindow, object: nil)
                }
                .keyboardShortcut("?", modifiers: .command)

                Divider()

                Button("Markdown Guide") {
                    NotificationCenter.default.post(name: .openMarkdownGuide, object: nil)
                }
                .keyboardShortcut("m", modifiers: [.command, .shift])
            }
        }

        @MainActor
        static func findTextView() -> CodeBlockBackgroundTextView? {
            guard let contentView = NSApp.keyWindow?.contentView else { return nil }
            return findTextView(in: contentView)
        }

        private static func findTextView(in view: NSView) -> CodeBlockBackgroundTextView? {
            if let textView = view as? CodeBlockBackgroundTextView {
                return textView
            }
            for subview in view.subviews {
                if let found = findTextView(in: subview) {
                    return found
                }
            }
            return nil
        }

        private func motionAnimation(_ primitive: MotionPreference.Primitive) -> Animation? {
            let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
            return MotionPreference(reduceMotion: reduceMotion).resolved(primitive)
        }

        @MainActor
        private func openDirectory() {
            let panel = NSOpenPanel()
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.allowsMultipleSelection = false

            if let fileURL = documentState?.currentFileURL {
                panel.directoryURL = fileURL.deletingLastPathComponent()
            }

            guard panel.runModal() == .OK, let url = panel.url else { return }
            directorySetup?(url)
        }

        @MainActor
        private func openFile() {
            let panel = NSOpenPanel()
            let extensions = [
                "md", "markdown",
                "swift", "py", "js", "ts", "rs", "go",
                "c", "cpp", "h", "hpp",
                "java", "rb", "json", "yaml", "yml",
                "html", "css", "sh", "kt",
                "toml", "xml", "sql", "r", "lua", "zig",
                "txt",
            ]
            var types: [UTType] = []
            for ext in extensions {
                if let utType = UTType(filenameExtension: ext), !types.contains(utType) {
                    types.append(utType)
                }
            }
            if !types.isEmpty { panel.allowedContentTypes = types }
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
                    FileOpenService.shared.openFileWindow?(newFileURL)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        window?.close()
                    }
                } else {
                    // File already open: open in new window
                    FileOpenService.shared.openFileWindow?(newFileURL)
                }
            } catch {
                print("Failed to create new markdown file: \(error)")
            }
        }
    }
#endif
