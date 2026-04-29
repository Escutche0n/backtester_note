import Foundation

enum ImportService {
    static let schema = "backtester-note/import/v1"

    static func preview(data: Data, now: Date = Date()) -> ImportPreview {
        do {
            let document = try decoder.decode(ImportDocument.self, from: data)
            return validate(document, now: now)
        } catch {
            return ImportPreview(
                document: nil,
                fatalIssues: [
                    ImportIssue(severity: .fatal, message: "JSON 无法解析为 Backtester Note import v1：\(error.localizedDescription)")
                ],
                warnings: [],
                accountSummaries: []
            )
        }
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)

            if let day = ImportDateFormatter.parseDay(value) {
                return day
            }

            if let instant = ImportDateFormatter.parseInstant(value) {
                return instant
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date: \(value)"
            )
        }
        return decoder
    }

    private static func validate(_ document: ImportDocument, now: Date) -> ImportPreview {
        var fatalIssues: [ImportIssue] = []
        var warnings: [ImportIssue] = []

        if document.schema != schema {
            fatalIssues.append(.fatal("schema 必须是 \(schema)"))
        }

        if document.accounts.isEmpty {
            fatalIssues.append(.fatal("accounts 至少需要 1 个账户"))
        }

        for account in document.accounts {
            validate(account, now: now, fatalIssues: &fatalIssues, warnings: &warnings)
        }

        return ImportPreview(
            document: document,
            fatalIssues: fatalIssues,
            warnings: warnings,
            accountSummaries: summaries(for: document.accounts)
        )
    }

    private static func validate(
        _ account: ImportAccount,
        now: Date,
        fatalIssues: inout [ImportIssue],
        warnings: inout [ImportIssue]
    ) {
        if account.accountID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fatalIssues.append(.fatal("账户 ID 不能为空"))
        }

        let baselineSnapshots = account.snapshots.filter(\.isBaseline)
        if baselineSnapshots.count != 1 {
            fatalIssues.append(.fatal("\(account.displayName) 必须恰有 1 个 baseline snapshot"))
        }

        if let baseline = baselineSnapshots.first {
            let earliest = account.snapshots.map(\.date).min()
            if earliest != baseline.date {
                fatalIssues.append(.fatal("\(account.displayName) 的 baseline 必须是最早 snapshot"))
            }

            for flow in account.flows where flow.date < baseline.date {
                fatalIssues.append(.fatal("\(account.displayName) 有早于 baseline 的流水：\(flow.code)"))
            }
        }

        for snapshot in account.snapshots {
            validate(snapshot, accountName: account.displayName, now: now, fatalIssues: &fatalIssues, warnings: &warnings)
        }

        for flow in account.flows {
            validate(flow, accountName: account.displayName, now: now, fatalIssues: &fatalIssues, warnings: &warnings)
        }

        let duplicateKeys = Dictionary(grouping: account.flows) { flow in
            [
                account.accountID,
                flow.code,
                ImportDateFormatter.dayString(flow.date),
                flow.type.rawValue,
                String(format: "%.2f", flow.amount),
                String(format: "%.4f", flow.shares)
            ].joined(separator: ":")
        }
        .filter { $0.value.count > 1 }

        for key in duplicateKeys.keys.sorted() {
            warnings.append(.warning("疑似重复流水：\(key)"))
        }
    }

    private static func validate(
        _ snapshot: ImportSnapshot,
        accountName: String,
        now: Date,
        fatalIssues: inout [ImportIssue],
        warnings: inout [ImportIssue]
    ) {
        if snapshot.date > now {
            warnings.append(.warning("\(accountName) 有未来 snapshot 日期：\(ImportDateFormatter.dayString(snapshot.date))"))
        }

        if snapshot.holdings.isEmpty {
            fatalIssues.append(.fatal("\(accountName) 的 snapshot 至少需要 1 条持仓"))
        }

        for holding in snapshot.holdings {
            if holding.code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                fatalIssues.append(.fatal("\(accountName) 有空基金代码"))
            }
            if holding.shares <= 0 {
                fatalIssues.append(.fatal("\(holding.code) shares 必须 > 0"))
            }
            if holding.value == nil && holding.nav == nil {
                fatalIssues.append(.fatal("\(holding.code) 至少提供 value 或 nav"))
            }
            if let value = holding.value, value <= 0 {
                fatalIssues.append(.fatal("\(holding.code) value 必须 > 0"))
            }
            if let nav = holding.nav, nav <= 0 {
                fatalIssues.append(.fatal("\(holding.code) nav 必须 > 0"))
            }
        }
    }

    private static func validate(
        _ flow: ImportFlow,
        accountName: String,
        now: Date,
        fatalIssues: inout [ImportIssue],
        warnings: inout [ImportIssue]
    ) {
        if flow.date > now {
            warnings.append(.warning("\(accountName) 有未来 flow 日期：\(ImportDateFormatter.dayString(flow.date))"))
        }

        if flow.code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fatalIssues.append(.fatal("\(accountName) 有空 flow code"))
        }

        if flow.amount <= 0 {
            fatalIssues.append(.fatal("\(flow.code) amount 必须 > 0"))
        }

        switch flow.type {
        case .buy, .sell, .transferIn, .transferOut:
            if flow.shares <= 0 {
                fatalIssues.append(.fatal("\(flow.code) \(flow.type.rawValue) shares 必须 > 0"))
            }
        case .dividend:
            if flow.shares < 0 {
                fatalIssues.append(.fatal("\(flow.code) dividend shares 不能为负"))
            }
        }

        if let fee = flow.fee, fee < 0 {
            fatalIssues.append(.fatal("\(flow.code) fee 不能为负"))
        }
    }

    private static func summaries(for accounts: [ImportAccount]) -> [ImportAccountSummary] {
        accounts.map { account in
            let baselineDate = account.snapshots.first(where: \.isBaseline)?.date
            let holdingCount = account.snapshots.reduce(0) { $0 + $1.holdings.count }

            return ImportAccountSummary(
                id: account.accountID,
                displayName: account.displayName,
                baselineDate: baselineDate,
                snapshotCount: account.snapshots.count,
                flowCount: account.flows.count,
                holdingCount: holdingCount
            )
        }
    }
}

private extension ImportIssue {
    static func fatal(_ message: String) -> ImportIssue {
        ImportIssue(severity: .fatal, message: message)
    }

    static func warning(_ message: String) -> ImportIssue {
        ImportIssue(severity: .warning, message: message)
    }
}
