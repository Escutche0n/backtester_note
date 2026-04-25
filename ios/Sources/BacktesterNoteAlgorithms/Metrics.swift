import Foundation

public enum Metrics {
    public static func cagr(
        startValue: Double,
        endValue: Double,
        startDate: Date,
        endDate: Date
    ) -> Double? {
        guard startValue > 0, endValue > 0, startDate < endDate else { return nil }
        let dayCount = BNCalendar.days(from: startDate, to: endDate)
        guard dayCount > 0 else { return nil }
        return pow(endValue / startValue, BNAlgorithmConstants.daysPerYear / Double(dayCount)) - 1
    }

    public static func sharpeRatio(
        values: [Double],
        annualRiskFreeRate: Double = 0,
        daysPerYear: Double = BNAlgorithmConstants.tradingDaysPerYear
    ) -> Double? {
        guard values.count >= 3 else { return nil }

        let dailyReturns = zip(values.dropFirst(), values.dropLast()).compactMap { current, previous -> Double? in
            guard previous > 0, current > 0 else { return nil }
            return current / previous - 1
        }

        guard dailyReturns.count >= 2 else { return nil }
        let riskFreeDaily = annualRiskFreeRate / daysPerYear
        let excessReturns = dailyReturns.map { $0 - riskFreeDaily }
        let mean = excessReturns.reduce(0, +) / Double(excessReturns.count)
        let variance = excessReturns.reduce(0.0) { partial, value in
            partial + pow(value - mean, 2)
        } / Double(excessReturns.count - 1)

        guard variance > 0, variance.isFinite else { return nil }
        let standardDeviation = sqrt(variance)
        return (mean / standardDeviation) * sqrt(daysPerYear)
    }

    public static func calmarRatio(annualizedReturn: Double?, maxDrawdown: Double) -> Double? {
        guard let annualizedReturn,
              annualizedReturn.isFinite,
              maxDrawdown.isFinite
        else { return nil }

        let denominator = abs(maxDrawdown)
        guard denominator > BNAlgorithmConstants.navZeroTolerance else { return nil }
        return annualizedReturn / denominator
    }

    public static func maxDrawdown(values: [Double]) -> Double {
        guard let first = values.first, first > 0 else { return 0 }

        var peak = first
        var maxDrawdown = 0.0
        for value in values where value > 0 {
            peak = max(peak, value)
            maxDrawdown = min(maxDrawdown, value / peak - 1)
        }
        return maxDrawdown
    }

    public static func currentDrawdown(values: [Double]) -> Double {
        guard let last = values.last, last > 0 else { return 0 }
        let peak = values.max() ?? 0
        guard peak > 0 else { return 0 }
        return last / peak - 1
    }
}
