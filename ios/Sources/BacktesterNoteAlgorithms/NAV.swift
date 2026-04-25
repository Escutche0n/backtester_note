import Foundation

public struct NAVInput: Sendable {
    public let marketValueSeries: [(date: String, value: Double)]
    public let cashFlowByDate: [String: Double]
    public let cashFlowEventsByDate: [String: [Double]]

    public init(
        marketValueSeries: [(date: String, value: Double)],
        cashFlowByDate: [String: Double] = [:],
        cashFlowEventsByDate: [String: [Double]] = [:]
    ) {
        self.marketValueSeries = marketValueSeries
        self.cashFlowByDate = cashFlowByDate
        self.cashFlowEventsByDate = cashFlowEventsByDate
    }
}

public struct NAVPoint: Equatable, Sendable {
    public let date: Date
    public let dateKey: String
    public let nav: Double
    public let returnRate: Double
}

public enum NAVLedgerStatus: String, Equatable, Sendable {
    case okNoCashFlow = "ok_no_cash_flow"
    case okWithCashFlow = "ok_with_cash_flow"
    case segmentStart = "segment_start"
    case segmentResetInvalidPreFlowMarketValue = "segment_reset_invalid_pre_flow_market_value"
    case segmentResetInvalidPreFlowNAV = "segment_reset_invalid_pre_flow_nav"
    case segmentResetInvalidFinalNAV = "segment_reset_invalid_final_nav"
    case segmentEndZeroPosition = "segment_end_zero_position"
    case skipCashFlowWithoutPosition = "skip_cash_flow_without_position"
    case skipEmpty = "skip_empty"
}

public struct NAVLedgerRow: Equatable, Sendable {
    public let date: Date
    public let dateKey: String
    public let endingMarketValue: Double
    public let externalCashFlow: Double
    public let previousShares: Double?
    public let preFlowMarketValue: Double?
    public let preFlowNAV: Double?
    public let finalShares: Double?
    public let finalNAV: Double?
    public let status: NAVLedgerStatus
}

public struct NAVCalculationResult: Equatable, Sendable {
    public let points: [NAVPoint]
    public let ledgerRows: [NAVLedgerRow]
}

public enum NAVCalculator {
    public static func calculate(_ input: NAVInput) -> NAVCalculationResult {
        var nav = 1.0
        var shares: Double?
        var previousEndingValue: Double?
        var points: [NAVPoint] = []
        var ledgerRows: [NAVLedgerRow] = []

        for item in input.marketValueSeries.sorted(by: { $0.date < $1.date }) {
            guard let date = BNCalendar.date(from: item.date), item.value.isFinite else {
                continue
            }

            let endingValue = rounded(max(item.value, 0))
            let cashFlow = rounded(input.cashFlowByDate[item.date] ?? 0)
            let previousShares = shares

            guard endingValue > BNAlgorithmConstants.navZeroTolerance else {
                let status: NAVLedgerStatus = abs(cashFlow) >= BNAlgorithmConstants.navZeroTolerance
                    ? .skipCashFlowWithoutPosition
                    : .skipEmpty
                ledgerRows.append(
                    NAVLedgerRow(
                        date: date,
                        dateKey: item.date,
                        endingMarketValue: endingValue,
                        externalCashFlow: cashFlow,
                        previousShares: previousShares,
                        preFlowMarketValue: nil,
                        preFlowNAV: nil,
                        finalShares: shares,
                        finalNAV: shares == nil ? nil : nav,
                        status: status
                    )
                )
                if previousShares != nil {
                    shares = nil
                    previousEndingValue = nil
                    ledgerRows[ledgerRows.count - 1] = NAVLedgerRow(
                        date: date,
                        dateKey: item.date,
                        endingMarketValue: endingValue,
                        externalCashFlow: cashFlow,
                        previousShares: previousShares,
                        preFlowMarketValue: nil,
                        preFlowNAV: nil,
                        finalShares: nil,
                        finalNAV: nil,
                        status: .segmentEndZeroPosition
                    )
                }
                continue
            }

            if shares == nil
                || (shares ?? 0) <= BNAlgorithmConstants.navZeroTolerance
                || previousEndingValue == nil
                || (previousEndingValue ?? 0) <= BNAlgorithmConstants.navZeroTolerance {
                nav = 1.0
                shares = rounded(endingValue)
                previousEndingValue = endingValue
                points.append(NAVPoint(date: date, dateKey: item.date, nav: 1.0, returnRate: 0))
                ledgerRows.append(
                    NAVLedgerRow(
                        date: date,
                        dateKey: item.date,
                        endingMarketValue: endingValue,
                        externalCashFlow: cashFlow,
                        previousShares: previousShares,
                        preFlowMarketValue: nil,
                        preFlowNAV: nil,
                        finalShares: shares,
                        finalNAV: nav,
                        status: .segmentStart
                    )
                )
                continue
            }

            let previousValueAfterFlow = previousEndingValue ?? 0
            let snapshotTotalValue = rounded(endingValue - cashFlow)
            guard previousValueAfterFlow > BNAlgorithmConstants.navZeroTolerance else {
                previousEndingValue = endingValue
                ledgerRows.append(
                    NAVLedgerRow(
                        date: date,
                        dateKey: item.date,
                        endingMarketValue: endingValue,
                        externalCashFlow: cashFlow,
                        previousShares: previousShares,
                        preFlowMarketValue: snapshotTotalValue,
                        preFlowNAV: nav,
                        finalShares: shares,
                        finalNAV: nav,
                        status: .segmentResetInvalidPreFlowMarketValue
                    )
                )
                continue
            }

            let dailyReturn = rounded((snapshotTotalValue - previousValueAfterFlow) / previousValueAfterFlow)
            let nextNAV = rounded(nav * (1 + dailyReturn))
            guard nextNAV > 0, nextNAV.isFinite else {
                previousEndingValue = endingValue
                ledgerRows.append(
                    NAVLedgerRow(
                        date: date,
                        dateKey: item.date,
                        endingMarketValue: endingValue,
                        externalCashFlow: cashFlow,
                        previousShares: previousShares,
                        preFlowMarketValue: snapshotTotalValue,
                        preFlowNAV: nav,
                        finalShares: shares,
                        finalNAV: nil,
                        status: .segmentResetInvalidFinalNAV
                    )
                )
                continue
            }

            nav = nextNAV
            if abs(cashFlow) >= BNAlgorithmConstants.navZeroTolerance {
                let deltaShares = rounded(cashFlow / nav)
                shares = rounded((shares ?? 0) + deltaShares)
            }

            previousEndingValue = endingValue
            points.append(NAVPoint(date: date, dateKey: item.date, nav: nav, returnRate: nav - 1))
            ledgerRows.append(
                NAVLedgerRow(
                    date: date,
                    dateKey: item.date,
                    endingMarketValue: endingValue,
                    externalCashFlow: cashFlow,
                    previousShares: previousShares,
                    preFlowMarketValue: snapshotTotalValue,
                    preFlowNAV: nav,
                    finalShares: shares,
                    finalNAV: nav,
                    status: abs(cashFlow) >= BNAlgorithmConstants.navZeroTolerance ? .okWithCashFlow : .okNoCashFlow
                )
            )
        }

        return NAVCalculationResult(points: points, ledgerRows: ledgerRows)
    }

    private static func rounded(_ value: Double) -> Double {
        BNAlgorithmConstants.roundedNAVValue(value)
    }
}
