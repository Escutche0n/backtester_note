import Foundation

struct PortfolioFileStore: Sendable {
    var fileURL: URL

    static func defaultStore() throws -> PortfolioFileStore {
        let directory = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        .appendingPathComponent("BacktesterNote", isDirectory: true)

        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        return PortfolioFileStore(fileURL: directory.appendingPathComponent("portfolio.v1.json"))
    }

    func load() throws -> [PortfolioAccount] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)
        return try Self.decoder.decode([PortfolioAccount].self, from: data)
    }

    func save(_ accounts: [PortfolioAccount]) throws {
        let data = try Self.encoder.encode(accounts)
        try data.write(to: fileURL, options: [.atomic])
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .formatted(dayFormatter())
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dayFormatter())
        return decoder
    }

    private static func dayFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = ImportDateFormatter.calendar
        formatter.timeZone = ImportDateFormatter.calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
}
