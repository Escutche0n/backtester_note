import Foundation

struct FundDailyNAVRecord: Codable, Identifiable, Equatable, Sendable {
    var id: String { "\(code):\(dateKey)" }
    var dateKey: String { ImportDateFormatter.dayString(date) }

    var code: String
    var date: Date
    var nav: Decimal

    init(code: String, date: Date, nav: Decimal) {
        self.code = FundNAVRecordKey.normalizedCode(code)
        self.date = ImportDateFormatter.calendar.startOfDay(for: date)
        self.nav = FundNAVDecimal.rounded(nav)
    }

    enum CodingKeys: String, CodingKey {
        case code
        case date
        case nav
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let code = try container.decode(String.self, forKey: .code)
        let date = try container.decode(Date.self, forKey: .date)
        let navValue = try container.decode(String.self, forKey: .nav)

        guard let nav = FundNAVDecimal.parse(navValue) else {
            throw DecodingError.dataCorruptedError(
                forKey: .nav,
                in: container,
                debugDescription: "NAV must be a decimal string."
            )
        }

        self.init(code: code, date: date, nav: nav)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(code, forKey: .code)
        try container.encode(date, forKey: .date)
        try container.encode(FundNAVDecimal.string(nav), forKey: .nav)
    }
}

struct FundNAVObservation: Equatable, Sendable {
    var record: FundDailyNAVRecord
    var credibility: NAVCredibility
}

enum FundNAVError: LocalizedError, Equatable {
    case invalidCode
    case nonPositiveNAV
    case storeLoadFailed

    var errorDescription: String? {
        switch self {
        case .invalidCode:
            "基金代码不能为空。"
        case .nonPositiveNAV:
            "日净值必须大于 0。"
        case .storeLoadFailed:
            "本地基金净值文件加载失败。为避免覆盖旧数据，需要用户确认后才能写入。"
        }
    }
}

enum FundNAVRecordKey {
    static func normalizedCode(_ code: String) -> String {
        code.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func matches(_ lhs: FundDailyNAVRecord, code: String, date: Date) -> Bool {
        lhs.code == normalizedCode(code)
            && lhs.dateKey == ImportDateFormatter.dayString(date)
    }
}

enum FundNAVDecimal {
    static func rounded(_ value: Decimal) -> Decimal {
        var input = value
        var output = Decimal()
        NSDecimalRound(&output, &input, 4, .plain)
        return output
    }

    static func string(_ value: Decimal) -> String {
        let number = NSDecimalNumber(decimal: rounded(value))
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = 4
        formatter.maximumFractionDigits = 4
        return formatter.string(from: number) ?? number.stringValue
    }

    static func parse(_ value: String) -> Decimal? {
        Decimal(string: value, locale: Locale(identifier: "en_US_POSIX"))
    }
}
