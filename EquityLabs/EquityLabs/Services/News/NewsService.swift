import Foundation
import Combine

// MARK: - NewsService
@MainActor
class NewsService: ObservableObject {
    static let shared = NewsService()

    private let apiClient = APIClient.shared
    private let cacheKey = "cached_news"

    @Published var isLoading = false
    @Published var error: Error?

    // In-memory cache for quick access
    private var memoryCache: [String: CachedNews] = [:]

    private init() {
        loadCacheFromDisk()
    }

    // MARK: - Fetch News

    /// Fetch news articles for a stock symbol with caching
    func fetchNews(for symbol: String, count: Int = 10, forceRefresh: Bool = false) async throws -> NewsResponse {
        isLoading = true
        defer { isLoading = false }

        // 1. Check cache first (unless force refresh)
        if !forceRefresh, let cached = getCachedNews(for: symbol), !cached.isExpired {
            AppLogger.portfolio.debug("Using cached news for \(symbol)")
            return NewsResponse(articles: cached.articles, hasSentiment: cached.hasSentiment)
        }

        do {
            // 2. Fetch from API
            let refresh = forceRefresh ? 1 : 0
            let response: NewsResponse = try await apiClient.request(.news(symbol: symbol, count: count, refresh: refresh))

            // 3. Cache the response
            cacheNews(response.articles, hasSentiment: response.hasSentiment, for: symbol)

            AppLogger.portfolio.info("Fetched \(response.articles.count) news articles for \(symbol), hasSentiment: \(response.hasSentiment)")
            return response
        } catch {
            AppLogger.portfolio.error("Failed to fetch news for \(symbol): \(error.localizedDescription)")

            // 4. Return cached data even if expired (offline fallback)
            if let cached = getCachedNews(for: symbol) {
                AppLogger.portfolio.warning("Using expired cache for \(symbol) due to API error")
                return NewsResponse(articles: cached.articles, hasSentiment: cached.hasSentiment)
            }

            self.error = error
            throw error
        }
    }

    // MARK: - Summarize Article

    /// Get AI-generated summary for a news article
    func summarizeArticle(_ article: NewsArticle) async throws -> String {
        isLoading = true
        defer { isLoading = false }

        do {
            let request = NewsSummaryRequest(
                articleUrl: article.url,
                articleTitle: article.title,
                source: article.source
            )
            let response: NewsSummaryResponse = try await apiClient.upload(
                .summarizeNews,
                body: request
            )

            AppLogger.portfolio.info("Generated summary for article: \(article.url)")
            return response.summary
        } catch {
            AppLogger.portfolio.error("Failed to summarize article: \(error.localizedDescription)")
            self.error = error
            throw error
        }
    }

    // MARK: - Cache Management

    /// Get cached news for a symbol
    private func getCachedNews(for symbol: String) -> CachedNews? {
        return memoryCache[symbol.uppercased()]
    }

    /// Cache news articles for a symbol
    private func cacheNews(_ articles: [NewsArticle], hasSentiment: Bool = false, for symbol: String) {
        let cached = CachedNews(articles: articles, symbol: symbol.uppercased(), hasSentiment: hasSentiment)
        memoryCache[symbol.uppercased()] = cached
        saveCacheToDisk()
    }

    /// Clear cache for a specific symbol
    func clearCache(for symbol: String) {
        memoryCache.removeValue(forKey: symbol.uppercased())
        saveCacheToDisk()
        AppLogger.portfolio.debug("Cleared news cache for \(symbol)")
    }

    /// Clear all news cache
    func clearAllCache() {
        memoryCache.removeAll()
        saveCacheToDisk()
        AppLogger.portfolio.info("Cleared all news cache")
    }

    /// Check if news is cached and fresh for a symbol
    func hasFreshCache(for symbol: String) -> Bool {
        guard let cached = getCachedNews(for: symbol) else {
            return false
        }
        return !cached.isExpired
    }

    // MARK: - Disk Persistence

    private var cacheURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("\(cacheKey).json")
    }

    /// Load cache from disk on initialization
    private func loadCacheFromDisk() {
        guard FileManager.default.fileExists(atPath: cacheURL.path) else {
            return
        }

        do {
            let data = try Data(contentsOf: cacheURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let cacheArray = try decoder.decode([CachedNews].self, from: data)

            // Convert array to dictionary for quick lookup
            memoryCache = Dictionary(uniqueKeysWithValues: cacheArray.map { ($0.symbol, $0) })

            AppLogger.portfolio.debug("Loaded news cache from disk: \(memoryCache.count) symbols")
        } catch {
            AppLogger.portfolio.warning("Failed to load news cache: \(error.localizedDescription)")
        }
    }

    /// Save cache to disk
    private func saveCacheToDisk() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted

            let cacheArray = Array(memoryCache.values)
            let data = try encoder.encode(cacheArray)

            try data.write(to: cacheURL)

            AppLogger.portfolio.debug("Saved news cache to disk: \(cacheArray.count) symbols")
        } catch {
            AppLogger.portfolio.error("Failed to save news cache: \(error.localizedDescription)")
        }
    }

    // MARK: - Batch Operations

    /// Fetch news for multiple symbols in parallel
    func fetchNewsForSymbols(_ symbols: [String], count: Int = 5) async throws -> [String: [NewsArticle]] {
        isLoading = true
        defer { isLoading = false }

        var results: [String: [NewsArticle]] = [:]

        try await withThrowingTaskGroup(of: (String, [NewsArticle]).self) { group in
            for symbol in symbols {
                group.addTask {
                    let response = try await self.fetchNews(for: symbol, count: count)
                    return (symbol, response.articles)
                }
            }

            for try await (symbol, articles) in group {
                results[symbol] = articles
            }
        }

        AppLogger.portfolio.info("Fetched news for \(results.count) symbols")
        return results
    }

    // MARK: - Utility Methods

    /// Get cache statistics
    func getCacheStats() -> CacheStats {
        let totalSymbols = memoryCache.count
        let freshSymbols = memoryCache.values.filter { !$0.isExpired }.count
        let expiredSymbols = totalSymbols - freshSymbols
        let totalArticles = memoryCache.values.reduce(0) { $0 + $1.articles.count }

        return CacheStats(
            totalSymbols: totalSymbols,
            freshSymbols: freshSymbols,
            expiredSymbols: expiredSymbols,
            totalArticles: totalArticles
        )
    }

    /// Get most recent cached symbols
    func getRecentCachedSymbols(limit: Int = 10) -> [String] {
        Array(memoryCache.values
            .sorted { $0.cachedAt > $1.cachedAt }
            .prefix(limit)
            .map { $0.symbol })
    }
}

// MARK: - CacheStats
struct CacheStats {
    let totalSymbols: Int
    let freshSymbols: Int
    let expiredSymbols: Int
    let totalArticles: Int

    var freshPercentage: Double {
        guard totalSymbols > 0 else { return 0 }
        return Double(freshSymbols) / Double(totalSymbols) * 100
    }
}

// MARK: - NewsError
enum NewsError: LocalizedError {
    case noArticlesFound
    case invalidURL
    case summarizationFailed

    var errorDescription: String? {
        switch self {
        case .noArticlesFound:
            return "No news articles found for this stock"
        case .invalidURL:
            return "Invalid article URL"
        case .summarizationFailed:
            return "Failed to generate article summary"
        }
    }
}
