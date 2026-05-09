import SwiftUI
import WidgetKit

struct ShelfWidgetView: View {
    @Environment(\.widgetFamily) var family
    let snapshot: ShelfSnapshot

    var body: some View {
        switch family {
        case .systemSmall: SmallShelf(snapshot: snapshot)
        case .systemMedium: MediumShelf(snapshot: snapshot)
        case .systemLarge: LargeShelf(snapshot: snapshot)
        default: MediumShelf(snapshot: snapshot)
        }
    }
}

private struct ShelfHeader: View {
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

private struct ShelfRow: View {
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
            ShelfPlank(hex: snapshot.backgroundColorHex)
        }
    }
}

private struct SmallShelf: View {
    let snapshot: ShelfSnapshot
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ShelfHeader(snapshot: snapshot, compact: true)
            Spacer(minLength: 0)
            ShelfRow(snapshot: snapshot, books: snapshot.books.prefix(3))
        }
    }
}

private struct MediumShelf: View {
    let snapshot: ShelfSnapshot
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ShelfHeader(snapshot: snapshot, compact: false)
            Spacer(minLength: 0)
            ShelfRow(snapshot: snapshot, books: snapshot.books.prefix(6))
        }
    }
}

private struct LargeShelf: View {
    let snapshot: ShelfSnapshot
    var body: some View {
        let all = snapshot.books
        let first = all.prefix(6)
        let second = all.dropFirst(6).prefix(6)
        VStack(alignment: .leading, spacing: 12) {
            ShelfHeader(snapshot: snapshot, compact: false)
            Spacer(minLength: 0)
            ShelfRow(snapshot: snapshot, books: first)
            Spacer(minLength: 0)
            ShelfRow(snapshot: snapshot, books: second)
        }
    }
}
