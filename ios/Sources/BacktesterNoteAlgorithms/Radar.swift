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

public struct RadarConfig: Codable, Equatable, Sendable {
    public var excessQualityWindowDays: Int
    public var strategyExecutionWindowDays: Int
    public var tradingDisciplineWindowDays: Int
    public var riskControlWindowDays: Int
    public var styleStabilityWindowDays: Int
    public var sustainabilityWindowDays: Int

    public var subWeightWeeklyContribution: Double
    public var subWeightUnderweightFunding: Double
    public var subWeightThresholdRepair: Double
    public var subWeightStructureConvergence: Double
    public var subWeightClassifiedAverage: Double
    public var subWeightEmergency: Double

    public var excessQualityFullMarkAnnualExcess: Double
    public var excessQualityZeroAnnualExcess: Double

    public init(
        excessQualityWindowDays: Int = 180,
        strategyExecutionWindowDays: Int = 90,
        tradingDisciplineWindowDays: Int = 90,
        riskControlWindowDays: Int = 180,
        styleStabilityWindowDays: Int = 180,
        sustainabilityWindowDays: Int = 180,
        subWeightWeeklyContribution: Double = 0.22,
        subWeightUnderweightFunding: Double = 0.22,
        subWeightThresholdRepair: Double = 0.18,
        subWeightStructureConvergence: Double = 0.14,
        subWeightClassifiedAverage: Double = 0.14,
        subWeightEmergency: Double = 0.10,
        excessQualityFullMarkAnnualExcess: Double = 0.05,
        excessQualityZeroAnnualExcess: Double = -0.05
    ) {
        self.excessQualityWindowDays = excessQualityWindowDays
        self.strategyExecutionWindowDays = strategyExecutionWindowDays
        self.tradingDisciplineWindowDays = tradingDisciplineWindowDays
        self.riskControlWindowDays = riskControlWindowDays
        self.styleStabilityWindowDays = styleStabilityWindowDays
        self.sustainabilityWindowDays = sustainabilityWindowDays
        self.subWeightWeeklyContribution = subWeightWeeklyContribution
        self.subWeightUnderweightFunding = subWeightUnderweightFunding
        self.subWeightThresholdRepair = subWeightThresholdRepair
        self.subWeightStructureConvergence = subWeightStructureConvergence
        self.subWeightClassifiedAverage = subWeightClassifiedAverage
        self.subWeightEmergency = subWeightEmergency
        self.excessQualityFullMarkAnnualExcess = excessQualityFullMarkAnnualExcess
        self.excessQualityZeroAnnualExcess = excessQualityZeroAnnualExcess
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
        return clamp01((annualExcessReturn - zero) / (full - zero))
    }

    private static func clamp01(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
