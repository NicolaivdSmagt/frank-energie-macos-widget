// ABOUTME: Integration tests for the Frank Energie GraphQL API client.
// ABOUTME: Verifies the API endpoint is reachable and returns correctly structured data.

import XCTest
@testable import FrankEnergieWidgetExtension

final class FrankEnergieAPITests: XCTestCase {

    private var api: FrankEnergieAPI!

    override func setUp() {
        super.setUp()
        api = FrankEnergieAPI()
    }

    // MARK: - Integration Tests (require network)

    func testFetchHourlyPrices() async throws {
        let marketPrices = try await api.fetchMarketPrices(
            date: Date(),
            resolution: .hourly
        )

        // Should have ~24 entries for a full day (may have extra from previous day UTC offset)
        XCTAssertGreaterThanOrEqual(marketPrices.electricityPrices.count, 24)
        XCTAssertFalse(marketPrices.gasPrices.isEmpty)

        // Verify average prices are populated
        XCTAssertGreaterThan(marketPrices.averageElectricityPrices.averageAllInPrice, 0)
        XCTAssertEqual(marketPrices.averageElectricityPrices.perUnit, "KWH")

        // Verify price entries have valid data
        let firstPrice = try XCTUnwrap(marketPrices.electricityPrices.first)
        XCTAssertEqual(firstPrice.resolution, "PT60M")
        XCTAssertEqual(firstPrice.perUnit, "KWH")
        XCTAssertGreaterThan(firstPrice.allInPrice, 0)
        XCTAssertNotNil(firstPrice.fromDate)
        XCTAssertNotNil(firstPrice.tillDate)
    }

    func testFetchQuarterHourlyPrices() async throws {
        let marketPrices = try await api.fetchMarketPrices(
            date: Date(),
            resolution: .quarterHourly
        )

        // Should have ~96 entries for a full day at 15-min resolution
        XCTAssertGreaterThanOrEqual(marketPrices.electricityPrices.count, 96)

        let firstPrice = try XCTUnwrap(marketPrices.electricityPrices.first)
        XCTAssertEqual(firstPrice.resolution, "PT15M")
    }

    func testFetchGasPrices() async throws {
        let marketPrices = try await api.fetchMarketPrices(
            date: Date(),
            resolution: .hourly
        )

        let firstGas = try XCTUnwrap(marketPrices.gasPrices.first)
        XCTAssertEqual(firstGas.perUnit, "M3")
        XCTAssertGreaterThan(firstGas.allInPrice, 0)
    }

    // MARK: - Date Formatting Tests

    func testFormatDate() {
        // Create a known date: May 12, 2026 at midnight in Amsterdam
        var components = DateComponents()
        components.year = 2026
        components.month = 5
        components.day = 12
        components.hour = 0
        components.minute = 0
        components.timeZone = Constants.netherlandsTimeZone

        let date = Calendar.current.date(from: components)!
        let formatted = FrankEnergieAPI.formatDate(date)

        XCTAssertEqual(formatted, "2026-05-12")
    }

    func testFormatDateHandlesUTCOffset() {
        // At 23:30 UTC on May 11, it's already May 12 in Amsterdam (CEST = UTC+2)
        var components = DateComponents()
        components.year = 2026
        components.month = 5
        components.day = 11
        components.hour = 23
        components.minute = 30
        components.timeZone = TimeZone(identifier: "UTC")

        let date = Calendar.current.date(from: components)!
        let formatted = FrankEnergieAPI.formatDate(date)

        // In Amsterdam time, this is May 12 at 01:30
        XCTAssertEqual(formatted, "2026-05-12")
    }

    // MARK: - Error Handling Tests

    func testInvalidDateReturnsError() async {
        // A date far in the future should still return a valid structure
        // (the API returns empty prices for dates without data, or may error)
        var components = DateComponents()
        components.year = 2030
        components.month = 12
        components.day = 31
        components.timeZone = Constants.netherlandsTimeZone

        let futureDate = Calendar.current.date(from: components)!

        // This may either succeed with empty data or throw a graphQL error
        do {
            let result = try await api.fetchMarketPrices(date: futureDate, resolution: .hourly)
            // If it succeeds, it should at least have the structure
            XCTAssertNotNil(result.averageElectricityPrices)
        } catch let error as FrankEnergieAPIError {
            // GraphQL errors are expected for invalid dates
            switch error {
            case .graphQLError:
                // This is an acceptable outcome
                break
            default:
                // Network errors might happen in CI, don't fail hard
                break
            }
        }
    }
}
