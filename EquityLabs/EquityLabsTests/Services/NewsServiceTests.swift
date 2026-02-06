import XCTest
@testable import EquityLabs

final class NewsServiceTests: XCTestCase {

    // MARK: - NewsArticle Model Tests

    func testNewsArticleCreation() {
        let date = Date()
        let article = NewsArticle(
            id: "article-1",
            title: "Apple reports record earnings",
            url: "https://example.com/article",
            source: "Reuters",
            publishedAt: date,
            imageUrl: "https://example.com/image.jpg",
            sentiment: NewsSentiment(score: 0.8, label: .positive, confidence: 0.9),
            summary: "Apple reported record Q4 earnings."
        )

        XCTAssertEqual(article.id, "article-1")
        XCTAssertEqual(article.title, "Apple reports record earnings")
        XCTAssertEqual(article.url, "https://example.com/article")
        XCTAssertEqual(article.source, "Reuters")
        XCTAssertEqual(article.publishedAt, date)
        XCTAssertEqual(article.imageUrl, "https://example.com/image.jpg")
        XCTAssertNotNil(article.sentiment)
        XCTAssertEqual(article.summary, "Apple reported record Q4 earnings.")
    }

    func testNewsArticleOptionalFields() {
        let article = NewsArticle(
            title: "Test Article",
            url: "https://example.com",
            source: "Test Source",
            publishedAt: Date()
        )

        XCTAssertNil(article.imageUrl)
        XCTAssertNil(article.sentiment)
        XCTAssertNil(article.summary)
        XCTAssertFalse(article.id.isEmpty)
    }

    // MARK: - Sentiment Parsing

    func testSentimentLabels() {
        XCTAssertEqual(SentimentLabel.positive.rawValue, "positive")
        XCTAssertEqual(SentimentLabel.neutral.rawValue, "neutral")
        XCTAssertEqual(SentimentLabel.negative.rawValue, "negative")
    }

    func testSentimentLabelDisplayName() {
        XCTAssertEqual(SentimentLabel.positive.displayName, "Positive")
        XCTAssertEqual(SentimentLabel.neutral.displayName, "Neutral")
        XCTAssertEqual(SentimentLabel.negative.displayName, "Negative")
    }

    func testSentimentLabelEmoji() {
        XCTAssertFalse(SentimentLabel.positive.emoji.isEmpty)
        XCTAssertFalse(SentimentLabel.neutral.emoji.isEmpty)
        XCTAssertFalse(SentimentLabel.negative.emoji.isEmpty)
    }

    func testSentimentLabelAllCases() {
        XCTAssertEqual(SentimentLabel.allCases.count, 3)
    }

    func testNewsSentimentColor() {
        let positive = NewsSentiment(score: 0.5, label: .positive, confidence: 0.8)
        XCTAssertEqual(positive.color, "green")

        let neutral = NewsSentiment(score: 0.0, label: .neutral, confidence: 0.8)
        XCTAssertEqual(neutral.color, "gray")

        let negative = NewsSentiment(score: -0.5, label: .negative, confidence: 0.8)
        XCTAssertEqual(negative.color, "red")
    }

    func testSentimentScoreRange() {
        let sentiment = NewsSentiment(score: 0.8, label: .positive, confidence: 0.9)
        XCTAssertTrue(sentiment.score >= -1.0 && sentiment.score <= 1.0)
        XCTAssertTrue(sentiment.confidence >= 0.0 && sentiment.confidence <= 1.0)
    }

    // MARK: - Sentiment Decoding from String

