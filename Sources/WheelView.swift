import SwiftUI

struct Wedge: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var innerRadiusRatio: CGFloat = 0.35

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let innerRadius = radius * innerRadiusRatio

        var path = Path()
        path.addArc(center: center, radius: radius,
                    startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.addArc(center: center, radius: innerRadius,
                    startAngle: endAngle, endAngle: startAngle, clockwise: true)
        path.closeSubpath()
        return path
    }
}

public struct WheelView: View {
    @EnvironmentObject var viewModel: OverlayViewModel
    @EnvironmentObject var preferences: Preferences

    @State private var scale: CGFloat = 0.6
    @State private var opacity: Double = 0.0

    public init() {}

    public var body: some View {
        let themeStyle = ThemeManager.style(for: preferences.theme)
        let destinations = preferences.destinations

        ZStack {
            // Dimmed backdrop
            Color.black.opacity(preferences.theme == .dark ? 0.45 : 0.25)
                .edgesIgnoringSafeArea(.all)

            // Wheel
            ZStack {
                // 8 segments
                ForEach(0..<8, id: \.self) { index in
                    let startDeg = Double(index) * 45.0 - 21.5
                    let endDeg   = Double(index) * 45.0 + 21.5
                    let isSelected = viewModel.selectedIndex == index
                    let dest = destinations[index]
                    let angleRad = Double(index) * 45.0 * .pi / 180.0
                    let midRadius: CGFloat = 135

                    // Wedge slice
                    Wedge(startAngle: .degrees(startDeg),
                          endAngle:   .degrees(endDeg),
                          innerRadiusRatio: 0.32)
                        .fill(isSelected
                              ? themeStyle.accentColor.opacity(0.92)
                              : themeStyle.ringBackgroundColor.opacity(0.82))
                        .overlay(
                            Wedge(startAngle: .degrees(startDeg),
                                  endAngle:   .degrees(endDeg),
                                  innerRadiusRatio: 0.32)
                                .stroke(isSelected
                                        ? themeStyle.accentColor
                                        : themeStyle.segmentBorderColor,
                                        lineWidth: 1.5)
                        )
                        .scaleEffect(isSelected ? 1.07 : 1.0)
                        .shadow(color: isSelected ? themeStyle.accentColor.opacity(0.45) : .clear,
                                radius: 12)
                        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isSelected)

                    // Icon + label
                    VStack(spacing: 5) {
                        Image(systemName: dest.iconName)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(isSelected ? .white : themeStyle.textColor)

                        Text(dest.name)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(isSelected ? .white : themeStyle.textColor)
                            .frame(maxWidth: 75)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .offset(x: cos(angleRad) * midRadius,
                            y: sin(angleRad) * midRadius)
                    .scaleEffect(isSelected ? 1.12 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isSelected)
                }

                // Center hub
                Circle()
                    .fill(themeStyle.ringBackgroundColor.opacity(0.95))
                    .frame(width: 124, height: 124)
                    .overlay(Circle().stroke(themeStyle.segmentBorderColor, lineWidth: 2))
                    .shadow(color: themeStyle.ringShadowColor, radius: themeStyle.ringShadowRadius)

                // Center content
                VStack(spacing: 4) {
                    Image(systemName: viewModel.draggedFilesCount > 1 ? "doc.on.doc.fill" : "doc.fill")
                        .font(.system(size: 26))
                        .foregroundColor(themeStyle.accentColor)

                    Text("\(viewModel.draggedFilesCount)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(themeStyle.textColor)

                    Text(viewModel.draggedFilesCount > 1 ? "Files" : "File")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(themeStyle.secondaryTextColor)
                        .textCase(.uppercase)
                }

                // Instruction hint
                if viewModel.selectedIndex == nil {
                    VStack {
                        Spacer()
                        Text("Move cursor to a segment, then release mouse")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 7)
                            .background(Color.black.opacity(0.45))
                            .cornerRadius(20)
                            .padding(.bottom, 60)
                    }
                }
            }
            .frame(width: 420, height: 420)
            .themeBackground(for: preferences.theme)
            .scaleEffect(scale)
            .opacity(opacity)
            .shadow(color: themeStyle.ringShadowColor, radius: themeStyle.ringShadowRadius + 4)
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                scale   = 1.0
                opacity = 1.0
            }
        }
    }
}
