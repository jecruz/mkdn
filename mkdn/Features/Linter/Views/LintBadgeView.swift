import SwiftUI

/// Warning badge showing lint issue count. Hidden when count is 0.
struct LintBadgeView: View {
    let count: Int
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        if count > 0 {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
                Text("\(count)")
                    .font(.system(.caption2, design: .monospaced).bold())
            }
            .foregroundColor(.yellow)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.yellow.opacity(0.15))
            )
        }
    }
}
