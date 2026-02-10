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

        // Handle sentiment - API may return simple string, full object, or nothing
        if let sentimentString = try? container.decode(String.self, forKey: .sentiment) {
            // API returns simple string like "neutral", "Positive", "NEGATIVE", etc.
            if let label = SentimentLabel(caseInsensitive: sentimentString) {
                let score: Double
                switch label {
                case .positive: score = 0.5
                case .neutral: score = 0.0
                case .negative: score = -0.5
                }
                self.sentiment = NewsSentiment(score: score, label: label, confidence: 0.5)
            } else {
                #if DEBUG
                print("⚠️ Unknown sentiment string: '\(sentimentString)'")
                #endif
                self.sentiment = nil
            }
        } else if let sentimentObj = try? container.decode(NewsSentiment.self, forKey: .sentiment) {
            self.sentiment = sentimentObj
        } else {
            #if DEBUG
            print("⚠️ No sentiment decoded for article: \(self.title.prefix(50))")
            #endif
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.label = try container.decode(SentimentLabel.self, forKey: .label)
        self.score = (try? container.decode(Double.self, forKey: .score)) ?? 0.0
        self.confidence = (try? container.decode(Double.self, forKey: .confidence)) ?? 0.5
    }

    enum CodingKeys: String, CodingKey {
        case score, label, confidence
    }
}

// MARK: - SentimentLabel
enum SentimentLabel: String, Codable, CaseIterable {
    case positive = "positive"
    case neutral = "neutral"
    case negative = "negative"

    /// Case-insensitive initializer to handle "Positive", "POSITIVE", etc.
    init?(caseInsensitive value: String) {
        self.init(rawValue: value.lowercased())
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawString = try container.decode(String.self)
        guard let label = SentimentLabel(caseInsensitive: rawString) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown sentiment label: \(rawString)")
        }
        self = label
    }

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
    let cachedAt: String?
    let expiresAt: String?
    let hasSentiment: Bool

    var count: Int { articles.count }

    init(articles: [NewsArticle], hasSentiment: Bool = false, cachedAt: String? = nil, expiresAt: String? = nil) {
        self.articles = articles
        self.hasSentiment = hasSentiment
        self.cachedAt = cachedAt
        self.expiresAt = expiresAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.articles = try container.decode([NewsArticle].self, forKey: .articles)
        self.cachedAt = try? container.decode(String.self, forKey: .cachedAt)
        self.expiresAt = try? container.decode(String.self, forKey: .expiresAt)
        self.hasSentiment = (try? container.decode(Bool.self, forKey: .hasSentiment)) ?? false
    }

    enum CodingKeys: String, CodingKey {
        case articles, cachedAt, expiresAt, hasSentiment
    }
}

// MARK: - NewsSummaryRequest
struct NewsSummaryRequest: Codable {
    let articleUrl: String
    let articleTitle: String
    let source: String
}

// MARK: - NewsSummaryResponse
struct NewsSummaryResponse: Codable {
    let summary: String
    let cachedAt: String?
}

// MARK: - CachedNews
struct CachedNews: Codable {
    let articles: [NewsArticle]
    let cachedAt: Date
    let symbol: String
    let hasSentiment: Bool

    var isExpired: Bool {
        let sixHours: TimeInterval = 6 * 60 * 60
        return Date().timeIntervalSince(cachedAt) > sixHours
    }

    init(articles: [NewsArticle], symbol: String, hasSentiment: Bool = false, cachedAt: Date = Date()) {
        self.articles = articles
        self.cachedAt = cachedAt
        self.symbol = symbol
        self.hasSentiment = hasSentiment
    }
}
