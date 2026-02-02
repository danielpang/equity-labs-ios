import CoreData
import Foundation
import Combine

// MARK: - PersistenceController
class PersistenceController: ObservableObject {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    // MARK: - Initialization
    private init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "EquityLabs")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Preview
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.viewContext

        // Create sample data for previews
        for i in 0..<5 {
            let stock = StockEntity(context: context)
            stock.id = UUID().uuidString
            stock.symbol = ["AAPL", "GOOGL", "MSFT", "TSLA", "AMZN"][i]
            stock.name = ["Apple Inc.", "Alphabet Inc.", "Microsoft Corp.", "Tesla Inc.", "Amazon.com Inc."][i]
            stock.currency = "USD"
            stock.currentPrice = [150.0, 2800.0, 350.0, 800.0, 3300.0][i]
            stock.previousClose = [148.0, 2750.0, 345.0, 790.0, 3250.0][i]
            stock.lastUpdated = Date()

            let lot = StockLotEntity(context: context)
            lot.id = UUID().uuidString
            lot.shares = 10.0
            lot.pricePerShare = [140.0, 2700.0, 340.0, 780.0, 3200.0][i]
            lot.purchaseDate = Date()
            lot.currency = "USD"
            lot.stock = stock
        }

        do {
            try context.save()
        } catch {
            print("Failed to save preview data: \(error)")
        }

        return controller
    }()

    // MARK: - Background Context
    func backgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    // MARK: - Save Context
    func saveContext() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Failed to save context: \(nsError), \(nsError.userInfo)")
            }
        }
    }

    func saveContext(_ context: NSManagedObjectContext) throws {
        if context.hasChanges {
            try context.save()
        }
    }

    // MARK: - Fetch
    func fetch<T: NSManagedObject>(_ request: NSFetchRequest<T>) throws -> [T] {
        return try viewContext.fetch(request)
    }

    func fetchInBackground<T: NSManagedObject>(_ request: NSFetchRequest<T>) async throws -> [T] {
        let context = backgroundContext()
        return try await context.perform {
            try context.fetch(request)
        }
    }

    // MARK: - Delete
    func delete(_ object: NSManagedObject) {
        viewContext.delete(object)
        saveContext()
    }

    func deleteAll<T: NSManagedObject>(_ type: T.Type) throws {
        let fetchRequest = NSFetchRequest<T>(entityName: String(describing: type))
        let objects = try viewContext.fetch(fetchRequest)
        objects.forEach { viewContext.delete($0) }
        saveContext()
    }

    // MARK: - Reset
    func reset() throws {
        try deleteAll(StockEntity.self)
        try deleteAll(StockLotEntity.self)
        try deleteAll(HistoricalDataEntity.self)
        try deleteAll(CachedNewsEntity.self)
    }
}
