import Foundation

// MARK: - HTTPMethod
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - APIEndpoint
enum APIEndpoint {
    // Stock endpoints
    case stockDetail(symbol: String)
    case stockSearch(query: String)
    case exchangeRate

    // Portfolio endpoints
    case portfolio
    case savePortfolio

    // News endpoints
    case news(symbol: String, count: Int, refresh: Int)
    case summarizeNews

    // Preferences endpoints
    case preferences
    case updatePreferences

    // Subscription endpoints
    case validateReceipt

    var baseURL: String {
        // TODO: Replace with your actual backend URL
        return "https://equitylabs.app"
    }

    var path: String {
        switch self {
        case .stockDetail(let symbol):
            return "/api/stocks/\(symbol)"
        case .stockSearch:
            return "/api/stocks/search"
        case .exchangeRate:
            return "/api/exchange-rate"
        case .portfolio, .savePortfolio:
            return "/api/portfolio"
        case .news(let symbol, _, _):
            return "/api/news/\(symbol)"
        case .summarizeNews:
            return "/api/news/summarize"
        case .preferences, .updatePreferences:
            return "/api/preferences"
        case .validateReceipt:
            return "/api/subscriptions/validate-receipt"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .stockDetail, .stockSearch, .exchangeRate, .portfolio, .news, .preferences:
            return .get
        case .savePortfolio, .summarizeNews, .validateReceipt:
            return .post
        case .updatePreferences:
            return .patch
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .stockSearch(let query):
            return [URLQueryItem(name: "q", value: query)]
        case .news(_, let count, let refresh):
            return [
                URLQueryItem(name: "count", value: String(count)),
                URLQueryItem(name: "refresh", value: String(refresh))
            ]
        default:
            return nil
        }
    }

    func buildURL() throws -> URL {
        guard var components = URLComponents(string: baseURL + path) else {
            throw APIError.invalidURL
        }

        if let queryItems = queryItems {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        return url
    }
}
