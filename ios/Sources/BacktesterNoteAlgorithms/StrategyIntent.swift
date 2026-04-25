import Foundation

public struct StrategyIntent: Codable, Equatable, Sendable {
    public var targetWeight: Double
    public var weeklyMinimumContribution: Double
    public var driftTolerance: Double
    public var quarterlyRebalanceIntervalDays: Int
    public var emergencyRepairWindowDays: Int
    public var negligibleDeviation: Double

    public init(
        targetWeight: Double = 0.25,
        weeklyMinimumContribution: Double = 1_000,
        driftTolerance: Double = 0.08,
        quarterlyRebalanceIntervalDays: Int = 90,
        emergencyRepairWindowDays: Int = 90,
        negligibleDeviation: Double = 0.02
    ) {
        self.targetWeight = targetWeight
        self.weeklyMinimumContribution = weeklyMinimumContribution
        self.driftTolerance = driftTolerance
        self.quarterlyRebalanceIntervalDays = quarterlyRebalanceIntervalDays
        self.emergencyRepairWindowDays = emergencyRepairWindowDays
        self.negligibleDeviation = negligibleDeviation
    }

    public static let `default` = StrategyIntent()
}
