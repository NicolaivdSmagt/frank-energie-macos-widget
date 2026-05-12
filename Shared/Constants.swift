// ABOUTME: Shared constants used by both the host app and widget extension.
// ABOUTME: Contains API endpoint, app group identifier, and default configuration values.

import Foundation

enum Constants {
    /// Frank Energie GraphQL API endpoint (no authentication required for market prices)
    static let apiURL = URL(string: "https://frank-graphql-prod.graphcdn.app/")!

    /// App Group identifier for sharing data between app and widget extension
    static let appGroupIdentifier = "group.nl.frankenergie.widget"

    /// UserDefaults keys for widget configuration
    enum UserDefaultsKeys {
        static let priceType = "widget_price_type"
        static let resolution = "widget_resolution"
    }

    /// Widget refresh interval in minutes
    static let refreshIntervalMinutes = 15

    /// The timezone used for displaying Dutch energy prices
    static let netherlandsTimeZone = TimeZone(identifier: "Europe/Amsterdam")!
}

/// The type of price to display in the widget
enum PriceType: String, CaseIterable, Sendable {
    case market = "market"
    case allIn = "allIn"

    var displayName: String {
        switch self {
        case .market: return "Marktprijs"
        case .allIn: return "All-in prijs"
        }
    }
}

/// The time resolution for price data
enum PriceResolution: String, CaseIterable, Sendable {
    case hourly = "PT60M"
    case quarterHourly = "PT15M"

    var displayName: String {
        switch self {
        case .hourly: return "Per uur"
        case .quarterHourly: return "Per kwartier"
        }
    }

    /// Number of data points expected for a full day
    var expectedDataPoints: Int {
        switch self {
        case .hourly: return 24
        case .quarterHourly: return 96
        }
    }
}
