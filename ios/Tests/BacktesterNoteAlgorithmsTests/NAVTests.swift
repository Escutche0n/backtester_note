import Testing
@testable import BacktesterNoteAlgorithms

@Suite("NAV")
struct NAVTests {
    @Test("starts first non-empty segment at nav 1")
    func segmentStart() {
        let result = NAVCalculator.calculate(
            NAVInput(marketValueSeries: [
                (date: "2026-01-01", value: 1_000),
                (date: "2026-01-02", value: 1_100),
            ])
        )

        #expect(result.points.map(\.dateKey) == ["2026-01-01", "2026-01-02"])
        #expect(result.points[0].nav == 1.0)
        #expect(result.points[1].nav == 1.1)
        #expect(result.ledgerRows[0].status == .segmentStart)
        #expect(result.ledgerRows[1].status == .okNoCashFlow)
    }

    @Test("external cash flow changes shares, not same-day nav")
    func cashFlowIsStrippedFromNAV() {
        let result = NAVCalculator.calculate(
            NAVInput(
                marketValueSeries: [
                    (date: "2026-01-01", value: 1_000),
                    (date: "2026-01-02", value: 1_200),
                    (date: "2026-01-03", value: 1_320),
                ],
                cashFlowByDate: [
                    "2026-01-02": 100,
                ]
            )
        )

        #expect(result.points.map(\.nav) == [1.0, 1.1, 1.21])
        #expect(result.ledgerRows[1].status == .okWithCashFlow)
        #expect(result.ledgerRows[1].finalShares == 1090.9091)
    }

    @Test("zero position ends segment and next non-zero point restarts at 1")
    func segmentResetAfterZeroPosition() {
        let result = NAVCalculator.calculate(
            NAVInput(marketValueSeries: [
                (date: "2026-01-01", value: 1_000),
                (date: "2026-01-02", value: 0),
                (date: "2026-01-03", value: 500),
            ])
        )

        #expect(result.points.map(\.dateKey) == ["2026-01-01", "2026-01-03"])
        #expect(result.points.map(\.nav) == [1.0, 1.0])
        #expect(result.ledgerRows[1].status == .segmentEndZeroPosition)
        #expect(result.ledgerRows[2].status == .segmentStart)
    }
}
