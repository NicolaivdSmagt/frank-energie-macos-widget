// ABOUTME: Tests for the widget timeline provider logic.
// ABOUTME: Verifies placeholder generation, snapshot creation, and refresh scheduling.

import XCTest
@testable import FrankEnergieWidgetExtension

final class TimelineProviderTests: XCTestCase {

    // MARK: - Placeholder Tests

    func testPlaceholderHasSampleData() {
        let placeholder = FrankEnergieEntry.placeholder()

        XCTAssertTrue(placeholder.isPlaceholder)
        XCTAssertFalse(placeholder.snapshot.electricityPrices.isEmpty)
        XCTAssertFalse(placeholder.snapshot.gasPrices.isEmpty)
        XCTAssertEqual(placeholder.snapshot.electricityPrices.count, 24)
        XCTAssertEqual(placeholder.snapshot.priceType, .allIn)
        XCTAssertEqual(placeholder.snapshot.resolution, .hourly)
    }

    func testPlaceholderAveragePrices() {
        let placeholder = FrankEnergieEntry.placeholder()

        XCTAssertEqual(placeholder.snapshot.averageElectricity.averageAllInPrice, 0.241, accuracy: 0.001)
        XCTAssertEqual(placeholder.snapshot.averageElectricity.perUnit, "KWH")
    }

    // MARK: - PriceSnapshot Tests

    func testCurrentElectricityPrice() {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)

        // Create prices where one entry covers the current hour
        let prices = (0..<24).map { h -> ElectricityPrice in
            let from = calendar.startOfDay(for: now).addingTimeInterval(TimeInterval(h * 3600))
            let till = from.addingTimeInterval(3600)
            let formatter = ISO8601DateFormatter.shared
            return ElectricityPrice(
                from: formatter.string(from: from),
                till: formatter.string(from: till),
                resolution: "PT60M",
                marketPrice: Double(h) * 0.01,
                marketPriceTax: 0.02,
                sourcingMarkupPrice: 0.018,
                energyTaxPrice: 0.11,
                marketPricePlus: Double(h) * 0.01 + 0.04,
                allInPrice: Double(h) * 0.01 + 0.15,
                perUnit: "KWH"
            )
        }

        let snapshot = PriceSnapshot(
            electricityPrices: prices,
            gasPrices: [],
            averageElectricity: AverageElectricityPrices(
                averageMarketPrice: 0.09,
                averageMarketPricePlus: 0.13,
                averageAllInPrice: 0.24,
                perUnit: "KWH",
                isWeighted: false
            ),
            priceType: .allIn,
            resolution: .hourly,
            fetchDate: now
        )

        let current = snapshot.currentElectricityPrice
        XCTAssertNotNil(current)
    }

    func testCurrentFractionalHour() {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents(in: Constants.netherlandsTimeZone, from: now)
        let expectedHour = Double(components.hour ?? 0) + Double(components.minute ?? 0) / 60.0

        let snapshot = PriceSnapshot(
            electricityPrices: [],
            gasPrices: [],
            averageElectricity: AverageElectricityPrices(
                averageMarketPrice: 0.09,
                averageMarketPricePlus: 0.13,
                averageAllInPrice: 0.24,
                perUnit: "KWH",
                isWeighted: false
            ),
            priceType: .allIn,
            resolution: .hourly,
            fetchDate: now
        )

        XCTAssertEqual(snapshot.currentFractionalHour, expectedHour, accuracy: 0.02)
    }

    func testFormattedAveragePrice() {
        let snapshot = PriceSnapshot(
            electricityPrices: [],
            gasPrices: [],
            averageElectricity: AverageElectricityPrices(
                averageMarketPrice: 0.09287,
                averageMarketPricePlus: 0.13052,
                averageAllInPrice: 0.24137,
                perUnit: "KWH",
                isWeighted: false
            ),
            priceType: .allIn,
            resolution: .hourly,
            fetchDate: Date()
        )

        XCTAssertEqual(snapshot.formattedAveragePrice, "0,241")
    }

    func testFormattedAveragePriceMarket() {
        let snapshot = PriceSnapshot(
            electricityPrices: [],
            gasPrices: [],
            averageElectricity: AverageElectricityPrices(
                averageMarketPrice: 0.09287,
                averageMarketPricePlus: 0.13052,
                averageAllInPrice: 0.24137,
                perUnit: "KWH",
                isWeighted: false
            ),
            priceType: .market,
            resolution: .hourly,
            fetchDate: Date()
        )

        XCTAssertEqual(snapshot.formattedAveragePrice, "0,093")
    }

    // MARK: - Gas Price Splitting Tests

    func testGasPriceBeforeAndAfter6() {
        let baseDate = Calendar.current.startOfDay(for: Date())
        let formatter = ISO8601DateFormatter.shared

        let gasPrices = [
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

        let snapshot = PriceSnapshot(
            electricityPrices: [],
            gasPrices: gasPrices,
            averageElectricity: AverageElectricityPrices(
                averageMarketPrice: 0.09,
                averageMarketPricePlus: 0.13,
                averageAllInPrice: 0.24,
                perUnit: "KWH",
                isWeighted: false
            ),
            priceType: .allIn,
            resolution: .hourly,
            fetchDate: Date()
        )

        XCTAssertNotNil(snapshot.gasPriceBefore6)
        XCTAssertNotNil(snapshot.gasPriceAfter6)
        XCTAssertEqual(snapshot.gasPriceBefore6?.allInPrice, 1.326, accuracy: 0.001)
        XCTAssertEqual(snapshot.gasPriceAfter6?.allInPrice, 1.353, accuracy: 0.001)
    }

    // MARK: - Widget Preferences Tests

    func testDefaultPreferences() {
        let prefs = WidgetPreferences.shared
        // Defaults should be allIn and hourly
        XCTAssertEqual(prefs.priceType, .allIn)
        XCTAssertEqual(prefs.resolution, .hourly)
    }
}
