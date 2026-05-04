import Foundation
import SwiftData

public enum SharedStore {
    public static let appGroupID = "group.com.angelinawu.selfshelf.shared"
    public static let storeFileName = "SelfShelf.store"

    public static var containerURL: URL {
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            return url
        }
        let fallback = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: fallback, withIntermediateDirectories: true)
        return fallback
    }

    public static var storeURL: URL {
        containerURL.appending(path: storeFileName)
    }

    @MainActor
    public static let shared: ModelContainer = {
        let schema = Schema([Shelf.self, Book.self])
        let config = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Fallback to in-memory if the shared container fails (e.g. entitlement missing in preview)
            let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: [memoryConfig])
        }
    }()
}
