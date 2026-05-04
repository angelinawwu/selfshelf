import Foundation
import SwiftData

@Model
public final class Book {
    @Attribute(.unique) public var id: UUID
    public var olid: String
    public var title: String
    public var authors: [String]
    public var coverId: Int?
    public var firstPublishYear: Int?
    public var addedAt: Date
    public var order: Int
    public var shelf: Shelf?

    public init(
        id: UUID = UUID(),
        olid: String,
        title: String,
        authors: [String],
        coverId: Int? = nil,
        firstPublishYear: Int? = nil,
        addedAt: Date = .now,
        order: Int = 0
    ) {
        self.id = id
        self.olid = olid
        self.title = title
        self.authors = authors
        self.coverId = coverId
        self.firstPublishYear = firstPublishYear
        self.addedAt = addedAt
        self.order = order
    }

    public var authorLine: String {
        authors.isEmpty ? "Unknown" : authors.joined(separator: ", ")
    }
}
