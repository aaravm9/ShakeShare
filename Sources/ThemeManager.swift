import SwiftUI

public struct ThemeStyle {
    public var accentColor: Color
    public var textColor: Color
    public var secondaryTextColor: Color
    public var ringBackgroundColor: Color
    public var segmentHoverColor: Color
    public var segmentBorderColor: Color
    public var ringShadowRadius: CGFloat
    public var ringShadowColor: Color
}

public class ThemeManager {
    public static func style(for type: ThemeType) -> ThemeStyle {
        switch type {
        case .light:
            return ThemeStyle(
                accentColor: Color.blue,
                textColor: Color.primary,
                secondaryTextColor: Color.secondary,
                ringBackgroundColor: Color(white: 0.95),
                segmentHoverColor: Color(white: 0.88),
                segmentBorderColor: Color(white: 0.8),
                ringShadowRadius: 8,
                ringShadowColor: Color.black.opacity(0.1)
            )
        case .dark:
            return ThemeStyle(
                accentColor: Color.orange,
                textColor: Color.white,
                secondaryTextColor: Color.gray,
                ringBackgroundColor: Color(white: 0.12),
                segmentHoverColor: Color(white: 0.22),
                segmentBorderColor: Color(white: 0.25),
                ringShadowRadius: 12,
                ringShadowColor: Color.black.opacity(0.4)
            )
        case .glass:
            return ThemeStyle(
                accentColor: Color.purple,
                textColor: Color.primary,
                secondaryTextColor: Color.secondary,
                ringBackgroundColor: Color.clear,
                segmentHoverColor: Color.purple.opacity(0.15),
                segmentBorderColor: Color.white.opacity(0.3),
                ringShadowRadius: 15,
                ringShadowColor: Color.black.opacity(0.2)
            )
        case .matte:
            return ThemeStyle(
                accentColor: Color.mint,
                textColor: Color.primary,
                secondaryTextColor: Color.secondary,
                ringBackgroundColor: Color(white: 0.9),
                segmentHoverColor: Color.mint.opacity(0.1),
                segmentBorderColor: Color.clear,
                ringShadowRadius: 0,
                ringShadowColor: Color.clear
            )
        }
    }
}

struct ThemeBackgroundModifier: ViewModifier {
    var type: ThemeType
    
    func body(content: Content) -> some View {
        switch type {
        case .light:
            return AnyView(
                content
                    .background(Circle().fill(Color(white: 0.98)))
                    .overlay(Circle().stroke(Color(white: 0.85), lineWidth: 1))
            )
        case .dark:
            return AnyView(
                content
                    .background(Circle().fill(Color(white: 0.08)))
                    .overlay(Circle().stroke(Color(white: 0.2), lineWidth: 1))
            )
        case .glass:
            return AnyView(
                content
                    .background(Circle().fill(.ultraThinMaterial))
                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1.5))
            )
        case .matte:
            return AnyView(
                content
                    .background(Circle().fill(Color(white: 0.96)))
                    .overlay(Circle().stroke(Color(white: 0.8), lineWidth: 1))
            )
        }
    }
}

extension View {
    public func themeBackground(for type: ThemeType) -> some View {
        self.modifier(ThemeBackgroundModifier(type: type))
    }
}
