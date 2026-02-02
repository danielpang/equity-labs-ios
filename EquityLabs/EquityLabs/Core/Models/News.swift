import Foundation

// MARK: - NewsArticle
struct NewsArticle: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let url: String
    let source: String
    let publishedAt: Date
    let imageUrl: String?
    var sentiment: NewsSentiment?
    var summary: String?

    init(id: String = UUID().uuidString,
         title: String,
         url: String,
         source: String,
         publishedAt: Date,
         imageUrl: String? = nil,
         sentiment: NewsSentiment? = nil,
         summary: String? = nil) {
        self.id = id
        self.title = title
        self.url = url
        self.source = source
        self.publishedAt = publishedAt
        self.imageUrl = imageUrl
        self.sentiment = sentiment
        self.summary = summary
    }

    enum CodingKeys: String, CodingKey {
        case id, title, url, source, publishedAt, imageUrl, sentiment, summary
    }
}

// MARK: - NewsSentiment
struct NewsSentiment: Codable, Hashable {
    let score: Double // -1.0 to 1.0
    let label: SentimentLabel
    let confidence: Double // 0.0 to 1.0

    var color: String {
        switch label {
        case .positive: return "green"
        case .neutral: return "gray"
        case .negative: return "red"
        }
    }

    init(score: Double, label: SentimentLabel, confidence: Double) {
        self.score = score
        self.label = label
        self.confidence = confidence
    }
}

// MARK: - SentimentLabel
enum SentimentLabel: String, Codable, CaseIterable {
    case positive = "positive"
    case neutral = "neutral"
    case negative = "negative"

    var displayName: String {
        rawValue.capitalized
    }

    var emoji: String {
        switch self {
        case .positive: return "📈"
        case .neutral: return "➖"
        case .negative: return "📉"
        }
    }
}

// MARK: - NewsResponse
struct NewsResponse: Codable {
    let articles: [NewsArticle]
    let count: Int
    let symbol: String?

    init(articles: [NewsArticle], count: Int, symbol: String? = nil) {
        self.articles = articles
        self.count = count
        self.symbol = symbol
    }
}

// MARK: - NewsSummaryRequest
struct NewsSummaryRequest: Codable {
    let url: String
}

// MARK: - NewsSummaryResponse
struct NewsSummaryResponse: Codable {
    let summary: String
    let url: String
}

// MARK: - CachedNews
struct CachedNews: Codable {
    let articles: [NewsArticle]
    let cachedAt: Date
    let symbol: String

    var isExpired: Bool {
        let sixHours: TimeInterval = 6 * 60 * 60
        return Date().timeIntervalSince(cachedAt) > sixHours
    }

    init(articles: [NewsArticle], symbol: String, cachedAt: Date = Date()) {
        self.articles = articles
        self.cachedAt = cachedAt
        self.symbol = symbol
    }
}
