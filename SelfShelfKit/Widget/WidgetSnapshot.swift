import Foundation

public struct ShelfSnapshot: Sendable, Hashable {
    public let id: UUID
    public let name: String
    public let backgroundColorHex: String
    public let accentColorHex: String
    public let preset: StylePreset
    public let books: [BookSnapshot]

    public init(id: UUID, name: String, backgroundColorHex: String, accentColorHex: String, preset: StylePreset, books: [BookSnapshot]) {
        self.id = id
        self.name = name
        self.backgroundColorHex = backgroundColorHex
        self.accentColorHex = accentColorHex
        self.preset = preset
        self.books = books
    }

    public static let placeholder = ShelfSnapshot(
        id: UUID(),
        name: "Favorites",
        backgroundColorHex: ShelfStyle.defaultBackgroundHex,
        accentColorHex: ShelfStyle.defaultAccentHex,
        preset: .flat,
        books: (0..<6).map { BookSnapshot(olid: "placeholder\($0)", title: "Book", coverId: nil) }
    )
}

public struct BookSnapshot: Sendable, Hashable, Identifiable {
    public var id: String { olid }
    public let olid: String
    public let title: String
    public let coverId: Int?

    public init(olid: String, title: String, coverId: Int?) {
        self.olid = olid
        self.title = title
        self.coverId = coverId
    }
}

public extension Shelf {
    func snapshot(limit: Int = 20) -> ShelfSnapshot {
        ShelfSnapshot(
            id: id,
            name: name,
            backgroundColorHex: backgroundColorHex,
            accentColorHex: accentColorHex,
            preset: preset,
            books: orderedBooks.prefix(limit).map { BookSnapshot(olid: $0.olid, title: $0.title, coverId: $0.coverId) }
        )
    }
}
