import AppIntents
import Foundation
import SwiftData

public struct ShelfEntity: AppEntity, Identifiable, Hashable {
    public static var typeDisplayRepresentation: TypeDisplayRepresentation = "Shelf"
    public static var defaultQuery = ShelfEntityQuery()

    public var id: UUID
    public var name: String

    public init(id: UUID, name: String) {
        self.id = id
        self.name = name
    }

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

public struct ShelfEntityQuery: EntityQuery {
    public init() {}

    @MainActor
    public func entities(for identifiers: [UUID]) async throws -> [ShelfEntity] {
        let ctx = SharedStore.shared.mainContext
        let descriptor = FetchDescriptor<Shelf>(predicate: #Predicate { identifiers.contains($0.id) })
        let shelves = (try? ctx.fetch(descriptor)) ?? []
        return shelves.map { ShelfEntity(id: $0.id, name: $0.name) }
    }

    @MainActor
    public func suggestedEntities() async throws -> [ShelfEntity] {
        try await allShelves()
    }

    @MainActor
    public func defaultResult() async -> ShelfEntity? {
        (try? await allShelves())?.first
    }

    @MainActor
    private func allShelves() async throws -> [ShelfEntity] {
        let ctx = SharedStore.shared.mainContext
        let descriptor = FetchDescriptor<Shelf>(sortBy: [SortDescriptor(\.sortIndex), SortDescriptor(\.createdAt)])
        let shelves = (try? ctx.fetch(descriptor)) ?? []
        return shelves.map { ShelfEntity(id: $0.id, name: $0.name) }
    }
}

public struct SelectShelfIntent: WidgetConfigurationIntent {
    public static var title: LocalizedStringResource = "Select Shelf"
    public static var description = IntentDescription("Pick which shelf to display.")

    @Parameter(title: "Shelf")
    public var shelf: ShelfEntity?

    public init() {}
    public init(shelf: ShelfEntity?) { self.shelf = shelf }
}
