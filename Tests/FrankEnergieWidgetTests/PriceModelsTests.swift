// ABOUTME: Unit tests for the price data models and JSON decoding.
// ABOUTME: Verifies correct parsing of the Frank Energie API response format.

import XCTest
@testable import FrankEnergieWidgetExtension

final class PriceModelsTests: XCTestCase {

    // MARK: - JSON Decoding Tests

    func testDecodeMarketPricesResponse() throws {
        let json = Self.sampleAPIResponse
        let data = json.data(using: .utf8)!

        let response = try JSONDecoder().decode(MarketPricesResponse.self, from: data)

        XCTAssertNotNil(response.data)
        XCTAssertNil(response.errors)

        let marketPrices = try XCTUnwrap(response.data?.marketPrices)
        XCTAssertEqual(marketPrices.electricityPrices.count, 3)
        XCTAssertEqual(marketPrices.gasPrices.count, 1)
    }

    func testDecodeElectricityPrice() throws {
        let json = Self.sampleAPIResponse
        let data = json.data(using: .utf8)!

        let response = try JSONDecoder().decode(MarketPricesResponse.self, from: data)
        let prices = try XCTUnwrap(response.data?.marketPrices.electricityPrices)
        let first = try XCTUnwrap(prices.first)

        XCTAssertEqual(first.from, "2026-05-11T22:00:00.000Z")
        XCTAssertEqual(first.till, "2026-05-11T23:00:00.000Z")
        XCTAssertEqual(first.resolution, "PT60M")
        XCTAssertEqual(first.marketPrice, 0.09917, accuracy: 0.00001)
        XCTAssertEqual(first.allInPrice, 0.24899, accuracy: 0.00001)
        XCTAssertEqual(first.perUnit, "KWH")
    }

    func testDecodeAverageElectricityPrices() throws {
        let json = Self.sampleAPIResponse
        let data = json.data(using: .utf8)!

        let response = try JSONDecoder().decode(MarketPricesResponse.self, from: data)
        let avg = try XCTUnwrap(response.data?.marketPrices.averageElectricityPrices)

        XCTAssertEqual(avg.averageMarketPrice, 0.09287, accuracy: 0.00001)
        XCTAssertEqual(avg.averageAllInPrice, 0.24137, accuracy: 0.00001)
        XCTAssertEqual(avg.perUnit, "KWH")
        XCTAssertFalse(avg.isWeighted)
    }

    func testDecodeGasPrice() throws {
        let json = Self.sampleAPIResponse
        let data = json.data(using: .utf8)!

        let response = try JSONDecoder().decode(MarketPricesResponse.self, from: data)
        let gasPrices = try XCTUnwrap(response.data?.marketPrices.gasPrices)
        let first = try XCTUnwrap(gasPrices.first)

        XCTAssertEqual(first.marketPrice, 0.42922, accuracy: 0.00001)
        XCTAssertEqual(first.allInPrice, 1.32602, accuracy: 0.00001)
        XCTAssertEqual(first.perUnit, "M3")
    }

    func testDecodeGraphQLError() throws {
        let json = """
        {
            "data": null,
            "errors": [{"message": "Graphql validation error"}]
        }
        """
        let data = json.data(using: .utf8)!

        let response = try JSONDecoder().decode(MarketPricesResponse.self, from: data)

        XCTAssertNil(response.data)
        XCTAssertNotNil(response.errors)
        XCTAssertEqual(response.errors?.first?.message, "Graphql validation error")
    }

    // MARK: - Date Parsing Tests

    func testElectricityPriceDateParsing() throws {
        let json = Self.sampleAPIResponse
        let data = json.data(using: .utf8)!

        let response = try JSONDecoder().decode(MarketPricesResponse.self, from: data)
        let first = try XCTUnwrap(response.data?.marketPrices.electricityPrices.first)

        let fromDate = try XCTUnwrap(first.fromDate)
        let tillDate = try XCTUnwrap(first.tillDate)

        // Verify the time difference is 1 hour
        let interval = tillDate.timeIntervalSince(fromDate)
        XCTAssertEqual(interval, 3600, accuracy: 1)
    }

    func testLocalHourComputation() throws {
        let json = Self.sampleAPIResponse
        let data = json.data(using: .utf8)!

        let response = try JSONDecoder().decode(MarketPricesResponse.self, from: data)
        let prices = try XCTUnwrap(response.data?.marketPrices.electricityPrices)

        // "2026-05-11T22:00:00.000Z" in Europe/Amsterdam (CEST, UTC+2) = 00:00 local
        let first = prices[0]
        XCTAssertEqual(first.localHour, 0)

        // "2026-05-11T23:00:00.000Z" in CEST = 01:00 local
        let second = prices[1]
        XCTAssertEqual(second.localHour, 1)
    }

    // MARK: - Price Type Selection Tests

