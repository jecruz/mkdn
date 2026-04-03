import SwiftUI

/// Sidebar sections for the Help window.
enum HelpSection: String, CaseIterable, Identifiable {
    case shortcuts = "Shortcuts"
    case features = "Features"
    case cliUsage = "CLI Usage"
    case about = "About"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .shortcuts: "keyboard"
        case .features: "sparkles"
        case .cliUsage: "terminal"
        case .about: "info.circle"
        }
    }
}
