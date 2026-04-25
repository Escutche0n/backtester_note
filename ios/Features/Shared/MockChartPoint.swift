import Foundation

struct ChartPoint: Identifiable, Sendable {
    let id = UUID()
    let index: Int
    let value: Double
}
