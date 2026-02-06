import Foundation
import Combine

// MARK: - PortfolioSyncManager
/// Orchestrates portfolio sync between local Core Data and remote API.
/// Handles last-sync tracking, foreground refresh, and offline mutation queuing.
@MainActor
class PortfolioSyncManager: ObservableObject {
    static let shared = PortfolioSyncManager()

    private let portfolioService = PortfolioService.shared
    private let repository = PortfolioRepository.shared

    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var pendingMutationCount: Int = 0

    private let lastSyncKey = Constants.UserDefaultsKeys.lastSyncDate
    private let mutationQueueKey = "pending_mutations_queue"
    private let staleness: TimeInterval = 5 * 60 // 5 minutes

    private init() {
        lastSyncDate = UserDefaults.standard.object(forKey: lastSyncKey) as? Date
        pendingMutationCount = loadMutationQueue().count
    }

    // MARK: - Sync If Needed

    /// Sync portfolio if data is stale (>5 min since last sync).
    /// Call this on app foreground.
    func syncIfNeeded() async {
        guard !isSyncing else { return }

        if let last = lastSyncDate, Date().timeIntervalSince(last) < staleness {
            AppLogger.portfolio.debug("Sync not needed — last sync \(last)")
            return
        }

        await fullSync()
    }

    // MARK: - Full Sync

    /// Perform a full sync: reload portfolio from API, save to Core Data, replay pending mutations.
    func fullSync() async {
        guard !isSyncing else { return }

        isSyncing = true
        defer { isSyncing = false }

        AppLogger.portfolio.info("Starting full portfolio sync...")

        // 1. Replay any pending offline mutations first
        await replayPendingMutations()

        // 2. Pull latest from API (source of truth)
        do {
            let portfolio = try await portfolioService.loadPortfolio()
            AppLogger.portfolio.info("Sync complete — \(portfolio.stocks.count) stocks")
            recordSync()
        } catch {
            AppLogger.portfolio.error("Sync failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Record Sync Timestamp

    private func recordSync() {
        let now = Date()
        lastSyncDate = now
        UserDefaults.standard.set(now, forKey: lastSyncKey)
    }

    // MARK: - Offline Mutation Queue

    /// Queue a mutation for later replay when offline.
    func queueMutation(_ mutation: PendingMutation) {
        var queue = loadMutationQueue()
        queue.append(mutation)
        saveMutationQueue(queue)
        pendingMutationCount = queue.count
        AppLogger.portfolio.info("Queued offline mutation: \(mutation.type.rawValue) — \(queue.count) pending")
    }

    /// Replay all pending mutations against the API.
    func replayPendingMutations() async {
        var queue = loadMutationQueue()
        guard !queue.isEmpty else { return }

        AppLogger.portfolio.info("Replaying \(queue.count) pending mutations...")

        var remaining: [PendingMutation] = []

        for mutation in queue {
            do {
                try await executeMutation(mutation)
                AppLogger.portfolio.debug("Replayed mutation: \(mutation.type.rawValue)")
            } catch {
                AppLogger.portfolio.warning("Mutation replay failed, keeping in queue: \(error.localizedDescription)")
                remaining.append(mutation)
            }
        }

        saveMutationQueue(remaining)
        pendingMutationCount = remaining.count
    }

    private func executeMutation(_ mutation: PendingMutation) async throws {
        switch mutation.type {
        case .addStock:
            if let stock = mutation.stock {
                try await portfolioService.addStock(stock)
            }
        case .deleteStock:
            if let symbol = mutation.symbol {
                try await portfolioService.deleteStock(symbol: symbol)
            }
        case .updateStock:
            if let stock = mutation.stock {
                try await portfolioService.updateStock(stock)
            }
        }
    }

    // MARK: - Persistence (UserDefaults)

    private func loadMutationQueue() -> [PendingMutation] {
        guard let data = UserDefaults.standard.data(forKey: mutationQueueKey),
              let queue = try? JSONDecoder().decode([PendingMutation].self, from: data) else {
            return []
        }
        return queue
    }

    private func saveMutationQueue(_ queue: [PendingMutation]) {
        if let data = try? JSONEncoder().encode(queue) {
            UserDefaults.standard.set(data, forKey: mutationQueueKey)
        }
    }

    /// Clear the mutation queue (e.g., on sign-out).
    func clearQueue() {
        UserDefaults.standard.removeObject(forKey: mutationQueueKey)
        pendingMutationCount = 0
    }
}

// MARK: - PendingMutation

struct PendingMutation: Codable, Identifiable {
    let id: String
    let type: MutationType
    let stock: Stock?
    let symbol: String?
    let createdAt: Date

    init(type: MutationType, stock: Stock? = nil, symbol: String? = nil) {
        self.id = UUID().uuidString
        self.type = type
        self.stock = stock
        self.symbol = symbol
        self.createdAt = Date()
    }
}

// MARK: - MutationType

enum MutationType: String, Codable {
    case addStock
    case deleteStock
    case updateStock
}