    func testNewsArticleDecodesStringSentiment() throws {
        let json = """
        {
            "title": "Test",
            "link": "https://example.com",
            "source": "Test Source",
            "publishedAt": "2026-02-05T12:00:00Z",
            "sentiment": "positive"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let article = try decoder.decode(NewsArticle.self, from: json)

        XCTAssertNotNil(article.sentiment)
        XCTAssertEqual(article.sentiment?.label, .positive)
        XCTAssertEqual(article.sentiment?.score, 0.5)
    }

    func testNewsArticleDecodesNeutralSentiment() throws {
        let json = """
        {
            "title": "Test",
            "link": "https://example.com",
            "source": "Test Source",
            "publishedAt": "2026-02-05T12:00:00Z",
            "sentiment": "neutral"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let article = try decoder.decode(NewsArticle.self, from: json)

        XCTAssertNotNil(article.sentiment)
        XCTAssertEqual(article.sentiment?.label, .neutral)
        XCTAssertEqual(article.sentiment?.score, 0.0)
    }

    func testNewsArticleDecodesNegativeSentiment() throws {
        let json = """
        {
            "title": "Test",
            "link": "https://example.com",
            "source": "Test Source",
            "publishedAt": "2026-02-05T12:00:00Z",
            "sentiment": "negative"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let article = try decoder.decode(NewsArticle.self, from: json)

        XCTAssertNotNil(article.sentiment)
        XCTAssertEqual(article.sentiment?.label, .negative)
        XCTAssertEqual(article.sentiment?.score, -0.5)
    }

    func testNewsArticleDecodesNullSentiment() throws {
        let json = """
        {
            "title": "Test",
            "link": "https://example.com",
            "source": "Test Source",
            "publishedAt": "2026-02-05T12:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let article = try decoder.decode(NewsArticle.self, from: json)

        XCTAssertNil(article.sentiment)
    }

    // MARK: - Date Parsing

    func testNewsArticleDecodesISO8601Date() throws {
        let json = """
        {
            "title": "Test",
            "link": "https://example.com",
            "source": "Test",
            "publishedAt": "2026-02-05T12:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let article = try decoder.decode(NewsArticle.self, from: json)

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: article.publishedAt)
        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 2)
        XCTAssertEqual(components.day, 5)
    }

    func testNewsArticleDecodesRFC2822Date() throws {
        let json = """
        {
            "title": "Test",
            "link": "https://example.com",
            "source": "Test",
            "publishedAt": "Wed, 05 Feb 2026 12:00:00 GMT"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let article = try decoder.decode(NewsArticle.self, from: json)

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: article.publishedAt)
        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 2)
        XCTAssertEqual(components.day, 5)
    }

    // MARK: - CachedNews Expiration

    func testCachedNewsNotExpired() {
        let cached = CachedNews(
            articles: [],
            symbol: "AAPL",
            cachedAt: Date()
        )
        XCTAssertFalse(cached.isExpired)
    }

    func testCachedNewsExpiredAfterSixHours() {
        let sevenHoursAgo = Date().addingTimeInterval(-7 * 60 * 60)
        let cached = CachedNews(
            articles: [],
            symbol: "AAPL",
            cachedAt: sevenHoursAgo
        )
        XCTAssertTrue(cached.isExpired)
    }

    func testCachedNewsNotExpiredAtFiveHours() {
        let fiveHoursAgo = Date().addingTimeInterval(-5 * 60 * 60)
        let cached = CachedNews(
            articles: [],
            symbol: "AAPL",
            cachedAt: fiveHoursAgo
        )
        XCTAssertFalse(cached.isExpired)
    }

    // MARK: - CachedNews Codable

    func testCachedNewsCodable() throws {
        let articles = [
            NewsArticle(
                title: "Test Article",
                url: "https://example.com",
                source: "Test",
                publishedAt: Date()
            )
        ]

        let cached = CachedNews(articles: articles, symbol: "AAPL")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(cached)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(CachedNews.self, from: data)

        XCTAssertEqual(decoded.symbol, "AAPL")
        XCTAssertEqual(decoded.articles.count, 1)
        XCTAssertEqual(decoded.articles.first?.title, "Test Article")
    }

    // MARK: - NewsResponse

    func testNewsResponseDecoding() throws {
        let json = """
        {
            "articles": [
                {
                    "title": "Test",
                    "link": "https://example.com",
                    "source": "Reuters",
                    "publishedAt": "2026-02-05T12:00:00Z"
                }
            ],
            "count": 1,
            "symbol": "AAPL"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(NewsResponse.self, from: json)

        XCTAssertEqual(response.articles.count, 1)
        XCTAssertEqual(response.count, 1)
        XCTAssertEqual(response.symbol, "AAPL")
    }

    func testNewsResponseWithoutCount() throws {
        let json = """
        {
            "articles": [
                {
                    "title": "Test",
                    "link": "https://example.com",
                    "source": "Reuters",
                    "publishedAt": "2026-02-05T12:00:00Z"
                },
                {
                    "title": "Test 2",
                    "link": "https://example.com/2",
                    "source": "Bloomberg",
                    "publishedAt": "2026-02-05T13:00:00Z"
                }
            ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(NewsResponse.self, from: json)

        XCTAssertEqual(response.articles.count, 2)
        // count should default to articles.count
        XCTAssertEqual(response.count, 2)
    }
}
