import SwiftUI

// Shared widget views. Used by the actual WidgetKit extension AND by the
// in-app preview cards so what the user sees inside SelfShelf matches the
// home-screen widget exactly.

public struct ShelfWidgetSmallView: View {
    public let snapshot: ShelfSnapshot
    public init(snapshot: ShelfSnapshot) { self.snapshot = snapshot }
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ShelfWidgetHeader(snapshot: snapshot, compact: true)
            Spacer(minLength: 0)
            ShelfWidgetRow(snapshot: snapshot, books: snapshot.books.prefix(3))
        }
    }
}

public struct ShelfWidgetMediumView: View {
    public let snapshot: ShelfSnapshot
    public init(snapshot: ShelfSnapshot) { self.snapshot = snapshot }
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ShelfWidgetHeader(snapshot: snapshot, compact: true)
            Spacer(minLength: 0)
            ShelfWidgetRow(snapshot: snapshot, books: snapshot.books.prefix(7))
        }
    }
}

public struct ShelfWidgetLargeView: View {
    public let snapshot: ShelfSnapshot
    public init(snapshot: ShelfSnapshot) { self.snapshot = snapshot }
    public var body: some View {
        let all = snapshot.books
        let first = all.prefix(6)
        let second = all.dropFirst(6).prefix(6)
        VStack(alignment: .leading, spacing: 12) {
            ShelfWidgetHeader(snapshot: snapshot, compact: false)
            Spacer(minLength: 0)
            ShelfWidgetRow(snapshot: snapshot, books: first)
            Spacer(minLength: 0)
            ShelfWidgetRow(snapshot: snapshot, books: second)
        }
    }
}

private struct ShelfWidgetHeader: View {
    let snapshot: ShelfSnapshot
    let compact: Bool
    var body: some View {
        let ink = Color(hex: snapshot.backgroundColorHex).contrastingInk()
        HStack(alignment: .firstTextBaseline) {
            Text(snapshot.name)
                .font(.serif(compact ? 15 : 18))
                .foregroundStyle(ink)
                .lineLimit(1)
            Spacer(minLength: 4)
            Text("\(snapshot.books.count) \(snapshot.books.count == 1 ? "BOOK" : "BOOKS")")
                .font(.mono(9))
                .tracking(1.0)
                .opacity(0.7)
                .foregroundStyle(ink)
        }
    }
}

private struct ShelfWidgetRow: View {
    let snapshot: ShelfSnapshot
    let books: ArraySlice<BookSnapshot>
    var body: some View {
        let tint = Color(hex: snapshot.backgroundColorHex).contrastingInk().opacity(0.9)
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 4) {
                if books.isEmpty {
                    Text("Empty shelf")
                        .font(.mono(9)).tracking(1.0).opacity(0.7)
                        .foregroundStyle(tint)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ForEach(Array(books)) { book in
                        Link(destination: URL(string: "selfshelf://book/\(book.olid)")!) {
                            BookCoverView(
                                coverId: book.coverId,
                                title: book.title,
                                fallbackTint: tint,
                                cornerRadius: 1.5
                            )
                            .aspectRatio(2.0/3.0, contentMode: .fit)
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 5)
            ShelfPlank(hex: snapshot.backgroundColorHex)
        }
    }
}
