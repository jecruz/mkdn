import AppKit
import SwiftUI

@MainActor
public enum AuxiliaryWindowManager {
    private static var helpWindow: NSWindow?
    private static var markdownGuideWindow: NSWindow?

    public static func showHelp(appSettings: AppSettings) {
        if let window = helpWindow {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let view = HelpWindowView().environment(appSettings)
        let controller = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: controller)
        window.title = "mkdn Help"
        window.styleMask = [.titled, .closable, .resizable, .miniaturizable]
        window.setContentSize(NSSize(width: 600, height: 450))
        window.isExcludedFromWindowsMenu = true
        window.center()
        window.isReleasedWhenClosed = false

        helpWindow = window
        window.makeKeyAndOrderFront(nil)
    }

    public static func showMarkdownGuide(appSettings: AppSettings) {
        if let window = markdownGuideWindow {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let view = MarkdownGuideView().environment(appSettings)
        let controller = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: controller)
        window.title = "Markdown Guide"
        window.styleMask = [.titled, .closable, .resizable, .miniaturizable, .fullSizeContentView]
        window.setContentSize(NSSize(width: 650, height: 500))
        window.isExcludedFromWindowsMenu = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.center()
        window.isReleasedWhenClosed = false

        markdownGuideWindow = window
        window.makeKeyAndOrderFront(nil)
    }
}
