// ABOUTME: Custom step-line chart view that renders electricity prices over 24 hours.
// ABOUTME: Draws a stepped line (matching the Frank Energie website style) with a vertical time marker.

import SwiftUI

/// A step-line chart that displays electricity prices over a 24-hour period
struct StepLineChartView: View {
    let prices: [ElectricityPrice]
    let priceType: PriceType
    let currentFractionalHour: Double
    let priceRange: ClosedRange<Double>

    @Environment(\.colorScheme) private var colorScheme

    /// Y-axis tick values to display
    private var yAxisTicks: [Double] {
        let span = priceRange.upperBound - priceRange.lowerBound
        let step: Double
        if span <= 0.15 {
            step = 0.05
        } else if span <= 0.30 {
            step = 0.10
        } else if span <= 0.60 {
            step = 0.20
        } else {
            step = 0.50
        }

        var ticks: [Double] = []
        // Start from the nearest step below the lower bound
        var value = (priceRange.lowerBound / step).rounded(.down) * step
        // End at the nearest step above the upper bound
        let end = (priceRange.upperBound / step).rounded(.up) * step
        while value <= end {
            ticks.append(value)
            value += step
        }
        return ticks
    }

    /// Padded price range for rendering (adds margin above and below)
    private var renderRange: ClosedRange<Double> {
        let ticks = yAxisTicks
        let lower = ticks.first ?? priceRange.lowerBound
        let upper = ticks.last ?? priceRange.upperBound
        return lower...upper
    }

    var body: some View {
        GeometryReader { geometry in
            let chartArea = chartRect(in: geometry.size)

            ZStack(alignment: .topLeading) {
                // Y-axis labels and grid lines
                ForEach(yAxisTicks, id: \.self) { tick in
                    let y = yPosition(for: tick, in: chartArea)

                    // Grid line
                    Path { path in
                        path.move(to: CGPoint(x: chartArea.minX, y: y))
                        path.addLine(to: CGPoint(x: chartArea.maxX, y: y))
                    }
                    .stroke(WidgetTheme.gridLine(for: colorScheme), lineWidth: 0.5)

                    // Y-axis label
                    Text(formatYLabel(tick))
                        .font(.system(size: 9, weight: .regular, design: .monospaced))
                        .foregroundColor(WidgetTheme.secondaryText(for: colorScheme))
                        .position(x: 24, y: y)
                }

                // X-axis labels
                ForEach([0, 6, 12, 18, 24], id: \.self) { hour in
                    let x = xPosition(for: Double(hour), in: chartArea)
                    Text(String(format: "%02d", hour == 24 ? 0 : hour))
                        .font(.system(size: 9, weight: .regular, design: .monospaced))
                        .foregroundColor(WidgetTheme.secondaryText(for: colorScheme))
                        .position(x: x, y: chartArea.maxY + 12)
                }

                // Step-line chart path
                stepLinePath(in: chartArea)
                    .stroke(WidgetTheme.chartLine, style: StrokeStyle(lineWidth: 2, lineJoin: .miter))

                // Current time vertical marker
                if currentFractionalHour >= 0 && currentFractionalHour <= 24 {
                    let markerX = xPosition(for: currentFractionalHour, in: chartArea)
                    Path { path in
                        path.move(to: CGPoint(x: markerX, y: chartArea.minY))
                        path.addLine(to: CGPoint(x: markerX, y: chartArea.maxY))
                    }
                    .stroke(WidgetTheme.timeMarker(for: colorScheme), lineWidth: 2)
                }
            }
        }
    }

    // MARK: - Chart Layout

    /// The rectangular area where the chart is drawn (inset from the view edges for labels)
    private func chartRect(in size: CGSize) -> CGRect {
        let leftMargin: CGFloat = 48  // Space for Y-axis labels
        let rightMargin: CGFloat = 8
        let topMargin: CGFloat = 10  // Space between header text and top Y-axis label
        let bottomMargin: CGFloat = 24  // Space for X-axis labels (below chart)

        return CGRect(
            x: leftMargin,
            y: topMargin,
            width: size.width - leftMargin - rightMargin,
            height: size.height - topMargin - bottomMargin
        )
    }

    /// Convert a fractional hour (0-24) to an X coordinate within the chart area
    private func xPosition(for hour: Double, in rect: CGRect) -> CGFloat {
        let fraction = hour / 24.0
        return rect.minX + CGFloat(fraction) * rect.width
    }

    /// Convert a price value to a Y coordinate within the chart area (inverted: higher price = lower Y)
    private func yPosition(for price: Double, in rect: CGRect) -> CGFloat {
        let range = renderRange
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return rect.midY }
        let fraction = (price - range.lowerBound) / span
        return rect.maxY - CGFloat(fraction) * rect.height
    }

    // MARK: - Step Line Path

    /// Build the stepped line path from price data points
    private func stepLinePath(in rect: CGRect) -> Path {
        Path { path in
            guard !prices.isEmpty else { return }

            var started = false
            for entry in prices {
                guard let hour = entry.localFractionalHour else { continue }
                let price = entry.price(for: priceType)
                let x = xPosition(for: hour, in: rect)
                let y = yPosition(for: price, in: rect)

                if !started {
                    path.move(to: CGPoint(x: x, y: y))
                    started = true
                } else {
                    // Step: horizontal first, then vertical (creates the stepped look)
                    path.addLine(to: CGPoint(x: x, y: path.currentPoint?.y ?? y))
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }

            // Extend the last step to the end of its time slot
            if let lastEntry = prices.last,
               let lastHour = lastEntry.localFractionalHour {
                let stepDuration: Double = (lastEntry.resolution == "PT15M") ? 0.25 : 1.0
                let endHour = min(lastHour + stepDuration, 24.0)
                let endX = xPosition(for: endHour, in: rect)
                path.addLine(to: CGPoint(x: endX, y: path.currentPoint?.y ?? 0))
            }
        }
    }

    // MARK: - Formatting

    /// Format a Y-axis label value like "€ 0,20"
    private func formatYLabel(_ value: Double) -> String {
        let formatted = String(format: "%.2f", value).replacingOccurrences(of: ".", with: ",")
        return "€ \(formatted)"
    }
}
