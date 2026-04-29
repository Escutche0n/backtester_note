import XCTest
@testable import BacktesterNote

@MainActor
final class FundNAVServiceTests: XCTestCase {
    func testUpsertWritesAndQueriesSingleFundNAV() throws {
        let service = makeService()
        let date = ImportDateFormatter.parseDay("2024-01-02")!

        let record = try service.upsert(code: "510300", date: date, nav: Decimal(string: "4.1234")!)

        XCTAssertEqual(record.code, "510300")
        XCTAssertEqual(service.records(for: "510300"), [record])
        XCTAssertEqual(service.nav(for: "510300", on: date), record)
    }

    func testUpsertSameCodeAndDayOverwritesExistingNAV() throws {
        let service = makeService()
        let date = ImportDateFormatter.parseDay("2024-01-02")!

        _ = try service.upsert(code: "510300", date: date, nav: Decimal(string: "4.1234")!)
        let overwritten = try service.upsert(code: "510300", date: date, nav: Decimal(string: "4.5678")!)

        XCTAssertEqual(service.records(for: "510300").count, 1)
        XCTAssertEqual(service.nav(for: "510300", on: date), overwritten)
        XCTAssertEqual(service.nav(for: "510300", on: date)?.nav, Decimal(string: "4.5678")!)
    }

    func testFourDecimalPrecisionRoundTripsThroughJSON() throws {
        let url = temporaryURL()
        let service = FundNAVService(store: FundNAVStore(fileURL: url))
        let date = ImportDateFormatter.parseDay("2024-01-02")!

        _ = try service.upsert(code: "510300", date: date, nav: Decimal(string: "4.12345")!)
        let reloaded = FundNAVService(store: FundNAVStore(fileURL: url))

        XCTAssertEqual(reloaded.nav(for: "510300", on: date)?.nav, Decimal(string: "4.1235")!)
        XCTAssertTrue(try String(contentsOf: url, encoding: .utf8).contains("\"nav\" : \"4.1235\""))
    }

    func testShanghaiDateKeyIsStableAcrossTimezoneInstants() throws {
        let service = makeService()
        let instant = ISO8601DateFormatter().date(from: "2024-01-01T16:30:00Z")!
        let shanghaiDay = ImportDateFormatter.parseDay("2024-01-02")!

        let record = try service.upsert(code: "510300", date: instant, nav: Decimal(string: "4.1234")!)

        XCTAssertEqual(record.dateKey, "2024-01-02")
        XCTAssertEqual(service.nav(for: "510300", on: shanghaiDay), record)
    }

    func testLatestNAVFindsNearestPriorRecord() throws {
        let service = makeService()

        _ = try service.upsert(
            code: "510300",
            date: ImportDateFormatter.parseDay("2024-01-02")!,
            nav: Decimal(string: "4.1000")!
        )
        let latest = try service.upsert(
            code: "510300",
            date: ImportDateFormatter.parseDay("2024-01-04")!,
            nav: Decimal(string: "4.3000")!
        )

        XCTAssertEqual(
            service.latestNAV(
                onOrBefore: ImportDateFormatter.parseDay("2024-01-05")!,
                for: "510300"
            ),
            latest
        )
        XCTAssertEqual(
            service.latestObservation(
                onOrBefore: ImportDateFormatter.parseDay("2024-01-05")!,
                for: "510300"
            )?.credibility,
            .confirmed
        )
        XCTAssertNil(service.latestNAV(onOrBefore: ImportDateFormatter.parseDay("2024-01-01")!, for: "510300"))
    }

    func testLoadFailureRequiresExplicitOverwrite() throws {
        let url = temporaryURL()
        try Data("broken".utf8).write(to: url)
        let service = FundNAVService(store: FundNAVStore(fileURL: url))

        XCTAssertNotNil(service.loadError)
        XCTAssertThrowsError(try service.upsert(
            code: "510300",
            date: ImportDateFormatter.parseDay("2024-01-02")!,
            nav: Decimal(string: "4.1234")!
        )) { error in
            XCTAssertEqual(error as? FundNAVError, .storeLoadFailed)
        }

        let record = try service.upsert(
            code: "510300",
            date: ImportDateFormatter.parseDay("2024-01-02")!,
            nav: Decimal(string: "4.1234")!,
            allowOverwriteAfterLoadFailure: true
        )

        XCTAssertNil(service.loadError)
        XCTAssertEqual(service.records(for: "510300"), [record])
    }

    func testDeleteRemovesMatchingCodeAndDay() throws {
        let service = makeService()
        let targetDate = ImportDateFormatter.parseDay("2024-01-02")!
        let otherDate = ImportDateFormatter.parseDay("2024-01-03")!

        _ = try service.upsert(code: "510300", date: targetDate, nav: Decimal(string: "4.1234")!)
        let retained = try service.upsert(code: "510300", date: otherDate, nav: Decimal(string: "4.5678")!)

        XCTAssertTrue(try service.delete(code: "510300", date: targetDate))
        XCTAssertEqual(service.records(for: "510300"), [retained])
        XCTAssertFalse(try service.delete(code: "510300", date: targetDate))
    }

    private func makeService() -> FundNAVService {
        FundNAVService(store: FundNAVStore(fileURL: temporaryURL()))
    }

    private func temporaryURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
    }
}
