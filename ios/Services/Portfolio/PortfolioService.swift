import Combine
import Foundation

@MainActor
final class PortfolioService: ObservableObject {
    @Published private(set) var accounts: [PortfolioAccount] = []
    @Published private(set) var lastCommitSummary: PortfolioCommitSummary?
    @Published private(set) var loadError: Error?

    let store: PortfolioFileStore

    init(store: PortfolioFileStore? = nil) {
        if let store {
            self.store = store
        } else {
            do {
                self.store = try PortfolioFileStore.defaultStore()
            } catch {
                fatalError("Portfolio store unavailable: \(error.localizedDescription)")
            }
        }

        do {
            accounts = try self.store.load()
        } catch {
            loadError = error
            accounts = []
        }
    }

    var currentAccount: PortfolioAccount? {
        accounts.sorted { $0.accountID < $1.accountID }.first
    }

    func previewCommit(_ preview: ImportPreview) throws -> PortfolioCommitPlan {
        let result = try buildCommitResult(from: preview)
        return PortfolioCommitPlan(summary: result.summary, hasStoreLoadError: loadError != nil)
    }

    func commit(_ preview: ImportPreview, allowOverwriteAfterLoadFailure: Bool = false) throws -> PortfolioCommitSummary {
        if loadError != nil && !allowOverwriteAfterLoadFailure {
            throw PortfolioError.storeLoadFailed
        }

        let result = try buildCommitResult(from: preview)
        accounts = result.accounts.sorted { $0.accountID < $1.accountID }
        try store.save(accounts)
        loadError = nil
        lastCommitSummary = result.summary
        return result.summary
    }

    private func buildCommitResult(from preview: ImportPreview) throws -> (accounts: [PortfolioAccount], summary: PortfolioCommitSummary) {
        guard preview.canCommit else {
            throw PortfolioError.importHasFatalIssues
        }
        guard let document = preview.document else {
            throw PortfolioError.missingDocument
        }

        var nextAccounts = accounts
        var summary = PortfolioCommitSummary(
            insertedSnapshots: 0,
            updatedSnapshots: 0,
            skippedFlows: 0,
            insertedFlows: 0,
            baselineMoved: false,
            oldBaselineDate: nil,
            newBaselineDate: nil
        )

        for incoming in document.accounts {
            try merge(incoming, into: &nextAccounts, summary: &summary)
        }

        return (nextAccounts, summary)
    }

    func deleteBaselineSnapshot() throws {
        throw PortfolioError.cannotDeleteBaseline
    }

    private func merge(
        _ incoming: ImportAccount,
        into accounts: inout [PortfolioAccount],
        summary: inout PortfolioCommitSummary
    ) throws {
        if let index = accounts.firstIndex(where: { $0.accountID == incoming.accountID }) {
            try mergeExisting(incoming, into: &accounts[index], summary: &summary)
        } else {
            accounts.append(makeAccount(from: incoming))
            summary.insertedSnapshots += incoming.snapshots.count
            summary.insertedFlows += incoming.flows.count
        }
    }

    private func mergeExisting(
        _ incoming: ImportAccount,
        into account: inout PortfolioAccount,
        summary: inout PortfolioCommitSummary
    ) throws {
        guard let incomingBaseline = incoming.snapshots.first(where: \.isBaseline),
              let existingBaseline = account.snapshots.first(where: \.isBaseline)
        else {
            throw PortfolioError.invalidBaselineState(accountID: account.accountID)
        }

        if incomingBaseline.date > existingBaseline.date {
            throw PortfolioError.baselineCannotMoveBackward(
                accountID: account.accountID,
                existing: existingBaseline.date,
                incoming: incomingBaseline.date
            )
        }

        if incomingBaseline.date < existingBaseline.date {
            summary.baselineMoved = true
            summary.oldBaselineDate = existingBaseline.date
            summary.newBaselineDate = incomingBaseline.date
            // TODO 1d/1e/1f: baselineMoved must trigger NAV, radar, and saved backtest recompute.
            for index in account.snapshots.indices {
                account.snapshots[index].isBaseline = false
            }
        }

        account.displayName = incoming.displayName
        account.currency = incoming.currency
        upsertSnapshots(incoming.snapshots, into: &account.snapshots, summary: &summary)
        appendFlows(incoming.flows, into: &account.flows, summary: &summary)
        account.snapshots.sort { $0.date < $1.date }
        account.flows.sort {
            if $0.date == $1.date { return $0.code < $1.code }
            return $0.date < $1.date
        }
    }

    private func upsertSnapshots(
        _ incoming: [ImportSnapshot],
        into snapshots: inout [PortfolioSnapshot],
        summary: inout PortfolioCommitSummary
    ) {
        for snapshot in incoming {
            let mapped = makeSnapshot(from: snapshot)
            if let index = snapshots.firstIndex(where: { $0.date == snapshot.date }) {
                snapshots[index] = mapped
                summary.updatedSnapshots += 1
            } else {
                snapshots.append(mapped)
                summary.insertedSnapshots += 1
            }
        }
    }

    private func appendFlows(
        _ incoming: [ImportFlow],
        into flows: inout [PortfolioFlow],
        summary: inout PortfolioCommitSummary
    ) {
        var existing = Set(flows.map(\.dedupeKey))
        for flow in incoming {
            let mapped = makeFlow(from: flow)
            if existing.contains(mapped.dedupeKey) {
                summary.skippedFlows += 1
            } else {
                flows.append(mapped)
                existing.insert(mapped.dedupeKey)
                summary.insertedFlows += 1
            }
        }
    }

    private func makeAccount(from importAccount: ImportAccount) -> PortfolioAccount {
        PortfolioAccount(
            accountID: importAccount.accountID,
            displayName: importAccount.displayName,
            currency: importAccount.currency,
            snapshots: importAccount.snapshots.map(makeSnapshot).sorted { $0.date < $1.date },
            flows: importAccount.flows.map(makeFlow).sorted { $0.date < $1.date },
            preferences: .defaultV1
        )
    }

    private func makeSnapshot(from importSnapshot: ImportSnapshot) -> PortfolioSnapshot {
        PortfolioSnapshot(
            date: importSnapshot.date,
            isBaseline: importSnapshot.isBaseline,
            note: importSnapshot.note,
            holdings: importSnapshot.holdings.map(makeHolding)
        )
    }

    private func makeHolding(from importHolding: ImportHolding) -> PortfolioHolding {
        let value = importHolding.value ?? (importHolding.nav ?? 0) * importHolding.shares
        let nav = importHolding.nav ?? value / importHolding.shares
        return PortfolioHolding(
            code: importHolding.code,
            name: importHolding.name,
            shares: importHolding.shares,
            value: value,
            nav: nav
        )
    }

    private func makeFlow(from importFlow: ImportFlow) -> PortfolioFlow {
        PortfolioFlow(
            date: importFlow.date,
            code: importFlow.code,
            type: PortfolioFlowType(importFlow.type),
            amount: importFlow.amount,
            shares: importFlow.shares,
            fee: importFlow.fee ?? 0,
            note: importFlow.note
        )
    }
}

private extension PortfolioFlowType {
    init(_ importType: ImportFlowType) {
        switch importType {
        case .buy:
            self = .buy
        case .sell:
            self = .sell
        case .dividend:
            self = .dividend
        case .transferIn:
            self = .transferIn
        case .transferOut:
            self = .transferOut
        }
    }
}
