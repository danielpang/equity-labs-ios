import Foundation
import CoreData
import Combine

// MARK: - PortfolioRepository
/// Repository layer for portfolio Core Data operations
@MainActor
class PortfolioRepository: ObservableObject {
    static let shared = PortfolioRepository()

    private let persistenceController = PersistenceController.shared

    private var viewContext: NSManagedObjectContext {
        persistenceController.viewContext
    }

    private init() {}

    // MARK: - Fetch Operations

    /// Fetch all stocks in the portfolio
    func fetchAllStocks() throws -> [Stock] {
        let request = StockEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \StockEntity.symbol, ascending: true)]

        let entities = try viewContext.fetch(request)
        return entities.compactMap { entity in
            convertToStock(from: entity)
        }
    }

    /// Fetch a specific stock by symbol
    func fetchStock(symbol: String) throws -> Stock? {
        let request = StockEntity.fetchRequest()
        request.predicate = NSPredicate(format: "symbol == %@", symbol)
        request.fetchLimit = 1

        guard let entity = try viewContext.fetch(request).first else {
            return nil
        }

        return convertToStock(from: entity)
    }

    /// Fetch a stock by ID
    func fetchStock(id: String) throws -> Stock? {
        let request = StockEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1

        guard let entity = try viewContext.fetch(request).first else {
            return nil
        }

        return convertToStock(from: entity)
    }

    // MARK: - Save Operations

    /// Save or update a stock with its lots
    func saveStock(_ stock: Stock) throws {
        // Check if stock already exists
        let request = StockEntity.fetchRequest()
        request.predicate = NSPredicate(format: "symbol == %@", stock.symbol)

        let existingEntity = try viewContext.fetch(request).first
        let stockEntity = existingEntity ?? StockEntity(context: viewContext)

        // Update stock properties
        stockEntity.id = stock.id
        stockEntity.symbol = stock.symbol
        stockEntity.name = stock.name
        stockEntity.currency = stock.currency
        stockEntity.currentPrice = stock.currentPrice ?? 0
        stockEntity.previousClose = stock.previousClose ?? 0
        stockEntity.lastUpdated = stock.lastUpdated

        // Save lots
        for lot in stock.lots {
            try saveLot(lot, for: stockEntity)
        }

        try persistenceController.saveContext(viewContext)
        AppLogger.portfolio.info("Saved stock: \(stock.symbol)")
    }

    /// Save a lot for a stock
    private func saveLot(_ lot: StockLot, for stockEntity: StockEntity) throws {
        // Check if lot exists
        let request = StockLotEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", lot.id)

        let lotEntity = try viewContext.fetch(request).first ?? StockLotEntity(context: viewContext)

        lotEntity.id = lot.id
        lotEntity.shares = lot.shares
        lotEntity.pricePerShare = lot.pricePerShare
        lotEntity.purchaseDate = lot.purchaseDate
        lotEntity.currency = lot.currency
        lotEntity.notes = lot.notes
        lotEntity.stock = stockEntity
    }

    /// Save multiple stocks (bulk operation)
    func saveStocks(_ stocks: [Stock]) throws {
        for stock in stocks {
            try saveStock(stock)
        }
        AppLogger.portfolio.info("Saved \(stocks.count) stocks")
    }

    /// Update stock prices
    func updateStockPrice(symbol: String, currentPrice: Double, previousClose: Double) throws {
        let request = StockEntity.fetchRequest()
        request.predicate = NSPredicate(format: "symbol == %@", symbol)

        guard let stockEntity = try viewContext.fetch(request).first else {
            throw PortfolioRepositoryError.stockNotFound(symbol)
        }

        stockEntity.currentPrice = currentPrice
        stockEntity.previousClose = previousClose
        stockEntity.lastUpdated = Date()

        try persistenceController.saveContext(viewContext)
        AppLogger.portfolio.debug("Updated price for \(symbol)")
    }

    // MARK: - Delete Operations

    /// Delete a stock and all its lots
    func deleteStock(symbol: String) throws {
        let request = StockEntity.fetchRequest()
        request.predicate = NSPredicate(format: "symbol == %@", symbol)

        guard let stockEntity = try viewContext.fetch(request).first else {
            throw PortfolioRepositoryError.stockNotFound(symbol)
        }

        viewContext.delete(stockEntity)
        try persistenceController.saveContext(viewContext)

        AppLogger.portfolio.info("Deleted stock: \(symbol)")
    }

    /// Delete a specific lot
    func deleteLot(id: String) throws {
        let request = StockLotEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)

        guard let lotEntity = try viewContext.fetch(request).first else {
            throw PortfolioRepositoryError.lotNotFound(id)
        }

        viewContext.delete(lotEntity)
        try persistenceController.saveContext(viewContext)

        AppLogger.portfolio.info("Deleted lot: \(id)")
    }

    /// Delete all portfolio data
    func deleteAll() throws {
        try persistenceController.deleteAll(StockEntity.self)
        try persistenceController.deleteAll(StockLotEntity.self)
        AppLogger.portfolio.warning("Deleted all portfolio data")
    }

    // MARK: - Statistics

    /// Get total count of stocks
    func getStockCount() throws -> Int {
        let request = StockEntity.fetchRequest()
        return try viewContext.count(for: request)
    }

    /// Get total portfolio value in a specific currency
    func getTotalValue(in currency: Currency) throws -> Double {
        let stocks = try fetchAllStocks()
        return stocks.reduce(0) { total, stock in
            let stockValue = stock.lots.reduce(0) { lotTotal, lot in
                lotTotal + (lot.shares * lot.pricePerShare)
            }
            // Note: Currency conversion is handled at the service layer (PortfolioService.getPortfolioValue)
            return total + stockValue
        }
    }

    // MARK: - Conversion Helpers

    /// Convert StockEntity to Stock model
    private func convertToStock(from entity: StockEntity) -> Stock? {
        guard let id = entity.id,
              let symbol = entity.symbol,
              let name = entity.name,
              let currency = entity.currency else {
            AppLogger.portfolio.error("Failed to convert StockEntity to Stock - missing required fields")
            return nil
        }

        // Convert lots
        let lotsSet = entity.lots as? Set<StockLotEntity> ?? []
        let lots = lotsSet.compactMap { convertToStockLot(from: $0) }

        return Stock(
            id: id,
            symbol: symbol,
            name: name,
            lots: lots,
            currentPrice: entity.currentPrice,
            previousClose: entity.previousClose,
            currency: currency,
            lastUpdated: entity.lastUpdated
        )
    }

    /// Convert StockLotEntity to StockLot model
    private func convertToStockLot(from entity: StockLotEntity) -> StockLot? {
        guard let id = entity.id,
              let purchaseDate = entity.purchaseDate,
              let currency = entity.currency else {
            AppLogger.portfolio.error("Failed to convert StockLotEntity to StockLot")
            return nil
        }

        return StockLot(
            id: id,
            shares: entity.shares,
            pricePerShare: entity.pricePerShare,
            purchaseDate: purchaseDate,
            currency: currency,
            notes: entity.notes
        )
    }

    // MARK: - Background Operations

    /// Perform operations on background context
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        let context = persistenceController.backgroundContext()

        return try await context.perform {
            let result = try block(context)

            if context.hasChanges {
                try context.save()
            }

            return result
        }
    }
}

// MARK: - PortfolioRepositoryError

enum PortfolioRepositoryError: LocalizedError {
    case stockNotFound(String)
    case lotNotFound(String)
    case saveFailed(Error)
    case fetchFailed(Error)

    var errorDescription: String? {
        switch self {
        case .stockNotFound(let symbol):
            return "Stock not found: \(symbol)"
        case .lotNotFound(let id):
            return "Lot not found: \(id)"
        case .saveFailed(let error):
            return "Save failed: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Fetch failed: \(error.localizedDescription)"
        }
    }
}
