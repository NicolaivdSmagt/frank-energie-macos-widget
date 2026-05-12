// ABOUTME: Timeline provider and widget configuration for the Frank Energie macOS widget.
// ABOUTME: Handles fetching price data, generating timeline entries, and selecting the appropriate view.

import WidgetKit
import SwiftUI

/// The timeline entry containing all data needed to render the widget
struct FrankEnergieEntry: TimelineEntry {
    let date: Date
    let snapshot: PriceSnapshot
    let isPlaceholder: Bool

    /// Create a placeholder entry with sample data (used before real data loads)
    static func placeholder() -> FrankEnergieEntry {
        FrankEnergieEntry(
            date: Date(),
            snapshot: PriceSnapshot(
                electricityPrices: Self.sampleElectricityPrices(),
                gasPrices: Self.sampleGasPrices(),
                averageElectricity: AverageElectricityPrices(
                    averageMarketPrice: 0.09,
                    averageMarketPricePlus: 0.13,
                    averageAllInPrice: 0.241,
                    perUnit: "KWH",
                    isWeighted: false
                ),
                priceType: .allIn,
                resolution: .hourly,
                fetchDate: Date()
            ),
            isPlaceholder: true
        )
    }

    /// Generate sample electricity prices for placeholder/preview
    private static func sampleElectricityPrices() -> [ElectricityPrice] {
        let baseDate = Calendar.current.startOfDay(for: Date())
        let samplePrices: [Double] = [
            0.22, 0.21, 0.20, 0.21, 0.22, 0.24,
            0.26, 0.28, 0.27, 0.25, 0.22, 0.20,
            0.19, 0.18, 0.19, 0.21, 0.24, 0.28,
            0.30, 0.29, 0.27, 0.26, 0.25, 0.24
        ]

        return samplePrices.enumerated().map { index, price in
            let from = baseDate.addingTimeInterval(TimeInterval(index * 3600))
            let till = from.addingTimeInterval(3600)
            let formatter = ISO8601DateFormatter.shared
            return ElectricityPrice(
                from: formatter.string(from: from),
                till: formatter.string(from: till),
                resolution: "PT60M",
                marketPrice: price * 0.4,
                marketPriceTax: price * 0.1,
                sourcingMarkupPrice: 0.01815,
                energyTaxPrice: 0.11085,
                marketPricePlus: price * 0.55,
                allInPrice: price,
                perUnit: "KWH"
            )
        }
    }

    /// Generate sample gas prices for placeholder/preview
    private static func sampleGasPrices() -> [GasPrice] {
        let baseDate = Calendar.current.startOfDay(for: Date())
        let formatter = ISO8601DateFormatter.shared
        return [
            GasPrice(
                from: formatter.string(from: baseDate),
                till: formatter.string(from: baseDate.addingTimeInterval(6 * 3600)),
                resolution: "PT60M",
                marketPrice: 0.43,
                marketPriceTax: 0.09,
                sourcingMarkupPrice: 0.08,
                energyTaxPrice: 0.73,
                marketPricePlus: 0.60,
                allInPrice: 1.326,
                perUnit: "M3"
            ),
            GasPrice(
                from: formatter.string(from: baseDate.addingTimeInterval(6 * 3600)),
                till: formatter.string(from: baseDate.addingTimeInterval(24 * 3600)),
                resolution: "PT60M",
                marketPrice: 0.44,
                marketPriceTax: 0.09,
                sourcingMarkupPrice: 0.08,
                energyTaxPrice: 0.73,
                marketPricePlus: 0.61,
                allInPrice: 1.353,
                perUnit: "M3"
            )
        ]
    }
}

/// Provides timeline entries to WidgetKit by fetching data from the Frank Energie API
struct FrankEnergieTimelineProvider: TimelineProvider {
    typealias Entry = FrankEnergieEntry

    private let api = FrankEnergieAPI()

    func placeholder(in context: Context) -> FrankEnergieEntry {
        .placeholder()
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (FrankEnergieEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder())
            return
        }

        Task {
            let entry = await fetchEntry()
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<FrankEnergieEntry>) -> Void) {
        Task {
            let entry = await fetchEntry()

            // Schedule next refresh in 15 minutes
            let refreshDate = Date().addingTimeInterval(TimeInterval(Constants.refreshIntervalMinutes * 60))
            let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
            completion(timeline)
        }
    }

    /// Fetch price data from the API and create a timeline entry
    private func fetchEntry() async -> FrankEnergieEntry {
        let preferences = WidgetPreferences.shared
        let priceType = preferences.priceType
        let resolution = preferences.resolution

        do {
            let marketPrices = try await api.fetchMarketPrices(
                date: Date(),
                resolution: resolution
            )

            let snapshot = PriceSnapshot(
                electricityPrices: marketPrices.electricityPrices,
                gasPrices: marketPrices.gasPrices,
                averageElectricity: marketPrices.averageElectricityPrices,
                priceType: priceType,
                resolution: resolution,
                fetchDate: Date()
            )

            return FrankEnergieEntry(
                date: Date(),
                snapshot: snapshot,
                isPlaceholder: false
            )
        } catch {
            // On failure, return placeholder with the user's preferences
            let fallback = FrankEnergieEntry.placeholder()
            return FrankEnergieEntry(
                date: fallback.date,
                snapshot: PriceSnapshot(
                    electricityPrices: fallback.snapshot.electricityPrices,
                    gasPrices: fallback.snapshot.gasPrices,
                    averageElectricity: fallback.snapshot.averageElectricity,
                    priceType: priceType,
                    resolution: resolution,
                    fetchDate: Date()
                ),
                isPlaceholder: true
            )
        }
    }
}

/// The widget definition
struct FrankEnergieElectricityWidget: Widget {
    let kind: String = "FrankEnergieElectricityWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FrankEnergieTimelineProvider()) { entry in
            FrankEnergieWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Frank Energie")
        .description("Dynamische stroomprijzen van vandaag")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

/// Routes to the appropriate widget view based on the widget family size
struct FrankEnergieWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: FrankEnergieEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(snapshot: entry.snapshot)
        case .systemMedium:
            MediumWidgetView(snapshot: entry.snapshot)
        default:
            MediumWidgetView(snapshot: entry.snapshot)
        }
    }
}
