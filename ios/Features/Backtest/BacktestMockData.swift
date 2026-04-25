import Foundation

struct BacktestFund: Identifiable, Sendable {
    let id: String
    let code: String
    let name: String
    let type: String
}

struct BacktestPortfolio: Identifiable, Sendable {
    let id: String
    let name: String
    let fundCodes: [String]
    let weights: [Double]
    let note: String
}

struct BacktestHistoryItem: Identifiable, Sendable {
    let id: String
    let name: String
    let type: String
    let period: String
    let cagr: Double
    let maxDrawdown: Double
    let sharpe: Double
    let savedAt: String
    let series: [ChartPoint]
}

enum BacktestMode: String, CaseIterable, Identifiable {
    case single
    case portfolio
    case sip
    case history

    var id: String { rawValue }

    var title: String {
        switch self {
        case .single:
            return "单基金"
        case .portfolio:
            return "组合"
        case .sip:
            return "定投"
        case .history:
            return "历史"
        }
    }
}

enum BacktestMockData {
    static let funds: [BacktestFund] = [
        .init(id: "510300", code: "510300", name: "沪深300ETF", type: "宽基"),
        .init(id: "513500", code: "513500", name: "标普500ETF", type: "海外"),
        .init(id: "512100", code: "512100", name: "中证1000ETF", type: "宽基"),
        .init(id: "512760", code: "512760", name: "芯片ETF", type: "行业")
    ]

    static let portfolios: [BacktestPortfolio] = [
        .init(id: "p1", name: "核心-卫星", fundCodes: ["510300", "513500", "512100", "512760"], weights: [0.40, 0.30, 0.20, 0.10], note: "60/40 变体，季度再平衡"),
        .init(id: "p2", name: "全天候", fundCodes: ["510300", "513500", "518880", "159920"], weights: [0.30, 0.30, 0.20, 0.20], note: "风险平价"),
        .init(id: "p3", name: "进攻型", fundCodes: ["512100", "512760", "159915"], weights: [0.40, 0.35, 0.25], note: "高波动，月度再平衡")
    ]

    static let previewSeries = makeSeries(days: 240, seed: 8_899, volatility: 0.009, drift: 0.0012)
    static let benchmarkSeries = makeSeries(days: 240, seed: 4_422, volatility: 0.009, drift: 0.0007)

    static let history: [BacktestHistoryItem] = [
        .init(id: "b1", name: "核心-卫星 · 月定投", type: "组合", period: "2020-01 → 2025-12", cagr: 11.8, maxDrawdown: -18.2, sharpe: 1.23, savedAt: "04-18", series: makeSeries(days: 80, seed: 97, volatility: 0.009, drift: 0.0011)),
        .init(id: "b2", name: "沪深300 · 周定投", type: "定投", period: "2018-01 → 2025-12", cagr: 6.4, maxDrawdown: -32.1, sharpe: 0.58, savedAt: "04-15", series: makeSeries(days: 80, seed: 194, volatility: 0.010, drift: 0.0006)),
        .init(id: "b3", name: "全天候 · 季再平衡", type: "组合", period: "2019-01 → 2025-12", cagr: 8.2, maxDrawdown: -11.4, sharpe: 1.38, savedAt: "04-10", series: makeSeries(days: 80, seed: 291, volatility: 0.007, drift: 0.0008))
    ]

    static func makeSeries(days: Int, seed: UInt64, volatility: Double, drift: Double) -> [ChartPoint] {
        var state = seed
        var value = 0.0
        var points = [ChartPoint(index: 0, value: value)]

        for index in 1...days {
            state = state &+ 0x6D2B79F5
            let unit = Double((state ^ (state >> 14)) & 0xFFFF_FFFF) / Double(UInt32.max)
            let shock = (unit - 0.5) * 2 * volatility + drift
            value = value + shock * 100
            value = value * 0.995 + Double(index) * drift * 50
            points.append(ChartPoint(index: index, value: value))
        }

        return points
    }
}
