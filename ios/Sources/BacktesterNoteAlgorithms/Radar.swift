import Foundation

public enum StrategyRadarDimension: String, CaseIterable, Codable, Sendable {
    case excessQuality
    case strategyExecution
    case tradingDiscipline
    case riskControl
    case styleStability
    case sustainability
}

public enum StrategyRadarSnapshotLabel: String, Codable, Sendable {
    case current
    case lastWeek
    case lastMonth
}

public struct StrategyRadarSnapshot: Equatable, Sendable {
    public let label: StrategyRadarSnapshotLabel
    public let anchorDate: Date
    public let scores: [StrategyRadarDimension: Double]

    public init(
        label: StrategyRadarSnapshotLabel,
        anchorDate: Date,
        scores: [StrategyRadarDimension: Double]
    ) {
        self.label = label
        self.anchorDate = anchorDate
        self.scores = scores
    }

    public var overallScore: Double? {
        let values = StrategyRadarDimension.allCases.compactMap { scores[$0] }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }
}

public struct RadarNAVPoint: Equatable, Sendable {
    public let date: Date
    public let nav: Double

    public init(date: Date, nav: Double) {
        self.date = date
        self.nav = nav
    }
}

public struct RadarConfig: Codable, Equatable, Sendable {
    public var excessQualityWindowDays: Int
    public var strategyExecutionWindowDays: Int
    public var tradingDisciplineWindowDays: Int
    public var riskControlWindowDays: Int
    public var styleStabilityWindowDays: Int
    public var sustainabilityWindowDays: Int

    public var lastWeekTradingDayOffset: Int
    public var lastMonthTradingDayOffset: Int

    public var subWeightWeeklyContribution: Double
    public var subWeightUnderweightFunding: Double
    public var subWeightThresholdRepair: Double
    public var subWeightStructureConvergence: Double
    public var subWeightClassifiedAverage: Double
    public var subWeightEmergency: Double

    public var excessQualityFullMarkAnnualExcess: Double
    public var excessQualityZeroAnnualExcess: Double

    public var sustainabilityPositiveDayLower: Double
    public var sustainabilityPositiveDayUpper: Double
    public var sustainabilityPositiveMonthLower: Double
    public var sustainabilityPositiveMonthUpper: Double
    public var sustainabilityDispersionLower: Double
    public var sustainabilityDispersionUpper: Double
    public var sustainabilityImprovementLower: Double
    public var sustainabilityImprovementUpper: Double

