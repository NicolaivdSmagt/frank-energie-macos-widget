// ABOUTME: Medium-sized widget view displaying the 24-hour electricity price chart.
// ABOUTME: Includes interactive toggle buttons for price type and resolution, plus summary stats.

import SwiftUI
import WidgetKit
import AppIntents

/// The medium widget view showing the full price chart with toggles and summary
struct MediumWidgetView: View {
    let snapshot: PriceSnapshot

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 2) {
            // Header: title + toggle buttons
            headerView

            // Chart
            StepLineChartView(
                prices: snapshot.electricityPrices,
                priceType: snapshot.priceType,
                currentFractionalHour: snapshot.currentFractionalHour,
                priceRange: snapshot.priceRange
            )

            // Footer: summary stats
            footerView
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 4)
        .containerBackground(for: .widget) {
            WidgetTheme.background(for: colorScheme)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Text("Stroomprijs")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(WidgetTheme.primaryText(for: colorScheme))

            Spacer()

            // Price type toggle
            HStack(spacing: 2) {
                toggleButton(
                    label: "Marktprijs",
                    isActive: snapshot.priceType == .market,
                    intent: TogglePriceTypeIntent()
                )
                toggleButton(
                    label: "All-in",
                    isActive: snapshot.priceType == .allIn,
                    intent: TogglePriceTypeIntent()
                )
            }

            Spacer().frame(width: 8)

            // Resolution toggle
            HStack(spacing: 2) {
                toggleButton(
                    label: "Uur",
                    isActive: snapshot.resolution == .hourly,
                    intent: ToggleResolutionIntent()
                )
                toggleButton(
                    label: "Kwartier",
                    isActive: snapshot.resolution == .quarterHourly,
                    intent: ToggleResolutionIntent()
                )
            }
        }
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack(spacing: 12) {
            // Current electricity price
            if let current = snapshot.currentElectricityPrice {
                HStack(spacing: 4) {
                    Circle()
                        .fill(WidgetTheme.priceLevel(
                            current: current.price(for: snapshot.priceType),
                            range: snapshot.priceRange
                        ))
                        .frame(width: 6, height: 6)
                    Text("Nu: \(PriceFormatter.formatWithEuro(current.price(for: snapshot.priceType))) /kWh")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(WidgetTheme.primaryText(for: colorScheme))
                }
            }

            Spacer()

            // Average electricity price
            HStack(spacing: 4) {
                Circle()
                    .fill(WidgetTheme.chartLine)
                    .frame(width: 6, height: 6)
                Text("Gem. \(snapshot.formattedAveragePrice) /kWh")
                    .font(.system(size: 9, weight: .regular))
                    .foregroundColor(WidgetTheme.secondaryText(for: colorScheme))
            }
        }
    }

    // MARK: - Toggle Button

    private func toggleButton(label: String, isActive: Bool, intent: some AppIntent) -> some View {
        Button(intent: intent) {
            Text(label)
                .font(.system(size: 8, weight: isActive ? .semibold : .regular))
                .foregroundColor(
                    isActive
                        ? WidgetTheme.toggleActiveText
                        : WidgetTheme.toggleInactiveText(for: colorScheme)
                )
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isActive
                              ? WidgetTheme.toggleActive(for: colorScheme)
                              : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(
                            isActive
                                ? Color.clear
                                : WidgetTheme.toggleInactiveBorder(for: colorScheme),
                            lineWidth: 0.5
                        )
                )
        }
        .buttonStyle(.plain)
    }
}
