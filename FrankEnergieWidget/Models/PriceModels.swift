// ABOUTME: Data models representing the Frank Energie GraphQL API response for market prices.
// ABOUTME: Includes Codable structs for JSON decoding and computed properties for display formatting.

import Foundation

/// Top-level API response wrapper
struct MarketPricesResponse: Codable, Sendable {
    let data: MarketPricesData?
    let errors: [GraphQLError]?
}

struct GraphQLError: Codable, Sendable {
    let message: String
}

struct MarketPricesData: Codable, Sendable {
    let marketPrices: MarketPrices
}

/// Contains all market price information for a given date and resolution
struct MarketPrices: Codable, Sendable {
    let averageElectricityPrices: AverageElectricityPrices
    let electricityPrices: [ElectricityPrice]
    let gasPrices: [GasPrice]
}

/// Average electricity price summary for the day
struct AverageElectricityPrices: Codable, Sendable {
    let averageMarketPrice: Double
    let averageMarketPricePlus: Double
    let averageAllInPrice: Double
    let perUnit: String
    let isWeighted: Bool
}

/// A single electricity price entry for a time slot
struct ElectricityPrice: Codable, Sendable, Identifiable {
    let from: String
    let till: String
    let resolution: String
    let marketPrice: Double
    let marketPriceTax: Double
    let sourcingMarkupPrice: Double
    let energyTaxPrice: Double
    let marketPricePlus: Double
    let allInPrice: Double
    let perUnit: String

    var id: String { from }

    /// Parse the "from" timestamp into a Date
    var fromDate: Date? {
        ISO8601DateFormatter.shared.date(from: from)
    }

    /// Parse the "till" timestamp into a Date
    var tillDate: Date? {
        ISO8601DateFormatter.shared.date(from: till)
    }

    /// Get the price value based on the selected price type
    func price(for type: PriceType) -> Double {
        switch type {
        case .market: return marketPrice
        case .allIn: return allInPrice
        }
    }

    /// Hour of the day in the Netherlands timezone (0-23)
    var localHour: Int? {
        guard let date = fromDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents(in: Constants.netherlandsTimeZone, from: date)
        return components.hour
    }

    /// Fractional hour (e.g., 14.25 for 14:15) in the Netherlands timezone
    var localFractionalHour: Double? {
        guard let date = fromDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents(in: Constants.netherlandsTimeZone, from: date)
        guard let hour = components.hour, let minute = components.minute else { return nil }
        return Double(hour) + Double(minute) / 60.0
    }
}

/// A single gas price entry for a time slot
struct GasPrice: Codable, Sendable, Identifiable {
    let from: String
    let till: String
    let resolution: String
    let marketPrice: Double
    let marketPriceTax: Double
    let sourcingMarkupPrice: Double
    let energyTaxPrice: Double
    let marketPricePlus: Double
    let allInPrice: Double
    let perUnit: String

    var id: String { from }

    /// Parse the "from" timestamp into a Date
    var fromDate: Date? {
        ISO8601DateFormatter.shared.date(from: from)
    }

    /// Get the price value based on the selected price type
    func price(for type: PriceType) -> Double {
        switch type {
        case .market: return marketPrice
        case .allIn: return allInPrice
        }
    }
}

/// Snapshot of price data used by the widget for rendering
struct PriceSnapshot: Sendable {
    let electricityPrices: [ElectricityPrice]
    let gasPrices: [GasPrice]
    let averageElectricity: AverageElectricityPrices
    let priceType: PriceType
    let resolution: PriceResolution
    let fetchDate: Date

    /// The current electricity price based on the current time
    var currentElectricityPrice: ElectricityPrice? {
        let now = Date()
        return electricityPrices.first { entry in
            guard let from = entry.fromDate, let till = entry.tillDate else { return false }
            return now >= from && now < till
        }
    }

    /// Gas price before 06:00 (first entry of the day, typically covers 00:00-06:00 in NL)
    var gasPriceBefore6: GasPrice? {
        gasPrices.first { entry in
            guard let date = entry.fromDate else { return false }
            let components = Calendar.current.dateComponents(in: Constants.netherlandsTimeZone, from: date)
            return (components.hour ?? 0) < 6
        }
    }

    /// Gas price after 06:00
    var gasPriceAfter6: GasPrice? {
        gasPrices.first { entry in
            guard let date = entry.fromDate else { return false }
            let components = Calendar.current.dateComponents(in: Constants.netherlandsTimeZone, from: date)
            return (components.hour ?? 0) >= 6
        }
    }

    /// The price range for scaling the chart
    var priceRange: ClosedRange<Double> {
        let prices = electricityPrices.map { $0.price(for: priceType) }
        let minPrice = min(0, prices.min() ?? 0)
        let maxPrice = prices.max() ?? 0.30
        return minPrice...maxPrice
    }

    /// Current fractional hour (0.0 - 24.0) in Netherlands timezone
    var currentFractionalHour: Double {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents(in: Constants.netherlandsTimeZone, from: now)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        return Double(hour) + Double(minute) / 60.0
    }

    /// Formatted average electricity price string
    var formattedAveragePrice: String {
        let price: Double
        switch priceType {
        case .market: price = averageElectricity.averageMarketPrice
        case .allIn: price = averageElectricity.averageAllInPrice
        }
        return PriceFormatter.format(price)
    }
}

/// Utility for formatting prices in European style (comma as decimal separator)
enum PriceFormatter {
    private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 3
        f.maximumFractionDigits = 3
        f.decimalSeparator = ","
        f.groupingSeparator = "."
        return f
    }()

    /// Format a price value like "0,241"
    static func format(_ value: Double) -> String {
        formatter.string(from: NSNumber(value: value)) ?? "0,000"
    }

    /// Format a price with euro sign like "€ 0,241"
    static func formatWithEuro(_ value: Double) -> String {
        "€ \(format(value))"
    }
}

// MARK: - ISO8601 Date Parsing

extension ISO8601DateFormatter {
    /// Shared formatter that handles the Frank Energie API date format (with milliseconds)
    static let shared: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
