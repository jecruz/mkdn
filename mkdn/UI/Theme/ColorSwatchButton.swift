import SwiftUI

// MARK: - SwatchStyle

/// Visual shape style for color swatches.
enum SwatchStyle {
    case circle
    case square
}

// MARK: - ColorSwatchButton

/// A tappable color swatch button with selection state and hover feedback.
///
/// Displays a color swatch in either circular or square form, with selection
/// indicated by a white stroke overlay and subtle scale animation.
///
/// - Parameters:
///   - hex: The hex color string (supports #RGB, #RRGGBB, #AARRGGBB).
///   - style: The swatch shape style (circle or square).
///   - isSelected: Whether the swatch is currently selected.
///   - action: Closure invoked when the swatch is tapped.
struct ColorSwatchButton: View {
    let hex: String
    let style: SwatchStyle
    let isSelected: Bool
    let size: CGFloat
    let action: () -> Void

    init(hex: String, style: SwatchStyle, isSelected: Bool, size: CGFloat = 32, action: @escaping () -> Void) {
        self.hex = hex
        self.style = style
        self.isSelected = isSelected
        self.size = size
        self.action = action
    }

    private let selectedScale: CGFloat = 1.1
    private let borderWidth: CGFloat = 1
    private let selectedStrokeWidth: CGFloat = 3

    var body: some View {
        Button(action: action) {
            swatchContent
        }
        .buttonStyle(.plain)
        .help(hex)
        .scaleEffect(isSelected ? selectedScale : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    @ViewBuilder
    private var swatchContent: some View {
        switch style {
        case .circle:
            circleSwatch
        case .square:
            squareSwatch
        }
    }

    private var circleSwatch: some View {
        Circle()
            .fill(Color(hex: hex))
            .overlay {
                Circle()
                    .stroke(.black, lineWidth: borderWidth)
            }
            .overlay {
                if isSelected {
                    Circle()
                        .stroke(.white, lineWidth: selectedStrokeWidth)
                }
            }
            .frame(width: size, height: size)
    }

    private var squareSwatch: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color(hex: hex))
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(.black, lineWidth: borderWidth)
            }
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(.white, lineWidth: selectedStrokeWidth)
                }
            }
            .frame(width: size, height: size)
    }
}

// MARK: - Previews

struct ColorSwatchButtonCircleStyle_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 16) {
            ColorSwatchButton(hex: "#ffffff", style: .circle, isSelected: false, action: {})
            ColorSwatchButton(hex: "#268bd2", style: .circle, isSelected: true, action: {})
            ColorSwatchButton(hex: "#002b36", style: .circle, isSelected: false, action: {})
            ColorSwatchButton(hex: "#f92672", style: .circle, isSelected: true, action: {})
        }
        .padding()
    }
}

struct ColorSwatchButtonSquareStyle_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 16) {
            ColorSwatchButton(hex: "#ffffff", style: .square, isSelected: false, action: {})
            ColorSwatchButton(hex: "#268bd2", style: .square, isSelected: true, action: {})
            ColorSwatchButton(hex: "#002b36", style: .square, isSelected: false, action: {})
            ColorSwatchButton(hex: "#f92672", style: .square, isSelected: true, action: {})
        }
        .padding()
    }
}
