// ABOUTME: AppIntent definitions for interactive widget buttons (macOS 15+).
// ABOUTME: Handles toggling between price types (market/all-in) and resolutions (hourly/quarter-hourly).

import AppIntents
import WidgetKit

/// Intent to toggle the price type between market and all-in
struct TogglePriceTypeIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Price Type"
    static var description = IntentDescription("Switch between market price and all-in price")

    func perform() async throws -> some IntentResult {
        let current = WidgetPreferences.shared.priceType
        let next: PriceType = (current == .market) ? .allIn : .market
        WidgetPreferences.shared.priceType = next
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

/// Intent to toggle the resolution between hourly and quarter-hourly
struct ToggleResolutionIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Resolution"
    static var description = IntentDescription("Switch between hourly and quarter-hourly prices")

    func perform() async throws -> some IntentResult {
        let current = WidgetPreferences.shared.resolution
        let next: PriceResolution = (current == .hourly) ? .quarterHourly : .hourly
        WidgetPreferences.shared.resolution = next
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

/// Manages widget preferences stored in UserDefaults (shared via App Group).
/// UserDefaults is thread-safe, so @unchecked Sendable is appropriate here.
final class WidgetPreferences: @unchecked Sendable {
    static let shared = WidgetPreferences()

    private let defaults: UserDefaults

    private init() {
        // Use the shared App Group defaults if available, fall back to standard
        self.defaults = UserDefaults(suiteName: Constants.appGroupIdentifier) ?? .standard
    }

    /// The currently selected price type
    var priceType: PriceType {
        get {
            guard let raw = defaults.string(forKey: Constants.UserDefaultsKeys.priceType),
                  let type = PriceType(rawValue: raw) else {
                return .allIn
            }
            return type
        }
        set {
            defaults.set(newValue.rawValue, forKey: Constants.UserDefaultsKeys.priceType)
        }
    }

    /// The currently selected resolution
    var resolution: PriceResolution {
        get {
            guard let raw = defaults.string(forKey: Constants.UserDefaultsKeys.resolution),
                  let res = PriceResolution(rawValue: raw) else {
                return .hourly
            }
            return res
        }
        set {
            defaults.set(newValue.rawValue, forKey: Constants.UserDefaultsKeys.resolution)
        }
    }
}
