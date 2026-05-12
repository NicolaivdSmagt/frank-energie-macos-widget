// ABOUTME: Small-sized widget view displaying the current electricity price prominently.
// ABOUTME: Shows a large price value with color-coded accent based on price level.

import SwiftUI
import WidgetKit

/// The small widget view showing the current price at a glance
struct SmallWidgetView: View {
    let snapshot: PriceSnapshot

    @Environment(\.colorScheme) private var colorScheme

    /// The current price value to display
    private var currentPrice: Double {
        snapshot.currentElectricityPrice?.price(for: snapshot.priceType) ?? 0
    }

    /// Color indicating the relative price level
    private var accentColor: Color {
        WidgetTheme.priceLevel(current: currentPrice, range: snapshot.priceRange)
    }

    var body: some View {
        VStack(spacing: 6) {
            // Header
            HStack {
                Text("Stroom nu")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(WidgetTheme.secondaryText(for: colorScheme))
                Spacer()
                // Small indicator dot showing price level
                Circle()
                    .fill(accentColor)
                    .frame(width: 8, height: 8)
            }

            Spacer()

            // Large price display
            VStack(spacing: 2) {
                Text(PriceFormatter.formatWithEuro(currentPrice))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(WidgetTheme.primaryText(for: colorScheme))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                Text("/kWh")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(WidgetTheme.secondaryText(for: colorScheme))
            }

            Spacer()

            // Footer: price type label + average comparison
            HStack {
                Text(snapshot.priceType.displayName)
                    .font(.system(size: 8, weight: .regular))
                    .foregroundColor(WidgetTheme.mutedText(for: colorScheme))

                Spacer()

                Text("Gem. \(snapshot.formattedAveragePrice)")
                    .font(.system(size: 8, weight: .regular))
                    .foregroundColor(WidgetTheme.mutedText(for: colorScheme))
            }
        }
        .padding(12)
        .containerBackground(for: .widget) {
            WidgetTheme.background(for: colorScheme)
                .overlay(
                    // Subtle accent glow at the top edge
                    LinearGradient(
                        colors: [accentColor.opacity(0.15), Color.clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
        }
    }
}
