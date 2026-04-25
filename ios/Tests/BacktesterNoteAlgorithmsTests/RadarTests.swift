import Foundation
import Testing
@testable import BacktesterNoteAlgorithms

@Suite("Radar")
struct RadarTests {
    @Test("overall score is simple average")
    func overallScoreAverage() throws {
        let date = try #require(BNCalendar.date(from: "2026-04-25"))
        let snapshot = StrategyRadarSnapshot(
            label: .current,
            anchorDate: date,
            scores: [
                .excessQuality: 0.2,
                .strategyExecution: 0.4,
                .tradingDiscipline: 0.6,
                .riskControl: 0.8,
                .styleStability: 1.0,
                .sustainability: 0.0,
            ]
        )

        #expect(snapshot.overallScore == 0.5)
    }

    @Test("strategy execution subweights match contract")
    func strategyExecutionWeights() {
        let firstOnly = StrategyExecutionSubscores(
            weeklyContributionCoverage: 1,
            underweightFundingHitRate: 0,
            thresholdRepairRate: 0,
            structureConvergenceScore: 0,
            classifiedAverage: 0,
            emergencyScore: 0
        )
        let lastOnly = StrategyExecutionSubscores(
            weeklyContributionCoverage: 0,
            underweightFundingHitRate: 0,
            thresholdRepairRate: 0,
            structureConvergenceScore: 0,
            classifiedAverage: 0,
            emergencyScore: 1
        )

        #expect(RadarScoring.strategyAlignmentScore(firstOnly) == 0.22)
        #expect(RadarScoring.strategyAlignmentScore(lastOnly) == 0.10)
    }

    @Test("excess quality threshold is linear")
    func excessQualityThresholds() {
        #expect(RadarScoring.excessQualityScore(annualExcessReturn: -0.05) == 0)
        #expect(RadarScoring.excessQualityScore(annualExcessReturn: 0.00) == 0.5)
        #expect(RadarScoring.excessQualityScore(annualExcessReturn: 0.05) == 1)
    }

    @Test("snapshot anchors use trading-day offsets")
    func snapshotAnchorOffsets() {
        let config = RadarConfig.default

        #expect(config.lastWeekTradingDayOffset == 5)
        #expect(config.lastMonthTradingDayOffset == 22)
    }

    @Test("sustainability score matches old app formula")
    func sustainabilityFormula() throws {
        let currentPoints = try navPoints([
            ("2026-01-01", 100),
            ("2026-01-02", 101),
            ("2026-02-01", 100),
            ("2026-02-02", 102),
            ("2026-03-01", 101),
            ("2026-03-02", 102),
        ])
        let previousPoints = try navPoints([
            ("2025-10-01", 100),
            ("2025-10-02", 101),
            ("2025-11-01", 100),
            ("2025-11-02", 99),
            ("2025-12-01", 100),
            ("2025-12-02", 99),
        ])
        let score = RadarScoring.sustainabilityScore(
            currentPoints: currentPoints,
            previousPoints: previousPoints
        )

        #expect(abs(score - 0.6833) < 0.0001)
    }

    /// Codex P2-1 回归 / nav.v1.md §0 红线 / Elvis 2026-04-25 决议：
    /// `sustainabilityScore` 不暴露 calendar 参数，月度分桶硬编码 Asia/Shanghai。
    ///
    /// 用对时区敏感的边界数据（上海 2026-02-01 00:00 = UTC 2026-01-31 16:00），
    /// 断言**确定性**输出。如果月度分桶切回 `Calendar.current`，本测试在非 CN
    /// 时区机器（UTC / LA / 任何 GMT-X 时区）上必挂 —— UTC 下 2026-02-01 上海凌晨
    /// 会落进 UTC 1 月，桶结构变化 → positiveMonthRatio 变化 → 分数变化。
    /// CN 时区机器上仍碰巧 = 期望值，但只要任何一处 CI 不在 CN 时区，回归就生效。
    @Test("sustainability uses Asia/Shanghai for month bucketing (P2-1 regression)")
    func sustainabilityIsTimezoneStable() throws {
        let pointsAtMonthBoundary = try navPoints([
            ("2026-01-30", 100),
            ("2026-01-31", 101),
            ("2026-02-01", 100),
            ("2026-02-02", 101),
            ("2026-03-01", 100),
            ("2026-03-02", 102),
        ])

        let score = RadarScoring.sustainabilityScore(
            currentPoints: pointsAtMonthBoundary
        )

        // 手算（Asia/Shanghai 分桶）：
        //   dailyReturns = [+1%, ≈-0.99%, +1%, ≈-0.99%, +2%]   (5 个，相邻配对)
        //     positiveDayRatio   = 3/5 = 0.60
        //     positiveDayScore   = (0.60 - 0.38)/0.30 ≈ 0.7333
        //   monthlyBuckets (Shanghai):
        //     2026-01: 100 → 101  = +1.00%
        //     2026-02: 100 → 101  = +1.00%
        //     2026-03: 100 → 102  = +2.00%
        //     positiveMonthRatio = 3/3 = 1.00
        //     positiveMonthScore = clamp((1.00-0.30)/0.55) = 1.0
        //   topFiveShare = 1.0 → dispersionScore = (0.8-1.0 - (-0.2)) / 1.0 = 0
        //   previousPoints empty → improvementValue = 0 → improvementScore = 0.5
        //   total = 0.7333*0.25 + 1.0*0.30 + 0*0.25 + 0.5*0.20 ≈ 0.5833
        #expect(abs(score - 0.5833) < 0.005)
    }

    private func navPoints(_ rows: [(String, Double)]) throws -> [RadarNAVPoint] {
        try rows.map { dateString, nav in
            let date = try #require(BNCalendar.date(from: dateString))
            return RadarNAVPoint(date: date, nav: nav)
        }
    }
}
