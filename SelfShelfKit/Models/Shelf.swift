import Foundation
import SwiftData

@Model
public final class Shelf {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var createdAt: Date
    public var sortIndex: Int

    public var backgroundColorHex: String
    public var accentColorHex: String
    public var presetRaw: String

    @Relationship(deleteRule: .cascade, inverse: \Book.shelf)
    public var books: [Book] = []

    public init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = .now,
        sortIndex: Int = 0,
        backgroundColorHex: String = ShelfStyle.defaultBackgroundHex,
        accentColorHex: String = ShelfStyle.defaultAccentHex,
        preset: StylePreset = .flat
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.sortIndex = sortIndex
        self.backgroundColorHex = backgroundColorHex
        self.accentColorHex = accentColorHex
        self.presetRaw = preset.rawValue
    }

    public var preset: StylePreset {
        get { StylePreset(rawValue: presetRaw) ?? .flat }
        set { presetRaw = newValue.rawValue }
    }

    public var orderedBooks: [Book] {
        books.sorted { $0.order < $1.order }
    }
}

public enum StylePreset: String, CaseIterable, Codable, Sendable {
    case flat
    case gradient
    case bordered

    public var displayName: String {
        switch self {
        case .flat: return "Flat"
        case .gradient: return "Gradient"
        case .bordered: return "Bordered"
        }
    }
}

public enum ShelfStyle {
    public static let defaultBackgroundHex = "#E9E2D3"
    public static let defaultAccentHex = "#2B2A27"

    public static let palette: [(name: String, hex: String)] = [
        ("Bone",      "#EFE9DC"),
        ("Sage",      "#B8C3A9"),
        ("Terracotta","#C97E5B"),
        ("Butter",    "#EED79A"),
        ("Denim",     "#5E7AA3"),
        ("Plum",      "#6E4B6E"),
        ("Ink",       "#2B2A27"),
        ("Paper",     "#F5F1E6"),
    ]
}
