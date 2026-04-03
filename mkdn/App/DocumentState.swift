#if os(macOS)
    import AppKit
    import SwiftUI
    import UniformTypeIdentifiers

    /// Per-window document state, observable across the view hierarchy.
    @MainActor
    @Observable
    public final class DocumentState {
        // MARK: - File State
        public var currentFileURL: URL?
        public var fileKind: FileKind = .markdown
        public var markdownContent = "" {
            didSet {
                if markdownContent != oldValue {
                    scheduleLint()
                }
            }
        }
        public private(set) var lastSavedContent = ""

        public var hasUnsavedChanges: Bool {
            markdownContent != lastSavedContent
        }

        public var isFileOutdated: Bool {
            fileWatcher.isOutdated
        }

        let fileWatcher = FileWatcher()
        public private(set) var loadGeneration: UInt64 = 0

        // MARK: - View Mode
        public var viewMode: ViewMode = .previewOnly

        // MARK: - Mode Overlay State
        public var modeOverlayLabel: String?

        // MARK: - Entrance Gate
        var isLoadingGateActive = false

        // MARK: - Color Palette State
        public var showColorPalettePopover = false

        // MARK: - Sidebar Layout State
        public var isSidebarVisible = false
        public var sidebarWidth: CGFloat = 240
        static let minSidebarWidth: CGFloat = 160
        static let maxSidebarWidth: CGFloat = 400

        // MARK: - Lint State
        public var lintIssues: [LintIssue] = []
        private let linter = MarkdownLinter()
        private var lintTask: Task<Void, Never>?

        public init() {}

        // MARK: - Methods

        public func loadFile(at url: URL) throws {
            loadGeneration &+= 1
            let content = try String(contentsOf: url, encoding: .utf8)
            if currentFileURL == url, markdownContent == content {
                return
            }
            currentFileURL = url
            fileKind = url.fileKind ?? .plainText
            markdownContent = content
            lastSavedContent = content
            fileWatcher.watch(url: url)
            NSDocumentController.shared.noteNewRecentDocumentURL(url)
            scheduleLint()
        }

        public func saveFile() throws {
            guard let url = currentFileURL else { return }
            fileWatcher.pauseForSave()
            defer { fileWatcher.resumeAfterSave() }
            try markdownContent.write(to: url, atomically: true, encoding: .utf8)
            lastSavedContent = markdownContent
        }

        public func reloadFile() throws {
            guard let url = currentFileURL else { return }
            try loadFile(at: url)
        }

        public func saveAs() {
            let panel = NSSavePanel()
            if let mdType = UTType(filenameExtension: "md") {
                panel.allowedContentTypes = [mdType]
            }
            panel.canCreateDirectories = true

            if let currentURL = currentFileURL {
                panel.directoryURL = currentURL.deletingLastPathComponent()
                panel.nameFieldStringValue = currentURL.lastPathComponent
            }

            guard panel.runModal() == .OK, let url = panel.url else { return }

            fileWatcher.pauseForSave()
            defer { fileWatcher.resumeAfterSave() }

            do {
                try markdownContent.write(to: url, atomically: true, encoding: .utf8)
                currentFileURL = url
                lastSavedContent = markdownContent
                fileWatcher.watch(url: url)
                NSDocumentController.shared.noteNewRecentDocumentURL(url)
            } catch {
                modeOverlayLabel = "Save failed"
            }
        }

        public func switchMode(to mode: ViewMode) {
            viewMode = mode
            modeOverlayLabel = mode == .previewOnly ? "Preview" : "Edit"
        }

        public func toggleSidebar() {
            isSidebarVisible.toggle()
        }

        public func scheduleLint() {
            lintTask?.cancel()
            lintTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }
                lintIssues = linter.lint(markdownContent)
            }
        }
    }
#endif
