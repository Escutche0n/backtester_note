import Testing
@testable import BacktesterNoteAlgorithms

@Suite("StrategyIntent")
struct StrategyIntentTests {
    @Test("defaults match contract")
    func defaults() {
        let intent = StrategyIntent.default

        #expect(intent.targetWeight == 0.25)
        #expect(intent.weeklyMinimumContribution == 1_000)
        #expect(intent.driftTolerance == 0.08)
        #expect(intent.quarterlyRebalanceIntervalDays == 90)
        #expect(intent.emergencyRepairWindowDays == 90)
        #expect(intent.negligibleDeviation == 0.02)
    }
}