    func testPriceForType() throws {
        let price = ElectricityPrice(
            from: "2026-05-12T10:00:00.000Z",
            till: "2026-05-12T11:00:00.000Z",
            resolution: "PT60M",
            marketPrice: 0.09,
            marketPriceTax: 0.02,
            sourcingMarkupPrice: 0.018,
            energyTaxPrice: 0.11,
            marketPricePlus: 0.13,
            allInPrice: 0.24,
            perUnit: "KWH"
        )

        XCTAssertEqual(price.price(for: .market), 0.09)
        XCTAssertEqual(price.price(for: .allIn), 0.24)
    }

    // MARK: - PriceFormatter Tests

    func testPriceFormatterBasic() {
        XCTAssertEqual(PriceFormatter.format(0.241), "0,241")
        XCTAssertEqual(PriceFormatter.format(0.1), "0,100")
        XCTAssertEqual(PriceFormatter.format(1.32602), "1,326")
    }

    func testPriceFormatterWithEuro() {
        XCTAssertEqual(PriceFormatter.formatWithEuro(0.241), "€ 0,241")
    }

    // MARK: - PriceSnapshot Tests

    func testPriceRange() {
        let prices = [
            makeElectricityPrice(hour: 0, allIn: 0.20),
            makeElectricityPrice(hour: 1, allIn: 0.15),
            makeElectricityPrice(hour: 2, allIn: 0.30),
        ]

        let snapshot = PriceSnapshot(
            electricityPrices: prices,
            gasPrices: [],
            averageElectricity: AverageElectricityPrices(
                averageMarketPrice: 0.09,
                averageMarketPricePlus: 0.13,
                averageAllInPrice: 0.22,
                perUnit: "KWH",
                isWeighted: false
            ),
            priceType: .allIn,
            resolution: .hourly,
            fetchDate: Date()
        )

        XCTAssertEqual(snapshot.priceRange.lowerBound, 0.0)
        XCTAssertEqual(snapshot.priceRange.upperBound, 0.30)
    }

    // MARK: - Helpers

    private func makeElectricityPrice(hour: Int, allIn: Double) -> ElectricityPrice {
        let baseDate = Calendar.current.startOfDay(for: Date())
        let from = baseDate.addingTimeInterval(TimeInterval(hour * 3600))
        let till = from.addingTimeInterval(3600)
        let formatter = ISO8601DateFormatter.shared

        return ElectricityPrice(
            from: formatter.string(from: from),
            till: formatter.string(from: till),
            resolution: "PT60M",
            marketPrice: allIn * 0.4,
            marketPriceTax: allIn * 0.08,
            sourcingMarkupPrice: 0.018,
            energyTaxPrice: 0.11,
            marketPricePlus: allIn * 0.55,
            allInPrice: allIn,
            perUnit: "KWH"
        )
    }

    // MARK: - Sample Data

    private static let sampleAPIResponse = """
    {
        "data": {
            "marketPrices": {
                "averageElectricityPrices": {
                    "averageMarketPrice": 0.09287,
                    "averageMarketPricePlus": 0.13052,
                    "averageAllInPrice": 0.24137,
                    "perUnit": "KWH",
                    "isWeighted": false
                },
                "electricityPrices": [
                    {
                        "from": "2026-05-11T22:00:00.000Z",
                        "till": "2026-05-11T23:00:00.000Z",
                        "resolution": "PT60M",
                        "marketPrice": 0.09917,
                        "marketPriceTax": 0.02083,
                        "sourcingMarkupPrice": 0.01815,
                        "energyTaxPrice": 0.11085,
                        "marketPricePlus": 0.13815,
                        "allInPrice": 0.24899,
                        "perUnit": "KWH"
                    },
                    {
                        "from": "2026-05-11T23:00:00.000Z",
                        "till": "2026-05-12T00:00:00.000Z",
                        "resolution": "PT60M",
                        "marketPrice": 0.09453,
                        "marketPriceTax": 0.01985,
                        "sourcingMarkupPrice": 0.01815,
                        "energyTaxPrice": 0.11085,
                        "marketPricePlus": 0.13253,
                        "allInPrice": 0.24338,
                        "perUnit": "KWH"
                    },
                    {
                        "from": "2026-05-12T00:00:00.000Z",
                        "till": "2026-05-12T01:00:00.000Z",
                        "resolution": "PT60M",
                        "marketPrice": 0.08941,
                        "marketPriceTax": 0.01878,
                        "sourcingMarkupPrice": 0.01815,
                        "energyTaxPrice": 0.11085,
                        "marketPricePlus": 0.12634,
                        "allInPrice": 0.23718,
                        "perUnit": "KWH"
                    }
                ],
                "gasPrices": [
                    {
                        "from": "2026-05-11T22:00:00.000Z",
                        "till": "2026-05-11T22:15:00.000Z",
                        "resolution": "PT15M",
                        "marketPrice": 0.42922,
                        "marketPriceTax": 0.09014,
                        "sourcingMarkupPrice": 0.07986,
                        "energyTaxPrice": 0.7268,
                        "marketPricePlus": 0.59922,
                        "allInPrice": 1.32602,
                        "perUnit": "M3"
                    }
                ]
            }
        }
    }
    """
}
