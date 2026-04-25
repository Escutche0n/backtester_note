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
}
