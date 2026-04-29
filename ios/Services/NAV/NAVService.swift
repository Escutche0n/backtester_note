import BacktesterNoteAlgorithms
import Foundation

struct AccountNAVSeries: Equatable, Sendable {
    let points: [AccountNAVPoint]
    let missingValuationDateKeys: [String]
    let flowOnlyDateKeys: [String]

    var nonConfirmedStates: [NAVCredibility] {
        var states = points.map(\.credibility).filter { $0 != .confirmed }
        if !flowOnlyDateKeys.isEmpty {
            states.append(.flowOnly)
        }
        return Array(Set(states)).sorted { $0.rawValue < $1.rawValue }
    }
}

struct AccountNAVPoint: Equatable, Sendable {
    let date: Date
    let dateKey: String
    let returnPercent: Double
    let credibility: NAVCredibility
}

enum NAVService {
    static func accountSeries(
        for account: PortfolioAccount,
        fundNAVRecords: [FundDailyNAVRecord]
    ) -> AccountNAVSeries {
        guard let baseline = account.snapshots.first(where: \.isBaseline) else {
            return AccountNAVSeries(points: [], missingValuationDateKeys: [], flowOnlyDateKeys: [])
        }

        let baselineDate = ImportDateFormatter.calendar.startOfDay(for: baseline.date)
        let baselineKey = ImportDateFormatter.dayString(baselineDate)
        let navByCodeDate = fundNAVRecords.reduce(into: [String: [String: FundDailyNAVRecord]]()) { result, record in
            result[record.code, default: [:]][record.dateKey] = record
        }
        let flowDatesWithoutValuation = Array(Set(unresolvedFlowDateKeys(
            account: account,
            baselineDate: baselineDate,
            navByCodeDate: navByCodeDate
        )))
        let cutoffDate = flowDatesWithoutValuation
            .compactMap(ImportDateFormatter.parseDay)
            .min()

        var candidateKeys = Set([baselineKey])
        for records in navByCodeDate.values {
            for dateKey in records.keys where dateKey >= baselineKey {
                if let cutoffDate, let date = ImportDateFormatter.parseDay(dateKey), date >= cutoffDate {
                    continue
                }
                candidateKeys.insert(dateKey)
            }
        }

        var cashFlowByDate: [String: Double] = [:]
        var credibilityByDate: [String: NAVCredibility] = [:]
        var missingValuationDateKeys: [String] = []
        let marketValues = candidateKeys.sorted().compactMap { dateKey -> (date: String, value: Double)? in
            guard let date = ImportDateFormatter.parseDay(dateKey) else { return nil }
            let shares = sharesByCode(on: date, baseline: baseline, flows: account.flows)
            let activeCodes = shares.filter { $0.value > BNAlgorithmConstants.navZeroTolerance }.map(\.key)
            let officialValue = officialMarketValue(
                activeCodes: activeCodes,
                sharesByCode: shares,
                dateKey: dateKey,
                navByCodeDate: navByCodeDate
            )

            cashFlowByDate[dateKey] = account.flows
                .filter { ImportDateFormatter.dayString($0.date) == dateKey }
                .reduce(0) { $0 + netInput(for: $1) }

            if let officialValue {
                credibilityByDate[dateKey] = .confirmed
                return (dateKey, officialValue)
            }

            if dateKey == baselineKey {
                credibilityByDate[dateKey] = .snapshotOnly
                return (dateKey, baseline.holdings.reduce(0) { $0 + $1.value })
            }

            missingValuationDateKeys.append(dateKey)
            return nil
        }

        let calculated = NAVCalculator.calculate(
            NAVInput(marketValueSeries: marketValues, cashFlowByDate: cashFlowByDate)
        )
        let points = calculated.points.map { point in
            AccountNAVPoint(
                date: point.date,
                dateKey: point.dateKey,
                returnPercent: point.returnRate * 100,
                credibility: credibilityByDate[point.dateKey] ?? .confirmed
            )
        }

        return AccountNAVSeries(
            points: points,
            missingValuationDateKeys: missingValuationDateKeys.sorted(),
            flowOnlyDateKeys: flowDatesWithoutValuation.sorted()
        )
    }

    private static func officialMarketValue(
        activeCodes: [String],
        sharesByCode: [String: Double],
        dateKey: String,
        navByCodeDate: [String: [String: FundDailyNAVRecord]]
    ) -> Double? {
        guard !activeCodes.isEmpty else { return nil }

        var total = 0.0
        for code in activeCodes {
            guard let record = navByCodeDate[code]?[dateKey] else {
                return nil
            }
            total += (sharesByCode[code] ?? 0) * NSDecimalNumber(decimal: record.nav).doubleValue
        }
        return total
    }

    private static func unresolvedFlowDateKeys(
        account: PortfolioAccount,
        baselineDate: Date,
        navByCodeDate: [String: [String: FundDailyNAVRecord]]
    ) -> [String] {
        account.flows.compactMap { flow in
            let date = ImportDateFormatter.calendar.startOfDay(for: flow.date)
            guard date > baselineDate else { return nil }

            let dateKey = ImportDateFormatter.dayString(date)
            let shares = sharesByCode(on: date, baseline: account.snapshots.first(where: \.isBaseline), flows: account.flows)
            let activeCodes = shares.filter { $0.value > BNAlgorithmConstants.navZeroTolerance }.map(\.key)
            return officialMarketValue(
                activeCodes: activeCodes,
                sharesByCode: shares,
                dateKey: dateKey,
                navByCodeDate: navByCodeDate
            ) == nil ? dateKey : nil
        }
    }

    private static func sharesByCode(
        on date: Date,
        baseline: PortfolioSnapshot?,
        flows: [PortfolioFlow]
    ) -> [String: Double] {
        var shares = Dictionary(uniqueKeysWithValues: (baseline?.holdings ?? []).map { ($0.code, $0.shares) })
        let baselineDate = baseline.map { ImportDateFormatter.calendar.startOfDay(for: $0.date) }
        for flow in flows.sorted(by: { $0.date < $1.date }) where flow.date <= date {
            let flowDate = ImportDateFormatter.calendar.startOfDay(for: flow.date)
            if let baselineDate, flowDate <= baselineDate {
                continue
            }
            shares[flow.code, default: 0] += shareDelta(for: flow)
        }
        return shares
    }

    private static func shareDelta(for flow: PortfolioFlow) -> Double {
        switch flow.type {
        case .buy, .transferIn:
            flow.shares
        case .sell, .transferOut:
            -flow.shares
        case .dividend:
            flow.shares
        }
    }

    private static func netInput(for flow: PortfolioFlow) -> Double {
        switch flow.type {
        case .buy, .transferIn:
            flow.amount
        case .sell, .transferOut:
            -flow.amount
        case .dividend:
            flow.shares == 0 ? -flow.amount : 0
        }
    }
}
