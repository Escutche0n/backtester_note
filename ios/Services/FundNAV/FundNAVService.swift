import Combine
import Foundation

@MainActor
final class FundNAVService: ObservableObject {
    @Published private(set) var records: [FundDailyNAVRecord] = []
    @Published private(set) var loadError: Error?

    private let store: any FundNAVStoring

    init(store: (any FundNAVStoring)? = nil) {
        if let store {
            self.store = store
        } else {
            do {
                self.store = try FundNAVStore.defaultStore()
            } catch {
                fatalError("Fund NAV store unavailable: \(error.localizedDescription)")
            }
        }

        do {
            records = Self.sorted(try self.store.load())
        } catch {
            loadError = error
            records = []
        }
    }

    func upsert(
        code: String,
        date: Date,
        nav: Decimal,
        allowOverwriteAfterLoadFailure: Bool = false
    ) throws -> FundDailyNAVRecord {
        if loadError != nil && !allowOverwriteAfterLoadFailure {
            throw FundNAVError.storeLoadFailed
        }

        let record = try makeRecord(code: code, date: date, nav: nav)
        var nextRecords = records

        if let index = nextRecords.firstIndex(where: {
            FundNAVRecordKey.matches($0, code: record.code, date: record.date)
        }) {
            nextRecords[index] = record
        } else {
            nextRecords.append(record)
        }

        let sortedRecords = Self.sorted(nextRecords)
        try store.save(sortedRecords)
        records = sortedRecords
        loadError = nil
        return record
    }

    func records(for code: String) -> [FundDailyNAVRecord] {
        let normalizedCode = FundNAVRecordKey.normalizedCode(code)
        return records.filter { $0.code == normalizedCode }
    }

    func nav(for code: String, on date: Date) -> FundDailyNAVRecord? {
        records.first { FundNAVRecordKey.matches($0, code: code, date: date) }
    }

    func latestNAV(onOrBefore date: Date, for code: String) -> FundDailyNAVRecord? {
        let normalizedCode = FundNAVRecordKey.normalizedCode(code)
        let dateKey = ImportDateFormatter.dayString(date)

        return records
            .filter { $0.code == normalizedCode && $0.dateKey <= dateKey }
            .sorted { $0.date > $1.date }
            .first
    }

    func observations(for code: String) -> [FundNAVObservation] {
        records(for: code).map {
            FundNAVObservation(record: $0, credibility: .confirmed)
        }
    }

    func latestObservation(onOrBefore date: Date, for code: String) -> FundNAVObservation? {
        latestNAV(onOrBefore: date, for: code).map {
            FundNAVObservation(record: $0, credibility: .confirmed)
        }
    }

    @discardableResult
    func delete(
        code: String,
        date: Date,
        allowOverwriteAfterLoadFailure: Bool = false
    ) throws -> Bool {
        if loadError != nil && !allowOverwriteAfterLoadFailure {
            throw FundNAVError.storeLoadFailed
        }

        let nextRecords = records.filter {
            !FundNAVRecordKey.matches($0, code: code, date: date)
        }
        guard nextRecords.count != records.count else {
            return false
        }

        let sortedRecords = Self.sorted(nextRecords)
        try store.save(sortedRecords)
        records = sortedRecords
        loadError = nil
        return true
    }

    private func makeRecord(code: String, date: Date, nav: Decimal) throws -> FundDailyNAVRecord {
        let normalizedCode = FundNAVRecordKey.normalizedCode(code)
        guard !normalizedCode.isEmpty else {
            throw FundNAVError.invalidCode
        }

        let roundedNAV = FundNAVDecimal.rounded(nav)
        guard roundedNAV > 0 else {
            throw FundNAVError.nonPositiveNAV
        }

        return FundDailyNAVRecord(code: normalizedCode, date: date, nav: roundedNAV)
    }

    private static func sorted(_ records: [FundDailyNAVRecord]) -> [FundDailyNAVRecord] {
        records.sorted {
            if $0.code == $1.code { return $0.date < $1.date }
            return $0.code < $1.code
        }
    }
}
