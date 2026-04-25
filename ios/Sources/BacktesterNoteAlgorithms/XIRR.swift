import Foundation

public struct CashFlow: Equatable, Sendable {
    public let date: Date
    public let amount: Double

    public init(date: Date, amount: Double) {
        self.date = date
        self.amount = amount
    }
}

public enum XIRR {
    public static func calculate(_ cashFlows: [CashFlow]) -> Double? {
        guard cashFlows.count >= 2 else { return nil }

        let sorted = cashFlows.sorted { $0.date < $1.date }
        guard let baseDate = sorted.first?.date else { return nil }

        func yearsSinceBase(_ date: Date) -> Double {
            date.timeIntervalSince(baseDate) / 86_400.0 / BNAlgorithmConstants.daysPerYear
        }

        func npv(rate: Double) -> Double? {
            guard rate > -1 else { return nil }
            let value = sorted.reduce(0.0) { partial, flow in
                let years = yearsSinceBase(flow.date)
                return partial + flow.amount / pow(1 + rate, years)
            }
            return value.isFinite ? value : nil
        }

        func derivative(rate: Double) -> Double? {
            guard rate > -1 else { return nil }
            let value = sorted.reduce(0.0) { partial, flow in
                let years = yearsSinceBase(flow.date)
                guard years != 0 else { return partial }
                return partial - years * flow.amount / pow(1 + rate, years + 1)
            }
            return value.isFinite ? value : nil
        }

        var rate = BNAlgorithmConstants.xirrInitialGuess
        for _ in 0..<BNAlgorithmConstants.xirrMaxIterations {
            guard let value = npv(rate: rate),
                  let slope = derivative(rate: rate),
                  abs(slope) > BNAlgorithmConstants.xirrDerivativeTolerance
            else { break }

            let next = rate - value / slope
            guard next.isFinite else { return nil }
            if abs(next - rate) < BNAlgorithmConstants.xirrTolerance {
                return next
            }
            rate = next
        }

        return rate.isFinite ? rate : nil
    }
}
