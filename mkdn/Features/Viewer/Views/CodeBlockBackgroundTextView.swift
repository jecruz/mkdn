#if os(macOS)
    import AppKit
    import SwiftUI

    /// `NSTextView` subclass that draws rounded-rectangle background containers
    /// behind code block text ranges identified via ``CodeBlockAttributes``.
    final class CodeBlockBackgroundTextView: NSTextView {
        // MARK: - Document State
        weak var documentState: DocumentState?

        // MARK: - Constants
        static let cornerRadius: CGFloat = 6
        static let borderWidth: CGFloat = 1
        static let borderOpacity: CGFloat = 0.3
        static let bottomPadding: CGFloat = MarkdownTextStorageBuilder.codeBlockPadding
        static let copyButtonInset: CGFloat = 8
        static let copyButtonSize: CGFloat = 24

        // MARK: - Types
        struct CodeBlockInfo {
            let blockID: String
            let range: NSRange
            let colorInfo: CodeBlockColorInfo
        }

        struct CodeBlockGeometry {
            let blockID: String
            let rect: CGRect
            let range: NSRange
            let colorInfo: CodeBlockColorInfo
        }

        // MARK: - Code Block Cache
        var cachedCodeBlocks: [CodeBlockInfo] = []
        var isCodeBlockCacheValid = false

        // MARK: - Copy Button State
        var hoveredBlockID: String?
        var copyButtonOverlay: NSView?
        var cachedBlockRects: [CodeBlockGeometry] = []

        // MARK: - Find State
        weak var findState: FindState?

        // MARK: - Print Support
        var printBlocks: [IndexedBlock] = []

        // MARK: - Live Resize
        override func setFrameSize(_ newSize: NSSize) {
            super.setFrameSize(newSize)
            invalidateCodeBlockCache()
            needsDisplay = true
        }

        // MARK: - Text Change Invalidation
        override func didChangeText() {
            super.didChangeText()
            invalidateCodeBlockCache()
        }

        func invalidateCodeBlockCache() {
            isCodeBlockCacheValid = false
        }

        // MARK: - Escape to Dismiss Find
        override func cancelOperation(_ sender: Any?) {
            if let findState, findState.isVisible {
                findState.dismiss()
                return
            }
            super.cancelOperation(sender)
        }

        // MARK: - Mouse Tracking
        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            installFullBoundsTrackingArea()
        }

        override func mouseDown(with event: NSEvent) {
            let point = convert(event.locationInWindow, from: nil)
            if isOverEmptyTextArea(point) {
                handleEmptyAreaMouseDown(with: event)
                return
            }
            super.mouseDown(with: event)

            if let mouseLocation = window?.mouseLocationOutsideOfEventStream {
                let finalPoint = convert(mouseLocation, from: nil)
                if isOverEmptyTextArea(finalPoint) {
                    NSCursor.arrow.set()
                }
            }
        }

        override func mouseMoved(with event: NSEvent) {
            if isObscuredAtPoint(event.locationInWindow) { return }

            let point = convert(event.locationInWindow, from: nil)
            if isOverEmptyTextArea(point) {
                NSCursor.arrow.set()
            } else if isOverLink(at: point) {
                NSCursor.pointingHand.set()
            } else {
                NSCursor.iBeam.set()
            }
            updateCopyButtonForMouse(at: point)
        }

        override func cursorUpdate(with event: NSEvent) {
            if isObscuredAtPoint(event.locationInWindow) { return }

            let point = convert(event.locationInWindow, from: nil)
            if isOverEmptyTextArea(point) {
                NSCursor.arrow.set()
            } else if isOverLink(at: point) {
                NSCursor.pointingHand.set()
            } else {
                NSCursor.iBeam.set()
            }
        }

        private func isObscuredAtPoint(_ windowPoint: NSPoint) -> Bool {
            guard let hitView = window?.contentView?.hitTest(windowPoint) else { return false }
            return hitView !== self && !hitView.isDescendant(of: self)
        }

        override func mouseExited(with event: NSEvent) {
            super.mouseExited(with: event)
            hideCopyButton()
        }

        // MARK: - Drawing
        override func drawBackground(in rect: NSRect) {
            super.drawBackground(in: rect)
            drawCodeBlockContainers(in: rect)
        }

        // MARK: - Context Menu
        override func menu(for event: NSEvent) -> NSMenu? {
            let menu = super.menu(for: event) ?? NSMenu()

            menu.addItem(.separator())

            if let state = documentState {
                if state.viewMode == .sideBySide {
                    let previewItem = NSMenuItem(
                        title: "Preview Mode",
                        action: #selector(switchToPreviewMode),
                        keyEquivalent: ""
                    )
                    previewItem.target = self
                    menu.addItem(previewItem)
                } else {
                    let editItem = NSMenuItem(
                        title: "Edit Mode",
                        action: #selector(switchToEditMode),
                        keyEquivalent: ""
                    )
                    editItem.target = self
                    menu.addItem(editItem)
                }
            }

            menu.addItem(.separator())

            let closeItem = NSMenuItem(
                title: "Close Window",
                action: #selector(closeCurrentWindow),
                keyEquivalent: ""
            )
            closeItem.target = self
            menu.addItem(closeItem)

            return menu
        }

        @objc private func switchToPreviewMode() {
            documentState?.switchMode(to: .previewOnly)
        }

        @objc private func switchToEditMode() {
            documentState?.switchMode(to: .sideBySide)
        }

        @objc private func closeCurrentWindow() {
            window?.close()
        }

        // MARK: - Print
        override func printView(_ sender: Any?) {
            guard !printBlocks.isEmpty else {
                super.printView(sender)
                return
            }

            let savedString = textStorage.map { NSAttributedString(attributedString: $0) }
            let savedBgColor = backgroundColor
            let result = MarkdownTextStorageBuilder.build(
                blocks: printBlocks,
                colors: PrintPalette.colors,
                syntaxColors: PrintPalette.syntaxColors,
                isPrint: true
            )
            textStorage?.setAttributedString(result.attributedString)
            backgroundColor = PlatformTypeConverter.color(from: PrintPalette.colors.background)

            // swiftlint:disable:next force_cast
            let printInfo = NSPrintInfo.shared.copy() as! NSPrintInfo
            let printOp = NSPrintOperation(view: self, printInfo: printInfo)
            printOp.showsPrintPanel = true
            printOp.showsProgressPanel = true
            printOp.run()

            if let saved = savedString {
                textStorage?.setAttributedString(saved)
            }
            backgroundColor = savedBgColor
        }
    }
#endif
