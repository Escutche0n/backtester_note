import Foundation

struct PortfolioAccount: Codable, Identifiable, Equatable, Sendable {
    var id: String { accountID }

    let accountID: String
    var displayName: String
    var currency: String
    var snapshots: [PortfolioSnapshot]
    var flows: [PortfolioFlow]
    var preferences: PortfolioPreferences
}

struct PortfolioSnapshot: Codable, Identifiable, Equatable, Sendable {
    var id: Date { date }

    var date: Date
    var isBaseline: Bool
    var note: String?
    var holdings: [PortfolioHolding]
}

struct PortfolioHolding: Codable, Identifiable, Equatable, Sendable {
    var id: String { code }

    var code: String
    var name: String
    var shares: Double
    var value: Double
    var nav: Double?
}

struct PortfolioFlow: Codable, Identifiable, Equatable, Sendable {
    var id: String { dedupeKey }

    var date: Date
    var code: String
    var type: PortfolioFlowType
    var amount: Double
    var shares: Double
    var fee: Double
    var note: String?

    var dedupeKey: String {
        [
            ImportDateFormatter.dayString(date),
            code,
            type.rawValue,
            String(format: "%.2f", amount),
            String(format: "%.4f", shares)
        ].joined(separator: ":")
    }
}

enum PortfolioFlowType: String, Codable, Sendable {
    case buy
    case sell
    case dividend
    case transferIn = "transfer_in"
    case transferOut = "transfer_out"
}

struct PortfolioPreferences: Codable, Equatable, Sendable {
    var enabledOverviewGraphIDs: [String]?

    static let defaultV1 = PortfolioPreferences(enabledOverviewGraphIDs: nil)
}

enum NAVCredibility: String, Codable, CaseIterable, Equatable, Sendable {
    case confirmed
    case pendingReconcile = "pending_reconcile"
    case intradayEstimate = "intraday_estimate"
    case snapshotOnly = "snapshot_only"
    case flowOnly = "flow_only"
}

struct PortfolioCommitSummary: Equatable, Sendable {
    var insertedSnapshots: Int
    var updatedSnapshots: Int
    var skippedFlows: Int
    var insertedFlows: Int
    var baselineMoved: Bool
    var oldBaselineDate: Date?
    var newBaselineDate: Date?
}

struct PortfolioCommitPlan: Equatable, Sendable {
    var summary: PortfolioCommitSummary
    var hasStoreLoadError: Bool

    var needsConfirmation: Bool {
        summary.baselineMoved || hasStoreLoadError
    }
}

enum PortfolioError: LocalizedError, Equatable {
    case importHasFatalIssues
    case missingDocument
    case baselineCannotMoveBackward(accountID: String, existing: Date, incoming: Date)
    case invalidBaselineState(accountID: String)
    case storeLoadFailed
    case cannotDeleteBaseline

    var errorDescription: String? {
        switch self {
        case .importHasFatalIssues:
            "导入文件还有必须修复的问题，不能写入。"
        case .missingDocument:
            "导入预览没有可写入的文档。"
        case let .baselineCannotMoveBackward(accountID, existing, incoming):
            "账户 \(accountID) 的 baseline 只能前移，不能从 \(ImportDateFormatter.dayString(existing)) 后移到 \(ImportDateFormatter.dayString(incoming))。"
        case let .invalidBaselineState(accountID):
            "账户 \(accountID) 的 baseline 状态无效，不能写入。"
        case .storeLoadFailed:
            "本地持仓文件加载失败。为避免覆盖旧数据，需要用户确认后才能写入。"
        case .cannotDeleteBaseline:
            "baseline snapshot 不允许删除。"
        }
    }
}
