// ABOUTME: Color palette and styling constants for the Frank Energie widget.
// ABOUTME: Provides adaptive colors that switch between dark mode (primary) and light mode.

import SwiftUI

/// Color palette for the widget, adapting to the system color scheme
enum WidgetTheme {

    // MARK: - Chart Colors

    /// The main chart line color (Frank Energie amber/orange)
    static let chartLine = Color(hex: "F5A623")

    /// The vertical "now" time marker
    static func timeMarker(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark: return Color.white.opacity(0.25)
        case .light: return Color(hex: "D1D5DB")
        @unknown default: return Color.white.opacity(0.25)
        }
    }

    /// Chart grid lines
    static func gridLine(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark: return Color(hex: "1F2937")
        case .light: return Color(hex: "E5E7EB")
        @unknown default: return Color(hex: "1F2937")
        }
    }

    // MARK: - Background

    /// Widget background color
    static func background(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark: return Color(hex: "141821")
        case .light: return Color.white
        @unknown default: return Color(hex: "141821")
        }
    }

    /// Secondary background (for toggle button groups)
    static func secondaryBackground(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark: return Color(hex: "1F2937")
        case .light: return Color(hex: "F3F4F6")
        @unknown default: return Color(hex: "1F2937")
        }
    }

    // MARK: - Text Colors

    /// Primary text (large price values, titles)
    static func primaryText(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark: return Color.white
        case .light: return Color(hex: "111827")
        @unknown default: return Color.white
        }
    }

    /// Secondary text (axis labels, summary text)
    static func secondaryText(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark: return Color(hex: "9CA3AF")
        case .light: return Color(hex: "6B7280")
        @unknown default: return Color(hex: "9CA3AF")
        }
    }

    /// Muted text (less important labels)
    static func mutedText(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark: return Color(hex: "6B7280")
        case .light: return Color(hex: "9CA3AF")
        @unknown default: return Color(hex: "6B7280")
        }
    }

    // MARK: - Toggle Button Colors

    /// Active toggle button background
    static func toggleActive(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark: return Color(hex: "1E3A5F")
        case .light: return Color(hex: "1B2B4B")
        @unknown default: return Color(hex: "1E3A5F")
        }
    }

    /// Active toggle text color
    static let toggleActiveText = Color.white

    /// Inactive toggle button border
    static func toggleInactiveBorder(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark: return Color(hex: "4B5563")
        case .light: return Color(hex: "D1D5DB")
        @unknown default: return Color(hex: "4B5563")
        }
    }

    /// Inactive toggle text color
    static func toggleInactiveText(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark: return Color(hex: "9CA3AF")
        case .light: return Color(hex: "4B5563")
        @unknown default: return Color(hex: "9CA3AF")
        }
    }

    // MARK: - Price Level Indicators

    /// Color indicating a low (cheap) price
    static let priceLow = Color(hex: "10B981")

    /// Color indicating a normal/medium price
    static let priceMedium = Color(hex: "F5A623")

    /// Color indicating a high (expensive) price
    static let priceHigh = Color(hex: "EF4444")

    /// Determine price level color based on where the current price falls in the day's range
    static func priceLevel(current: Double, range: ClosedRange<Double>) -> Color {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return priceMedium }

        let normalized = (current - range.lowerBound) / span
        if normalized < 0.33 {
            return priceLow
        } else if normalized < 0.66 {
            return priceMedium
        } else {
            return priceHigh
        }
    }
}


