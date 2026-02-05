import Foundation
import Combine

// MARK: - APIClient
@MainActor
class APIClient: ObservableObject {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private var authToken: String?

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.waitsForConnectivity = true

        self.session = URLSession(configuration: configuration)

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: - Authentication
    func setAuthToken(_ token: String?) {
        self.authToken = token
    }

    // MARK: - Request Methods
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        let url = try endpoint.buildURL()
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            #if DEBUG
            print("⚠️ WARNING: No auth token set - request will fail!")
            #endif
        }

        #if DEBUG
        print("🌐 API Request: \(endpoint.method.rawValue) \(url.absoluteString)")
        #endif

        return try await performRequest(request)
    }

    func upload<T: Decodable, Body: Encodable>(_ endpoint: APIEndpoint, body: Body) async throws -> T {
        let url = try endpoint.buildURL()
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = try encoder.encode(body)

        #if DEBUG
        print("🌐 API Request: \(endpoint.method.rawValue) \(url.absoluteString)")
        if let bodyData = request.httpBody,
           let bodyString = String(data: bodyData, encoding: .utf8) {
            print("📤 Request Body: \(bodyString)")
        }
        #endif

        return try await performRequest(request)
    }

    func uploadWithoutResponse<Body: Encodable>(_ endpoint: APIEndpoint, body: Body) async throws {
        let url = try endpoint.buildURL()
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = try encoder.encode(body)

        #if DEBUG
        print("🌐 API Request: \(endpoint.method.rawValue) \(url.absoluteString)")
        #endif

        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }

    // MARK: - Private Methods
    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)

        try validateResponse(response)

        #if DEBUG
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Response: \(responseString.prefix(500))")
        }
        #endif

        do {
            let decoded = try decoder.decode(T.self, from: data)
            return decoded
        } catch {
            #if DEBUG
            print("❌ Decoding Error: \(error)")
            #endif
            throw APIError.decodingError(error)
        }
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        #if DEBUG
        print("📊 Status Code: \(httpResponse.statusCode)")

        // Log Clerk-specific headers for debugging auth issues
        if let clerkAuthStatus = httpResponse.value(forHTTPHeaderField: "x-clerk-auth-status") {
            print("🔐 Clerk Auth Status: \(clerkAuthStatus)")
        }
        if let clerkAuthReason = httpResponse.value(forHTTPHeaderField: "x-clerk-auth-reason") {
            print("🔐 Clerk Auth Reason: \(clerkAuthReason)")
        }
        if let clerkAuthMessage = httpResponse.value(forHTTPHeaderField: "x-clerk-auth-message") {
            print("🔐 Clerk Auth Message: \(clerkAuthMessage)")
        }
        #endif

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            #if DEBUG
            print("❌ 404 Not Found - Endpoint may not exist or auth failed")
            #endif
            throw APIError.notFound
        case 429:
            throw APIError.rateLimited
        case 500...599:
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        default:
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
    }

    // MARK: - Retry Logic
    func requestWithRetry<T: Decodable>(
        _ endpoint: APIEndpoint,
        maxRetries: Int = 3,
        retryDelay: TimeInterval = 1.0
    ) async throws -> T {
        var lastError: APIError?

        for attempt in 0..<maxRetries {
            do {
                return try await request(endpoint)
            } catch let error as APIError {
                lastError = error

                guard error.isRetryable && attempt < maxRetries - 1 else {
                    throw error
                }

                let delay = retryDelay * pow(2.0, Double(attempt))
                #if DEBUG
                print("⏳ Retry attempt \(attempt + 1) after \(delay)s")
                #endif

                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }

        throw lastError ?? APIError.unknown
    }
}
