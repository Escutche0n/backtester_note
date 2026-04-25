import Foundation

public enum BNAlgorithmConstants {
    public static let navPrecision = 4
    public static let navZeroTolerance = 0.0001
    public static let xirrInitialGuess = 0.12
    public static let xirrMaxIterations = 40
    public static let xirrTolerance = 1e-7
    public static let xirrDerivativeTolerance = 1e-6
    public static let daysPerYear = 365.0
    public static let tradingDaysPerYear = 252.0

    public static func roundedNAVValue(_ value: Double) -> Double {
        guard value.isFinite else { return value }
        let scale = pow(10.0, Double(navPrecision))
        return (value * scale).rounded() / scale
    }
}
