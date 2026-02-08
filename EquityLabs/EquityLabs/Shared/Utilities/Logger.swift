import Foundation
import OSLog

// MARK: - AppLogger
struct AppLogger {
    private let logger: Logger

    init(category: String) {
        self.logger = Logger(subsystem: Constants.App.bundleId, category: category)
    }

    func debug(_ message: String) {
        #if DEBUG
        logger.debug("\(message)")
        #endif
    }

    func info(_ message: String) {
        logger.info("\(message)")
    }

    func notice(_ message: String) {
        logger.notice("\(message)")
    }

    func warning(_ message: String) {
        logger.warning("\(message)")
    }

    func error(_ message: String) {
        logger.error("\(message)")
    }

    func critical(_ message: String) {
        logger.critical("\(message)")
    }
}

// MARK: - Log Categories
extension AppLogger {
    static let networking = AppLogger(category: "Networking")
    static let authentication = AppLogger(category: "Authentication")
    static let persistence = AppLogger(category: "Persistence")
    static let portfolio = AppLogger(category: "Portfolio")
    static let subscription = AppLogger(category: "Subscription")
    static let background = AppLogger(category: "Background")
    static let settings = AppLogger(category: "Settings")
    static let ui = AppLogger(category: "UI")
}
