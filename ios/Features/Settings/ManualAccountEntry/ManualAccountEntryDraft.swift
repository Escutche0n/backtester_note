import Foundation

struct ManualHoldingDraft: Identifiable, Equatable {
    let id: UUID
    var code: String
    var name: String
    var sharesText: String
    var valueText: String
    var navText: String

    init(
        id: UUID = UUID(),
        code: String = "",
        name: String = "",
        sharesText: String = "",
        valueText: String = "",
        navText: String = ""
    ) {
        self.id = id
        self.code = code
        self.name = name
        self.sharesText = sharesText
        self.valueText = valueText
        self.navText = navText
    }
}

struct ManualAccountDraft: Equatable {
    var accountID: String = "default"
    var displayName: String = "主账户"
    var currency: String = "CNY"
    var baselineDate: Date = Date()
    var note: String = ""
    var holdings: [ManualHoldingDraft] = [ManualHoldingDraft()]

    enum DraftError: LocalizedError, Equatable {
        case displayNameEmpty
        case noHoldings
        case holdingCodeEmpty(rowIndex: Int)
        case holdingSharesInvalid(code: String)
        case holdingValueOrNAVMissing(code: String)
        case holdingValueInvalid(code: String)
        case holdingNAVInvalid(code: String)

        var errorDescription: String? {
            switch self {
            case .displayNameEmpty:
                "账户名称不能为空。"
            case .noHoldings:
                "至少需要 1 条持仓。"
            case let .holdingCodeEmpty(row):
                "第 \(row + 1) 行：基金代码不能为空。"
            case let .holdingSharesInvalid(code):
                "\(code) 份额必须是大于 0 的数字。"
            case let .holdingValueOrNAVMissing(code):
                "\(code) 至少填写市值或日净值。"
            case let .holdingValueInvalid(code):
                "\(code) 市值必须是大于 0 的数字。"
            case let .holdingNAVInvalid(code):
                "\(code) 日净值必须是大于 0 的数字。"
            }
        }
    }

    func makeImportJSONData(now: Date = Date()) throws -> Data {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { throw DraftError.displayNameEmpty }
        guard !holdings.isEmpty else { throw DraftError.noHoldings }

        var holdingDicts: [[String: Any]] = []
        for (index, holding) in holdings.enumerated() {
            holdingDicts.append(try buildHoldingDict(holding, rowIndex: index))
        }

        let baselineKey = ImportDateFormatter.dayString(baselineDate)
        var snapshotDict: [String: Any] = [
            "date": baselineKey,
            "is_baseline": true,
            "holdings": holdingDicts
        ]
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedNote.isEmpty {
            snapshotDict["note"] = trimmedNote
        }

        let accountDict: [String: Any] = [
            "account_id": accountID,
            "display_name": trimmedName,
            "currency": currency,
            "snapshots": [snapshotDict],
            "flows": [Any]()
        ]

        let document: [String: Any] = [
            "schema": ImportService.schema,
            "exported_at": Self.iso8601(now),
            "source": "user_manual",
            "accounts": [accountDict]
        ]

        return try JSONSerialization.data(withJSONObject: document, options: [.sortedKeys])
    }

    private func buildHoldingDict(_ holding: ManualHoldingDraft, rowIndex: Int) throws -> [String: Any] {
        let code = holding.code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { throw DraftError.holdingCodeEmpty(rowIndex: rowIndex) }

        guard let shares = Self.parseDecimal(holding.sharesText), shares > 0 else {
            throw DraftError.holdingSharesInvalid(code: code)
        }

        let valueText = holding.valueText.trimmingCharacters(in: .whitespacesAndNewlines)
        let navText = holding.navText.trimmingCharacters(in: .whitespacesAndNewlines)

        if valueText.isEmpty && navText.isEmpty {
            throw DraftError.holdingValueOrNAVMissing(code: code)
        }

        var dict: [String: Any] = [
            "code": code,
            "name": holding.name.trimmingCharacters(in: .whitespacesAndNewlines),
            "shares": shares
        ]

        if !valueText.isEmpty {
            guard let value = Self.parseDecimal(valueText), value > 0 else {
                throw DraftError.holdingValueInvalid(code: code)
            }
            dict["value"] = value
        }

        if !navText.isEmpty {
            guard let nav = Self.parseDecimal(navText), nav > 0 else {
                throw DraftError.holdingNAVInvalid(code: code)
            }
            dict["nav"] = nav
        }

        if dict["name"] as? String == "" {
            dict["name"] = code
        }

        return dict
    }

    private static func parseDecimal(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard !trimmed.isEmpty else { return nil }
        return Double(trimmed)
    }

    private static func iso8601(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        return formatter.string(from: date)
    }
}
