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
        case id
        case title
        case url = "link"  // API uses "link"
        case source
        case publishedAt
        case imageUrl
        case sentiment
        case summary
    }

    // Custom decoder to handle API format
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Generate ID if not provided by API
        self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString

        self.title = try container.decode(String.self, forKey: .title)
        self.url = try container.decode(String.self, forKey: .url)
        self.source = try container.decode(String.self, forKey: .source)
        self.imageUrl = try? container.decode(String.self, forKey: .imageUrl)
        self.summary = try? container.decode(String.self, forKey: .summary)

        // Handle publishedAt - try multiple date formats
        if let dateString = try? container.decode(String.self, forKey: .publishedAt) {
            // Try RFC2822 format first (e.g., "Wed, 04 Feb 2026 23:59:09 GMT")
            let rfc2822Formatter = DateFormatter()
            rfc2822Formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
            rfc2822Formatter.locale = Locale(identifier: "en_US_POSIX")

            if let date = rfc2822Formatter.date(from: dateString) {
                self.publishedAt = date
            } else {
                // Try ISO8601 as fallback
                let iso8601Formatter = ISO8601DateFormatter()
                self.publishedAt = iso8601Formatter.date(from: dateString) ?? Date()
            }
        } else {
            self.publishedAt = Date()
        }

        // Handle sentiment - API returns simple string or full object
        if let sentimentString = try? container.decode(String.self, forKey: .sentiment) {
            // API returns simple string like "neutral", "positive", "negative"
            if let label = SentimentLabel(rawValue: sentimentString) {
                // Create a simple NewsSentiment from the label
                let score: Double
                switch label {
                case .positive: score = 0.5
                case .neutral: score = 0.0
                case .negative: score = -0.5
                }
                self.sentiment = NewsSentiment(score: score, label: label, confidence: 0.5)
            } else {
                self.sentiment = nil
            }
        } else if let sentimentObj = try? container.decode(NewsSentiment.self, forKey: .sentiment) {
            self.sentiment = sentimentObj
        } else {
            self.sentiment = nil
        }
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

    // Custom decoder to handle API format
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.articles = try container.decode([NewsArticle].self, forKey: .articles)
        // Compute count from articles array if not provided by API
        self.count = (try? container.decode(Int.self, forKey: .count)) ?? articles.count
        self.symbol = try? container.decode(String.self, forKey: .symbol)
    }

    enum CodingKeys: String, CodingKey {
        case articles, count, symbol
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
