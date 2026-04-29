import XCTest
@testable import BacktesterNote

@MainActor
final class PortfolioServiceTests: XCTestCase {
    func testCommitWritesAccountAndSkipsDuplicateFlows() throws {
        let service = makeService()
        let preview = ImportService.preview(data: Self.importJSON(baseline: "2024-01-01"))

        let first = try service.commit(preview)
        XCTAssertEqual(service.accounts.count, 1)
        XCTAssertEqual(first.insertedSnapshots, 1)
        XCTAssertEqual(first.insertedFlows, 1)

        let second = try service.commit(preview)
        XCTAssertEqual(second.updatedSnapshots, 1)
        XCTAssertEqual(second.skippedFlows, 1)
        XCTAssertEqual(service.accounts.first?.flows.count, 1)
    }

    func testBaselineCannotMoveLater() throws {
        let service = makeService()
        _ = try service.commit(ImportService.preview(data: Self.importJSON(baseline: "2024-01-01")))

        let later = ImportService.preview(data: Self.importJSON(baseline: "2024-02-01"))

        XCTAssertThrowsError(try service.commit(later)) { error in
            XCTAssertEqual(error as? PortfolioError, .baselineCannotMoveBackward(
                accountID: "default",
                existing: ImportDateFormatter.parseDay("2024-01-01")!,
                incoming: ImportDateFormatter.parseDay("2024-02-01")!
            ))
        }
    }

    func testEarlierBaselineMovesOldBaselineToCheckpoint() throws {
        let service = makeService()
        _ = try service.commit(ImportService.preview(data: Self.importJSON(baseline: "2024-02-01")))

        let preview = ImportService.preview(data: Self.importJSON(baseline: "2024-01-01"))
        let plan = try service.previewCommit(preview)
        let moved = try service.commit(preview)

        XCTAssertTrue(plan.needsConfirmation)
        XCTAssertTrue(moved.baselineMoved)
        XCTAssertEqual(service.accounts.first?.snapshots.count, 2)
        XCTAssertEqual(service.accounts.first?.snapshots.filter(\.isBaseline).first?.date, ImportDateFormatter.parseDay("2024-01-01"))
    }

    func testLoadFailureRequiresExplicitOverwrite() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
        try Data("broken".utf8).write(to: url)
        let service = PortfolioService(store: PortfolioFileStore(fileURL: url))
        let preview = ImportService.preview(data: Self.importJSON(baseline: "2024-01-01"))

        let plan = try service.previewCommit(preview)

        XCTAssertTrue(plan.hasStoreLoadError)
        XCTAssertThrowsError(try service.commit(preview)) { error in
            XCTAssertEqual(error as? PortfolioError, .storeLoadFailed)
        }
        XCTAssertNoThrow(try service.commit(preview, allowOverwriteAfterLoadFailure: true))
        XCTAssertNil(service.loadError)
    }

    func testFileStoreRoundTripsAccounts() throws {
        let service = makeService()
        let preview = ImportService.preview(data: Self.importJSON(baseline: "2024-01-01"))
        _ = try service.commit(preview)

        let reloaded = PortfolioService(store: service.store)

        XCTAssertEqual(reloaded.accounts, service.accounts)
    }

    private func makeService() -> PortfolioService {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
        return PortfolioService(store: PortfolioFileStore(fileURL: url))
    }

    private static func importJSON(baseline: String) -> Data {
        """
        {
          "schema": "backtester-note/import/v1",
          "exported_at": "2026-04-25T00:00:00+08:00",
          "source": "user_manual",
          "accounts": [{
            "account_id": "default",
            "display_name": "主账户",
            "currency": "CNY",
            "snapshots": [{
              "date": "\(baseline)",
              "is_baseline": true,
              "holdings": [{
                "code": "510300",
                "name": "沪深300ETF",
                "shares": 1000,
                "value": 4200
              }]
            }],
            "flows": [{
              "date": "\(baseline)",
              "code": "510300",
              "type": "buy",
              "amount": 500,
              "shares": 100,
              "fee": 0
            }]
          }]
        }
        """.data(using: .utf8)!
    }
}
