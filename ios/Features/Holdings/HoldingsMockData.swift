import Foundation

struct HoldingsOverview: Sendable {
    let totalValue: Double
    let unitNAV: Double
    let dayPnl: Double
    let dayPct: Double
    let dayDrawdown: Double
    let holdPnl: Double
    let holdPct: Double
    let xirr: Double
    let excess: Double
    let maxDrawdown6M: Double
    let sharpe: Double
    let calmar: Double
    let unbalance: Double
}

struct HoldingFund: Identifiable, Sendable {
    let id: String
    let code: String
    let name: String
    let type: String
    let targetWeight: Double
    let value: Double
    let cost: Double
    let shares: Double
    let dayPct: Double
    let holdPct: Double
    let sparkline: [ChartPoint]
}

struct ChartPoint: Identifiable, Sendable {
    let id = UUID()
    let index: Int
    let value: Double
}

struct NavRangeSeries: Sendable {
    let account: [ChartPoint]
    let benchmark: [ChartPoint]
}

struct RadarSnapshot: Sendable {
    let key: String
    let title: String
    let values: [Double]
    let score: Double
}

enum HoldingsMockData {
    static let funds: [HoldingFund] = [
        .init(
            id: "510300",
            code: "510300",
            name: "沪深300ETF",
            type: "宽基",
            targetWeight: 0.30,
            value: 48_320.42,
            cost: 42_100,
            shares: 19_840,
            dayPct: 1.24,
            holdPct: 14.77,
            sparkline: makeSeries(days: 30, seed: 10, volatility: 0.012, drift: 0.0008)
        ),
        .init(
            id: "513500",
            code: "513500",
            name: "标普500ETF",
            type: "海外",
            targetWeight: 0.25,
            value: 42_180.88,
            cost: 38_500,
            shares: 2_420,
            dayPct: -0.42,
            holdPct: 9.56,
            sparkline: makeSeries(days: 30, seed: 20, volatility: 0.011, drift: 0.0007)
        ),
        .init(
            id: "512100",
            code: "512100",
            name: "中证1000ETF",
            type: "宽基",
            targetWeight: 0.15,
            value: 24_106.55,
            cost: 26_800,
            shares: 9_840,
            dayPct: 2.11,
            holdPct: -10.05,
            sparkline: makeSeries(days: 30, seed: 30, volatility: 0.014, drift: -0.0002)
        ),
        .init(
            id: "512760",
            code: "512760",
            name: "芯片ETF",
            type: "行业",
            targetWeight: 0.10,
            value: 19_844.10,
            cost: 15_200,
            shares: 12_900,
            dayPct: 3.47,
            holdPct: 30.55,
            sparkline: makeSeries(days: 30, seed: 40, volatility: 0.016, drift: 0.0011)
        ),
        .init(
            id: "512170",
            code: "512170",
            name: "医疗ETF",
            type: "行业",
            targetWeight: 0.10,
            value: 9_233.40,
            cost: 12_600,
            shares: 8_760,
            dayPct: -1.18,
            holdPct: -26.72,
            sparkline: makeSeries(days: 30, seed: 50, volatility: 0.013, drift: -0.0007)
        ),
        .init(
            id: "518880",
            code: "518880",
            name: "黄金ETF",
            type: "商品",
            targetWeight: 0.10,
            value: 12_940.22,
            cost: 10_100,
            shares: 1_860,
            dayPct: 0.68,
            holdPct: 28.12,
            sparkline: makeSeries(days: 30, seed: 60, volatility: 0.008, drift: 0.0008)
        )
    ]

    static let overview = HoldingsOverview(
        totalValue: totalValue,
        unitNAV: 1.2847,
        dayPnl: 1_284.62,
        dayPct: 0.85,
        dayDrawdown: -0.32,
        holdPnl: totalValue - totalCost,
        holdPct: ((totalValue - totalCost) / totalCost) * 100,
        xirr: 12.83,
        excess: 4.62,
        maxDrawdown6M: -8.24,
        sharpe: 1.42,
        calmar: 1.78,
        unbalance: 0.143
    )

    static let navSeries: [String: NavRangeSeries] = [
        "1M": .init(
            account: makeSeries(days: 30, seed: 12_345, volatility: 0.010, drift: 0.0012),
            benchmark: makeSeries(days: 30, seed: 9_911, volatility: 0.009, drift: 0.0007)
        ),
        "3M": .init(
            account: makeSeries(days: 90, seed: 23_456, volatility: 0.009, drift: 0.0010),
            benchmark: makeSeries(days: 90, seed: 8_833, volatility: 0.009, drift: 0.0006)
        ),
        "6M": .init(
            account: makeSeries(days: 180, seed: 34_567, volatility: 0.008, drift: 0.0009),
            benchmark: makeSeries(days: 180, seed: 7_722, volatility: 0.008, drift: 0.0005)
        ),
        "1Y": .init(
            account: makeSeries(days: 365, seed: 45_678, volatility: 0.008, drift: 0.0008),
            benchmark: makeSeries(days: 365, seed: 6_611, volatility: 0.008, drift: 0.0004)
        )
    ]

    static let radarDimensions = ["超额收益", "执行程度", "投资纪律", "风险控制", "风格", "收益"]

    static let radarSnapshots: [RadarSnapshot] = [
        .init(key: "lastMonth", title: "上月", values: [69, 77, 70, 58, 65, 68], score: 67.8),
        .init(key: "lastWeek", title: "上周", values: [74, 81, 75, 62, 68, 72], score: 72.0),
        .init(key: "current", title: "当前", values: [78, 84, 72, 65, 70, 76], score: 74.2)
    ]

    private static var totalValue: Double {
        funds.reduce(0) { $0 + $1.value }
    }

    private static var totalCost: Double {
        funds.reduce(0) { $0 + $1.cost }
    }

    static func makeSeries(days: Int, seed: UInt64, volatility: Double, drift: Double) -> [ChartPoint] {
        var generator = SeededGenerator(seed: seed)
        var value = 0.0
        var points = [ChartPoint(index: 0, value: value)]

        for index in 1...days {
            let shock = (generator.nextUnit() - 0.5) * 2 * volatility + drift
            value = value + shock * 100
            value = value * 0.995 + (Double(index) * drift * 50)
            points.append(ChartPoint(index: index, value: value))
        }

        return points
    }
}

private struct SeededGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func nextUnit() -> Double {
        state = state &+ 0x6D2B79F5
        var z = state
        z = (z ^ (z >> 15)) &* (z | 1)
        z ^= z &+ ((z ^ (z >> 7)) &* (z | 61))
        return Double((z ^ (z >> 14)) & 0xFFFF_FFFF) / Double(UInt32.max)
    }
}
