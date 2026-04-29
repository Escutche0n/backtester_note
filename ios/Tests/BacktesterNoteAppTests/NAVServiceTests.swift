import XCTest
@testable import BacktesterNote

final class NAVServiceTests: XCTestCase {
    func testConfirmedSeriesUsesManualFundNAV() {
        let account = makeAccount(holdings: [
            makeHolding(code: "510300", shares: 100, value: 100)
        ])
        let records = [
            makeNAV(code: "510300", dateKey: "2024-01-02", nav: "1.0000"),
            makeNAV(code: "510300", dateKey: "2024-01-03", nav: "1.1000")
        ]

        let series = NAVService.accountSeries(for: account, fundNAVRecords: records)

        XCTAssertEqual(series.points.count, 2)
        XCTAssertEqual(series.points.last?.returnPercent ?? 0, 10, accuracy: 0.0001)
        XCTAssertEqual(series.points.map(\.credibility), [.confirmed, .confirmed])
        XCTAssertTrue(series.missingValuationDateKeys.isEmpty)
        XCTAssertTrue(series.flowOnlyDateKeys.isEmpty)
    }

    func testBaselineFallsBackToSnapshotOnlyWhenOfficialNAVStartsLater() {
        let account = makeAccount(holdings: [
            makeHolding(code: "510300", shares: 100, value: 100)
        ])
        let records = [
            makeNAV(code: "510300", dateKey: "2024-01-03", nav: "1.1000")
        ]

        let series = NAVService.accountSeries(for: account, fundNAVRecords: records)

        XCTAssertEqual(series.points.count, 2)
        XCTAssertEqual(series.points.first?.credibility, .snapshotOnly)
        XCTAssertEqual(series.points.last?.credibility, .confirmed)
        XCTAssertEqual(series.points.last?.returnPercent ?? 0, 10, accuracy: 0.0001)
    }

    func testFlowWithoutSameDayValuationStopsBeforeFakeNAV() {
        let account = makeAccount(
            holdings: [makeHolding(code: "510300", shares: 100, value: 100)],
            flows: [
                makeFlow(dateKey: "2024-01-03", code: "510300", type: .buy, amount: 10, shares: 10)
            ]
        )
        let records = [
            makeNAV(code: "510300", dateKey: "2024-01-02", nav: "1.0000"),
            makeNAV(code: "510300", dateKey: "2024-01-04", nav: "1.1000")
        ]

        let series = NAVService.accountSeries(for: account, fundNAVRecords: records)

        XCTAssertEqual(series.points.map(\.dateKey), ["2024-01-02"])
        XCTAssertEqual(series.flowOnlyDateKeys, ["2024-01-03"])
    }

    func testPartialFundNAVDateIsReportedAsGap() {
        let account = makeAccount(holdings: [
            makeHolding(code: "510300", shares: 100, value: 100),
            makeHolding(code: "000001", shares: 100, value: 100)
        ])
        let records = [
            makeNAV(code: "000001", dateKey: "2024-01-02", nav: "1.0000"),
            makeNAV(code: "510300", dateKey: "2024-01-02", nav: "1.0000"),
            makeNAV(code: "510300", dateKey: "2024-01-03", nav: "1.1000"),
            makeNAV(code: "000001", dateKey: "2024-01-04", nav: "1.0000"),
            makeNAV(code: "510300", dateKey: "2024-01-04", nav: "1.1000")
        ]

        let series = NAVService.accountSeries(for: account, fundNAVRecords: records)

        XCTAssertEqual(series.points.map(\.dateKey), ["2024-01-02", "2024-01-04"])
        XCTAssertEqual(series.points.last?.returnPercent ?? 0, 5, accuracy: 0.0001)
        XCTAssertEqual(series.missingValuationDateKeys, ["2024-01-03"])
    }

    private func makeAccount(
        holdings: [PortfolioHolding],
        flows: [PortfolioFlow] = []
    ) -> PortfolioAccount {
        PortfolioAccount(
            accountID: "main",
            displayName: "Main",
            currency: "CNY",
            snapshots: [
                PortfolioSnapshot(
                    date: ImportDateFormatter.parseDay("2024-01-02")!,
                    isBaseline: true,
                    note: nil,
                    holdings: holdings
                )
            ],
            flows: flows,
            preferences: .defaultV1
        )
    }

    private func makeHolding(code: String, shares: Double, value: Double) -> PortfolioHolding {
        PortfolioHolding(code: code, name: code, shares: shares, value: value, nav: value / shares)
    }

    private func makeFlow(
        dateKey: String,
        code: String,
        type: PortfolioFlowType,
        amount: Double,
        shares: Double
    ) -> PortfolioFlow {
        PortfolioFlow(
            date: ImportDateFormatter.parseDay(dateKey)!,
            code: code,
            type: type,
            amount: amount,
            shares: shares,
            fee: 0,
            note: nil
        )
    }

    private func makeNAV(code: String, dateKey: String, nav: String) -> FundDailyNAVRecord {
        FundDailyNAVRecord(
            code: code,
            date: ImportDateFormatter.parseDay(dateKey)!,
            nav: Decimal(string: nav)!
        )
    }
}
