#if os(macOS)
    import SwiftUI

    private struct IsDirectoryModeKey: EnvironmentKey {
        static let defaultValue: Bool = false
    }

    public extension EnvironmentValues {
        var isDirectoryMode: Bool {
            get { self[IsDirectoryModeKey.self] }
            set { self[IsDirectoryModeKey.self] = newValue }
        }
    }
#endif
