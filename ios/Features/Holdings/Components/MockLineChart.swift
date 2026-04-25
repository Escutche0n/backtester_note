import SwiftUI

struct MockLineChart: View {
    let series: [ChartPoint]
    let benchmark: [ChartPoint]
    let color: Color
    var showFill = true

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let bounds = ChartBounds(primary: series, secondary: benchmark)
            let linePath = chartPath(points: series, bounds: bounds, size: size)
            let benchmarkPath = chartPath(points: benchmark, bounds: bounds, size: size)

            ZStack {
                grid(size: size)

                if bounds.crossesZero {
                    zeroLine(bounds: bounds, size: size)
                }

                benchmarkPath
                    .stroke(BNTokens.Colors.benchmark.opacity(0.75), style: StrokeStyle(lineWidth: 1.2, dash: [3, 4]))

                if showFill {
                    fillPath(linePath: linePath, points: series, bounds: bounds, size: size)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.22), color.opacity(0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                linePath
                    .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            }
        }
    }

    private func grid(size: CGSize) -> some View {
        Path { path in
            for fraction in [0.25, 0.5, 0.75] {
                let y = size.height * fraction
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
        }
        .stroke(BNTokens.Colors.hairline, style: StrokeStyle(lineWidth: 0.5, dash: [2, 4]))
    }

    private func zeroLine(bounds: ChartBounds, size: CGSize) -> some View {
        Path { path in
            let y = yPosition(for: 0, bounds: bounds, height: size.height)
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
        }
        .stroke(Color.white.opacity(0.18), style: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
    }

    private func chartPath(points: [ChartPoint], bounds: ChartBounds, size: CGSize) -> Path {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: point(for: first, count: points.count, bounds: bounds, size: size))
            for item in points.dropFirst() {
                path.addLine(to: point(for: item, count: points.count, bounds: bounds, size: size))
            }
        }
    }

    private func fillPath(linePath: Path, points: [ChartPoint], bounds: ChartBounds, size: CGSize) -> Path {
        var path = linePath
        guard let first = points.first, let last = points.last else { return path }
        let firstPoint = point(for: first, count: points.count, bounds: bounds, size: size)
        let lastPoint = point(for: last, count: points.count, bounds: bounds, size: size)
        path.addLine(to: CGPoint(x: lastPoint.x, y: size.height))
        path.addLine(to: CGPoint(x: firstPoint.x, y: size.height))
        path.closeSubpath()
        return path
    }

    private func point(for item: ChartPoint, count: Int, bounds: ChartBounds, size: CGSize) -> CGPoint {
        let denominator = max(count - 1, 1)
        let x = CGFloat(item.index) / CGFloat(denominator) * size.width
        let y = yPosition(for: item.value, bounds: bounds, height: size.height)
        return CGPoint(x: x, y: y)
    }

    private func yPosition(for value: Double, bounds: ChartBounds, height: CGFloat) -> CGFloat {
        let range = bounds.maxValue - bounds.minValue
        let normalized = (value - bounds.minValue) / (range == 0 ? 1 : range)
        return CGFloat(1 - normalized) * height
    }
}

private struct ChartBounds {
    let minValue: Double
    let maxValue: Double

    init(primary: [ChartPoint], secondary: [ChartPoint]) {
        let values = (primary + secondary).map(\.value)
        minValue = values.min() ?? 0
        maxValue = values.max() ?? 1
    }

    var crossesZero: Bool {
        minValue < 0 && maxValue > 0
    }
}
