#if os(macOS)
    import AppKit
    import SwiftUI

    /// Transparent NSView helper that configures the hosting NSWindow.
    public struct WindowAccessor: NSViewRepresentable {
        public var onWindowAvailable: ((NSWindow?) -> Void)?

        public init(onWindowAvailable: ((NSWindow?) -> Void)? = nil) {
            self.onWindowAvailable = onWindowAvailable
        }

        public func makeNSView(context _: Context) -> WindowAccessorView {
            let view = WindowAccessorView()
            view.onWindowAvailable = onWindowAvailable
            return view
        }

        public func updateNSView(_ nsView: WindowAccessorView, context _: Context) {
            nsView.onWindowAvailable = onWindowAvailable
        }
    }

    /// Custom NSView that configures its hosting window when attached.
    public final class WindowAccessorView: NSView {
        private var didConfigure = false
        var onWindowAvailable: ((NSWindow?) -> Void)?

        override public func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window, !didConfigure else { return }
            didConfigure = true
            onWindowAvailable?(window)

            DispatchQueue.main.async { [weak window] in
                guard let window else { return }
                self.configureWindow(window)
            }
        }

        private func configureWindow(_ window: NSWindow) {
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.styleMask.insert(.fullSizeContentView)
            window.isMovableByWindowBackground = true
            window.hasShadow = true

            // Apply saved window size
            let savedWidth = UserDefaults.standard.double(forKey: "windowWidth")
            let savedHeight = UserDefaults.standard.double(forKey: "windowHeight")
            if savedWidth > 0, savedHeight > 0 {
                var frame = window.frame
                frame.size = NSSize(width: savedWidth, height: savedHeight)
                window.setFrame(frame, display: true)
            }

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(windowDidResize(_:)),
                name: NSWindow.didResizeNotification,
                object: window
            )

            guard !TestHarnessMode.isEnabled else { return }
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)
        }

        @objc private func windowDidResize(_ notification: Notification) {
            guard let window = notification.object as? NSWindow else { return }
            let size = window.frame.size
            UserDefaults.standard.set(Double(size.width), forKey: "windowWidth")
            UserDefaults.standard.set(Double(size.height), forKey: "windowHeight")
        }
    }
#endif
