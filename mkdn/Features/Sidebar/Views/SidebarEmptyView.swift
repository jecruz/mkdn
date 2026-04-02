#if os(macOS)
    import SwiftUI

    /// Displayed when the directory contains no recognized text files.
    struct SidebarEmptyView: View {
        @Environment(AppSettings.self) private var appSettings

        var body: some View {
            VStack(spacing: 8) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.title2)
                    .foregroundStyle(appSettings.effectiveColors.foregroundSecondary)
                Text("No text files found")
                    .font(.callout)
                    .foregroundStyle(appSettings.effectiveColors.foregroundSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
#endif
