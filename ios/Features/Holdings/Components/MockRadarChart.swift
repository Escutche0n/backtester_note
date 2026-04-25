import SwiftUI

struct MockRadarChart: View {
    let dimensions: [String]
    let snapshots: [RadarSnapshot]

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let radius = size / 2 - 34

            ZStack {
                grid(center: center, radius: radius)
                spokes(center: center, radius: radius)

                ForEach(Array(snapshots.enumerated()), id: \.element.key) { index, snapshot in
                    let color = radarColor(index: index)
                    polygon(snapshot.values, center: center, radius: radius)
                        .fill(color.opacity(index == snapshots.count - 1 ? 0.18 : 0.06))
                        .overlay {
                            polygon(snapshot.values, center: center, radius: radius)
                                .stroke(color.opacity(index == snapshots.count - 1 ? 1 : 0.55), lineWidth: index == snapshots.count - 1 ? 1.5 : 1)
                        }
                }

                labels(center: center, radius: radius + 20)
            }
        }
    }

    private func grid(center: CGPoint, radius: CGFloat) -> some View {
        ZStack {
            ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { scale in
                polygon(Array(repeating: scale * 100, count: dimensions.count), center: center, radius: radius)
                    .stroke(Color.white.opacity(0.07), lineWidth: 0.5)
            }
        }
    }

    private func spokes(center: CGPoint, radius: CGFloat) -> some View {
        Path { path in
            for index in dimensions.indices {
                path.move(to: center)
                path.addLine(to: point(index: index, value: 100, center: center, radius: radius))
            }
        }
        .stroke(Color.white.opacity(0.05), lineWidth: 0.5)
    }

    private func labels(center: CGPoint, radius: CGFloat) -> some View {
        ZStack {
            ForEach(Array(dimensions.enumerated()), id: \.offset) { index, label in
                let location = point(index: index, value: 100, center: center, radius: radius)
                Text(label)
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundStyle(BNTokens.Colors.foregroundSecondary)
                    .position(location)
            }
        }
    }

    private func polygon(_ values: [Double], center: CGPoint, radius: CGFloat) -> Path {
        Path { path in
            guard !values.isEmpty else { return }
            path.move(to: point(index: 0, value: values[0], center: center, radius: radius))
            for index in values.indices.dropFirst() {
                path.addLine(to: point(index: index, value: values[index], center: center, radius: radius))
            }
            path.closeSubpath()
        }
    }

    private func point(index: Int, value: Double, center: CGPoint, radius: CGFloat) -> CGPoint {
        let angle = Double.pi * 2 * Double(index) / Double(max(dimensions.count, 1)) - Double.pi / 2
        let scaledRadius = CGFloat(value / 100) * radius
        return CGPoint(
            x: center.x + cos(angle) * scaledRadius,
            y: center.y + sin(angle) * scaledRadius
        )
    }

    private func radarColor(index: Int) -> Color {
        switch index {
        case 0:
            return BNTokens.Colors.accent.opacity(0.7)
        case 1:
            return BNTokens.Colors.benchmark
        default:
            return BNTokens.Colors.foregroundPrimary
        }
    }
}
