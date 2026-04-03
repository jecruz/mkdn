import AppKit
import SwiftUI

/// Provides access to the hosting `NSWindow` for a SwiftUI view.
///
/// Embed in a view's background to receive a callback with the window
/// reference once the view is attached to a window. The callback fires
/// once on first attachment.
struct WindowAccessor: NSViewRepresentable {
    let onWindow: (NSWindow?) -> Void

    func makeNSView(context: Context) -> _WindowAccessorView {
        _WindowAccessorView(onWindow: onWindow)
    }

    func updateNSView(_ nsView: _WindowAccessorView, context: Context) {}
}

final class _WindowAccessorView: NSView {
    let onWindow: (NSWindow?) -> Void
    private var didFire = false

    init(onWindow: @escaping (NSWindow?) -> Void) {
        self.onWindow = onWindow
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard !didFire else { return }
        didFire = true
        onWindow(window)
    }
}
