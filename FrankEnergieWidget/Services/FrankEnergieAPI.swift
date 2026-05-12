// ABOUTME: GraphQL API client for fetching market prices from Frank Energie.
// ABOUTME: Uses URLSession to make unauthenticated POST requests to the public price endpoint.

import Foundation

/// Errors that can occur when fetching prices from the Frank Energie API
enum FrankEnergieAPIError: Error, LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case graphQLError(message: String)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Frank Energie API"
        case .httpError(let statusCode):
            return "HTTP error \(statusCode) from Frank Energie API"
        case .graphQLError(let message):
            return "GraphQL error: \(message)"
        case .decodingError(let error):
            return "Failed to decode API response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

/// Client for the Frank Energie GraphQL API
actor FrankEnergieAPI {

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Fetch market prices for a given date and resolution.
    /// No authentication is required for market prices.
    func fetchMarketPrices(
        date: Date = Date(),
        resolution: PriceResolution = .hourly
    ) async throws -> MarketPrices {
        let dateString = Self.formatDate(date)
        let query = Self.buildMarketPricesQuery()
        let variables: [String: String] = [
            "date": dateString,
            "resolution": resolution.rawValue
        ]

        let body: [String: Any] = [
            "query": query,
            "operationName": "MarketPrices",
            "variables": variables
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: body)

        var request = URLRequest(url: Constants.apiURL)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("4.13.3", forHTTPHeaderField: "x-graphql-client-version")
        request.setValue("frank-app", forHTTPHeaderField: "x-graphql-client-name")
        request.setValue("ios/26.0.1", forHTTPHeaderField: "x-graphql-client-os")

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw FrankEnergieAPIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FrankEnergieAPIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw FrankEnergieAPIError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoded: MarketPricesResponse
        do {
            decoded = try JSONDecoder().decode(MarketPricesResponse.self, from: data)
        } catch {
            throw FrankEnergieAPIError.decodingError(error)
        }

        if let errors = decoded.errors, let firstError = errors.first {
            throw FrankEnergieAPIError.graphQLError(message: firstError.message)
        }

        guard let marketPrices = decoded.data?.marketPrices else {
            throw FrankEnergieAPIError.invalidResponse
        }

        return marketPrices
    }

    /// Format a Date into the "YYYY-MM-DD" string the API expects
    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = Constants.netherlandsTimeZone
        return formatter.string(from: date)
    }

    /// Build the GraphQL query string for market prices
    private static func buildMarketPricesQuery() -> String {
        """
        query MarketPrices($date: String!, $resolution: PriceResolution!) {
            marketPrices(date: $date, resolution: $resolution) {
                averageElectricityPrices {
                    averageMarketPrice
                    averageMarketPricePlus
                    averageAllInPrice
                    perUnit
                    isWeighted
                }
                electricityPrices {
                    from
                    till
                    resolution
                    marketPrice
                    marketPriceTax
                    sourcingMarkupPrice
                    energyTaxPrice
                    marketPricePlus
                    allInPrice
                    perUnit
                }
                gasPrices {
                    from
                    till
                    resolution
                    marketPrice
                    marketPriceTax
                    sourcingMarkupPrice
                    energyTaxPrice
                    marketPricePlus
                    allInPrice
                    perUnit
                }
            }
        }
        """
    }
}