    public init(
        excessQualityWindowDays: Int = 180,
        strategyExecutionWindowDays: Int = 90,
        tradingDisciplineWindowDays: Int = 90,
        riskControlWindowDays: Int = 180,
        styleStabilityWindowDays: Int = 180,
        sustainabilityWindowDays: Int = 180,
        lastWeekTradingDayOffset: Int = 5,
        lastMonthTradingDayOffset: Int = 22,
        subWeightWeeklyContribution: Double = 0.22,
        subWeightUnderweightFunding: Double = 0.22,
        subWeightThresholdRepair: Double = 0.18,
        subWeightStructureConvergence: Double = 0.14,
        subWeightClassifiedAverage: Double = 0.14,
        subWeightEmergency: Double = 0.10,
        excessQualityFullMarkAnnualExcess: Double = 0.05,
        excessQualityZeroAnnualExcess: Double = -0.05,
        sustainabilityPositiveDayLower: Double = 0.38,
        sustainabilityPositiveDayUpper: Double = 0.68,
        sustainabilityPositiveMonthLower: Double = 0.30,
        sustainabilityPositiveMonthUpper: Double = 0.85,
        sustainabilityDispersionLower: Double = -0.20,
        sustainabilityDispersionUpper: Double = 0.80,
        sustainabilityImprovementLower: Double = -0.15,
        sustainabilityImprovementUpper: Double = 0.15
    ) {
        self.excessQualityWindowDays = excessQualityWindowDays
        self.strategyExecutionWindowDays = strategyExecutionWindowDays
        self.tradingDisciplineWindowDays = tradingDisciplineWindowDays
        self.riskControlWindowDays = riskControlWindowDays
        self.styleStabilityWindowDays = styleStabilityWindowDays
        self.sustainabilityWindowDays = sustainabilityWindowDays
        self.lastWeekTradingDayOffset = lastWeekTradingDayOffset
        self.lastMonthTradingDayOffset = lastMonthTradingDayOffset
        self.subWeightWeeklyContribution = subWeightWeeklyContribution
        self.subWeightUnderweightFunding = subWeightUnderweightFunding
        self.subWeightThresholdRepair = subWeightThresholdRepair
        self.subWeightStructureConvergence = subWeightStructureConvergence
        self.subWeightClassifiedAverage = subWeightClassifiedAverage
        self.subWeightEmergency = subWeightEmergency
        self.excessQualityFullMarkAnnualExcess = excessQualityFullMarkAnnualExcess
        self.excessQualityZeroAnnualExcess = excessQualityZeroAnnualExcess
        self.sustainabilityPositiveDayLower = sustainabilityPositiveDayLower
        self.sustainabilityPositiveDayUpper = sustainabilityPositiveDayUpper
        self.sustainabilityPositiveMonthLower = sustainabilityPositiveMonthLower
        self.sustainabilityPositiveMonthUpper = sustainabilityPositiveMonthUpper
        self.sustainabilityDispersionLower = sustainabilityDispersionLower
        self.sustainabilityDispersionUpper = sustainabilityDispersionUpper
        self.sustainabilityImprovementLower = sustainabilityImprovementLower
        self.sustainabilityImprovementUpper = sustainabilityImprovementUpper
    }

    public static let `default` = RadarConfig()
}

public struct StrategyExecutionSubscores: Equatable, Sendable {
    public var weeklyContributionCoverage: Double
    public var underweightFundingHitRate: Double
    public var thresholdRepairRate: Double
    public var structureConvergenceScore: Double
    public var classifiedAverage: Double
    public var emergencyScore: Double

    public init(
        weeklyContributionCoverage: Double,
        underweightFundingHitRate: Double,
        thresholdRepairRate: Double,
        structureConvergenceScore: Double,
        classifiedAverage: Double,
        emergencyScore: Double
    ) {
        self.weeklyContributionCoverage = weeklyContributionCoverage
        self.underweightFundingHitRate = underweightFundingHitRate
        self.thresholdRepairRate = thresholdRepairRate
        self.structureConvergenceScore = structureConvergenceScore
        self.classifiedAverage = classifiedAverage
        self.emergencyScore = emergencyScore
    }
}

public enum RadarScoring {
    public static func strategyAlignmentScore(
        _ subscores: StrategyExecutionSubscores,
        config: RadarConfig = .default
    ) -> Double {
        clamp01(
            clamp01(subscores.weeklyContributionCoverage) * config.subWeightWeeklyContribution
            + clamp01(subscores.underweightFundingHitRate) * config.subWeightUnderweightFunding
            + clamp01(subscores.thresholdRepairRate) * config.subWeightThresholdRepair
            + clamp01(subscores.structureConvergenceScore) * config.subWeightStructureConvergence
            + clamp01(subscores.classifiedAverage) * config.subWeightClassifiedAverage
            + clamp01(subscores.emergencyScore) * config.subWeightEmergency
        )
    }

    public static func excessQualityScore(
        annualExcessReturn: Double,
        config: RadarConfig = .default
    ) -> Double {
        let zero = config.excessQualityZeroAnnualExcess
        let full = config.excessQualityFullMarkAnnualExcess
        guard full > zero else { return 0 }
        return normalizedScore(value: annualExcessReturn, lower: zero, upper: full)
    }

