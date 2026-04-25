import Foundation

struct ImportDocument: Decodable {
    let schema: String
    let exportedAt: Date
    let source: ImportSource
    let accounts: [ImportAccount]

    enum CodingKeys: String, CodingKey {
        case schema
        case exportedAt = "exported_at"
        case source
        case accounts
    }
}

enum ImportSource: String, Decodable {
    case userManual = "user_manual"
    case shortcut
    case legacyFundMVPExport = "legacy_fundmvp_export"
}

struct ImportAccount: Decodable, Identifiable {
    let accountID: String
    let displayName: String
    let currency: String
    let snapshots: [ImportSnapshot]
    let flows: [ImportFlow]

    var id: String { accountID }

    enum CodingKeys: String, CodingKey {
        case accountID = "account_id"
        case displayName = "display_name"
        case currency
        case snapshots
        case flows
    }
}

struct ImportSnapshot: Decodable, Identifiable {
    let date: Date
    let isBaseline: Bool
    let note: String?
    let holdings: [ImportHolding]

    var id: Date { date }

    enum CodingKeys: String, CodingKey {
        case date
        case isBaseline = "is_baseline"
        case note
        case holdings
    }
}

struct ImportHolding: Decodable, Identifiable {
    let code: String
    let name: String
    let shares: Double
    let value: Double?
    let nav: Double?

    var id: String { code }
}

struct ImportFlow: Decodable, Identifiable {
    let date: Date
    let code: String
    let type: ImportFlowType
    let amount: Double
    let shares: Double
    let fee: Double?
    let note: String?

    var id: String {
        "\(ImportDateFormatter.dayString(date)):\(code):\(type.rawValue):\(amount):\(shares)"
    }
}

enum ImportFlowType: String, Decodable {
    case buy
    case sell
    case dividend
    case transferIn = "transfer_in"
    case transferOut = "transfer_out"
}

struct ImportPreview: Identifiable {
    let id = UUID()
    let document: ImportDocument?
    let fatalIssues: [ImportIssue]
    let warnings: [ImportIssue]
    let accountSummaries: [ImportAccountSummary]

    var canCommit: Bool {
        fatalIssues.isEmpty && document != nil
    }

    var snapshotCount: Int {
        accountSummaries.reduce(0) { $0 + $1.snapshotCount }
    }

    var flowCount: Int {
        accountSummaries.reduce(0) { $0 + $1.flowCount }
    }
}

struct ImportAccountSummary: Identifiable {
    let id: String
    let displayName: String
    let baselineDate: Date?
    let snapshotCount: Int
    let flowCount: Int
    let holdingCount: Int
}

struct ImportIssue: Identifiable {
    enum Severity {
        case fatal
        case warning
    }

    let id = UUID()
    let severity: Severity
    let message: String
}

enum ImportDateFormatter {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        calendar.locale = Locale(identifier: "zh_CN")
        return calendar
    }()

    static func parseDay(_ value: String) -> Date? {
        dayFormatter().date(from: value)
    }

    static func parseInstant(_ value: String) -> Date? {
        isoFormatter().date(from: value)
    }

    static func dayString(_ date: Date) -> String {
        dayFormatter().string(from: date)
    }

    private static func dayFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }

    private static func isoFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }
}
