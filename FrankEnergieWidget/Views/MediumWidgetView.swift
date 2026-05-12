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
        VStack(spacing: 4) {
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
        .padding(.vertical, 8)
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
            // Average electricity price
            HStack(spacing: 4) {
                Circle()
                    .fill(WidgetTheme.chartLine)
                    .frame(width: 6, height: 6)
                Text("Gem. \(snapshot.formattedAveragePrice) /kWh")
                    .font(.system(size: 9, weight: .regular))
                    .foregroundColor(WidgetTheme.secondaryText(for: colorScheme))
            }

            Spacer()

            // Gas prices
            if let gasBefore = snapshot.gasPriceBefore6 {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 7))
                        .foregroundColor(WidgetTheme.mutedText(for: colorScheme))
                    Text("< 06: \(PriceFormatter.format(gasBefore.price(for: snapshot.priceType)))")
                        .font(.system(size: 9, weight: .regular))
                        .foregroundColor(WidgetTheme.secondaryText(for: colorScheme))
                }
            }

            if let gasAfter = snapshot.gasPriceAfter6 {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 7))
                        .foregroundColor(WidgetTheme.mutedText(for: colorScheme))
                    Text("> 06: \(PriceFormatter.format(gasAfter.price(for: snapshot.priceType)))")
                        .font(.system(size: 9, weight: .regular))
                        .foregroundColor(WidgetTheme.secondaryText(for: colorScheme))
                }
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