    /// 收益质量（sustainability）打分。
    ///
    /// 月度分桶**强制**用 ``BNCalendar/calendar``（固定 Asia/Shanghai TimeZone）。
    /// 产品定位是国内基金复盘工具，按非 CN 时区看盘没有合法语义；为防止
    /// "传错 calendar" 这类漂移在调用方发生，本方法**不暴露** `calendar` 参数。
    /// 这是 `docs/algorithms/nav.v1.md` §0 "全 App 统一 Asia/Shanghai 自然日"
    /// 红线在 sustainability 上的兑现点。
    public static func sustainabilityScore(
        currentPoints: [RadarNAVPoint],
        previousPoints: [RadarNAVPoint] = [],
        config: RadarConfig = .default
    ) -> Double {
        let returns = dailyReturns(points: currentPoints)
        let positiveDayRatio = ratio(returns.filter { $0 > 0 }.count, over: returns.count)
        let positiveDayScore = normalizedScore(
            value: positiveDayRatio,
            lower: config.sustainabilityPositiveDayLower,
            upper: config.sustainabilityPositiveDayUpper
        )

        let monthlyReturns = monthlyReturns(points: currentPoints)
        let positiveMonthRatio = ratio(monthlyReturns.filter { $0 > 0 }.count, over: monthlyReturns.count)
        let positiveMonthScore = normalizedScore(
            value: positiveMonthRatio,
            lower: config.sustainabilityPositiveMonthLower,
            upper: config.sustainabilityPositiveMonthUpper
        )

        let positiveReturns = returns.filter { $0 > 0 }.sorted(by: >)
        let totalPositive = positiveReturns.reduce(0, +)
        let topFiveShare = totalPositive > 0
            ? positiveReturns.prefix(5).reduce(0, +) / totalPositive
            : 1
        let dispersionScore = normalizedScore(
            value: 0.8 - topFiveShare,
            lower: config.sustainabilityDispersionLower,
            upper: config.sustainabilityDispersionUpper
        )

        let previousReturns = dailyReturns(points: previousPoints)
        let previousPositiveDayRatio = previousReturns.isEmpty
            ? positiveDayRatio
            : ratio(previousReturns.filter { $0 > 0 }.count, over: previousReturns.count)
        let improvementScore = normalizedScore(
            value: positiveDayRatio - previousPositiveDayRatio,
            lower: config.sustainabilityImprovementLower,
            upper: config.sustainabilityImprovementUpper
        )

        return weightedScore([
            (positiveDayScore, 0.25),
            (positiveMonthScore, 0.30),
            (dispersionScore, 0.25),
            (improvementScore, 0.20),
        ])
    }

    private static func dailyReturns(points: [RadarNAVPoint]) -> [Double] {
        let sortedValues = points.sorted { $0.date < $1.date }.map(\.nav)
        guard sortedValues.count > 1 else { return [] }
        return zip(sortedValues.dropFirst(), sortedValues).compactMap { current, previous in
            guard previous > 0 else { return nil }
            return current / previous - 1
        }
    }

    /// 月度收益分桶。强制 Asia/Shanghai 自然月，不接受外部 calendar
    /// （见 ``sustainabilityScore(currentPoints:previousPoints:config:)``
    /// 文档注释中的设计依据）。
    private static func monthlyReturns(points: [RadarNAVPoint]) -> [Double] {
        let grouped = Dictionary(grouping: points) { point in
            BNCalendar.calendar.dateComponents([.year, .month], from: point.date)
        }
        return grouped.values.compactMap { rows in
            let sorted = rows.sorted { $0.date < $1.date }
            guard let start = sorted.first?.nav,
                  let end = sorted.last?.nav,
                  start > 0
            else { return nil }
            return end / start - 1
        }
    }

    private static func ratio(_ count: Int, over total: Int) -> Double {
        Double(count) / max(Double(total), 1)
    }

    private static func normalizedScore(value: Double, lower: Double, upper: Double) -> Double {
        guard upper > lower else { return 0.5 }
        return clamp01((value - lower) / (upper - lower))
    }

    private static func weightedScore(_ components: [(Double, Double)]) -> Double {
        let totalWeight = components.reduce(0.0) { $0 + $1.1 }
        guard totalWeight > 0 else { return 0 }
        return clamp01(components.reduce(0.0) { $0 + ($1.0 * $1.1) } / totalWeight)
    }

    private static func clamp01(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
