import Foundation
import Testing
@testable import BacktesterNoteAlgorithms

@Suite("Metrics")
struct MetricsTests {
    @Test("cagr uses 365 day denominator")
    func cagr() throws {
        let start = try #require(BNCalendar.date(from: "2025-01-01"))
        let end = try #require(BNCalendar.date(from: "2026-01-01"))

        let result = try #require(Metrics.cagr(
            startValue: 100,
            endValue: 121,
            startDate: start,
            endDate: end
        ))

        #expect(abs(result - 0.21) < 0.000_000_1)
    }

    @Test("xirr solves annual single outflow inflow")
    func xirr() throws {
        let start = try #require(BNCalendar.date(from: "2025-01-01"))
        let end = try #require(BNCalendar.date(from: "2026-01-01"))

        let result = try #require(XIRR.calculate([
            CashFlow(date: start, amount: -100),
            CashFlow(date: end, amount: 112),
        ]))

        #expect(abs(result - 0.12) < 0.000_000_1)
    }

    @Test("drawdown returns negative values")
    func drawdown() {
        #expect(Metrics.maxDrawdown(values: [100, 120, 90, 110]) == -0.25)
        #expect(abs(Metrics.currentDrawdown(values: [100, 120, 90, 110]) - (-0.0833333333)) < 0.000_000_1)
    }
}
