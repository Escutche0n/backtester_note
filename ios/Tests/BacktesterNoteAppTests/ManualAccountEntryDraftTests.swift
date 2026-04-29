import XCTest
@testable import BacktesterNote

@MainActor
final class ManualAccountEntryDraftTests: XCTestCase {
    func testDraftProducesCommittablePreview() throws {
        let draft = makeDraft()
        let data = try draft.makeImportJSONData(now: now)
        let preview = ImportService.preview(data: data, now: now)

        XCTAssertTrue(preview.canCommit, "fatal: \(preview.fatalIssues.map(\.message))")
        XCTAssertEqual(preview.accountSummaries.first?.holdingCount, 2)
        XCTAssertEqual(preview.snapshotCount, 1)
        XCTAssertEqual(preview.flowCount, 0)
    }

    func testCommitFromDraftLandsBaselineAndHoldings() throws {
        let service = makeService()
        let draft = makeDraft()
        let data = try draft.makeImportJSONData(now: now)
        let preview = ImportService.preview(data: data, now: now)

        let summary = try service.commit(preview)

        XCTAssertEqual(summary.insertedSnapshots, 1)
        XCTAssertEqual(summary.insertedFlows, 0)
        XCTAssertFalse(summary.baselineMoved)

        let account = try XCTUnwrap(service.currentAccount)
        XCTAssertEqual(account.displayName, draft.displayName)
        let baseline = try XCTUnwrap(account.snapshots.first(where: \.isBaseline))
        XCTAssertEqual(ImportDateFormatter.dayString(baseline.date), ImportDateFormatter.dayString(draft.baselineDate))
        XCTAssertEqual(baseline.holdings.map(\.code).sorted(), ["000001", "510300"])
        let etf = try XCTUnwrap(baseline.holdings.first(where: { $0.code == "510300" }))
        XCTAssertEqual(etf.shares, 1234.56, accuracy: 0.0001)
        XCTAssertEqual(etf.value, 5500.00, accuracy: 0.0001)
    }

    func testNAVOnlyHoldingComputesValueViaImporter() throws {
        var draft = makeDraft()
        draft.holdings = [
            ManualHoldingDraft(code: "510300", name: "ETF", sharesText: "100", valueText: "", navText: "1.5")
        ]

        let data = try draft.makeImportJSONData(now: now)
        let preview = ImportService.preview(data: data, now: now)
        XCTAssertTrue(preview.canCommit, "fatal: \(preview.fatalIssues.map(\.message))")

        let service = makeService()
        _ = try service.commit(preview)
        let holding = try XCTUnwrap(service.currentAccount?.snapshots.first?.holdings.first)
        XCTAssertEqual(holding.value, 150.0, accuracy: 0.0001)
        XCTAssertEqual(holding.nav ?? 0, 1.5, accuracy: 0.0001)
    }

    func testEmptyDisplayNameRejected() {
        var draft = makeDraft()
        draft.displayName = "   "
        XCTAssertThrowsError(try draft.makeImportJSONData(now: now)) { error in
            XCTAssertEqual(error as? ManualAccountDraft.DraftError, .displayNameEmpty)
        }
    }

    func testHoldingMissingValueAndNAVRejected() {
        var draft = makeDraft()
        draft.holdings = [
            ManualHoldingDraft(code: "510300", name: "ETF", sharesText: "100", valueText: "", navText: "")
        ]
        XCTAssertThrowsError(try draft.makeImportJSONData(now: now)) { error in
            XCTAssertEqual(error as? ManualAccountDraft.DraftError, .holdingValueOrNAVMissing(code: "510300"))
        }
    }

    func testInvalidSharesRejected() {
        var draft = makeDraft()
        draft.holdings = [
            ManualHoldingDraft(code: "510300", name: "ETF", sharesText: "abc", valueText: "100", navText: "")
        ]
        XCTAssertThrowsError(try draft.makeImportJSONData(now: now)) { error in
            XCTAssertEqual(error as? ManualAccountDraft.DraftError, .holdingSharesInvalid(code: "510300"))
        }
    }

    private func makeDraft() -> ManualAccountDraft {
        var draft = ManualAccountDraft()
        draft.displayName = "主账户"
        draft.baselineDate = ImportDateFormatter.parseDay("2026-04-29")!
        draft.holdings = [
            ManualHoldingDraft(code: "510300", name: "沪深300ETF", sharesText: "1234.56", valueText: "5500.00", navText: "4.456"),
            ManualHoldingDraft(code: "000001", name: "华夏成长", sharesText: "200", valueText: "240", navText: "")
        ]
        return draft
    }

    private func makeService() -> PortfolioService {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
        return PortfolioService(store: PortfolioFileStore(fileURL: url))
    }

    private var now: Date {
        ImportDateFormatter.parseDay("2026-04-29")!
    }
}
