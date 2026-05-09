import SwiftUI
import SwiftData
import WidgetKit

struct ShelfDetailView: View {
    @Bindable var shelf: Shelf
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    @State private var showingEditor = false
    @State private var showingSearch = false

    private let columns = [GridItem(.adaptive(minimum: 90), spacing: 14)]

    var body: some View {
        ZStack {
            AppTheme.paper.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    livePreview
                    Divider().overlay(AppTheme.hairline).padding(.vertical, 4)
                    grid
                }
                .padding(20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(shelf.name)
                    .font(.serif(20))
                    .foregroundStyle(AppTheme.ink)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showingSearch = true } label: { Label("Add book", systemImage: "plus") }
                    Button { showingEditor = true } label: { Label("Edit shelf", systemImage: "slider.horizontal.3") }
                    Section {
                        Button(role: .destructive) {
                            ctx.delete(shelf)
                            try? ctx.save()
                            WidgetCenter.shared.reloadAllTimelines()
                            dismiss()
                        } label: { Label("Delete shelf", systemImage: "trash") }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .tint(AppTheme.ink)
            }
        }
        .sheet(isPresented: $showingEditor) {
            ShelfEditorView(mode: .edit(shelf))
        }
        .sheet(isPresented: $showingSearch) {
            NavigationStack {
                SearchView(preselectedShelf: shelf)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(shelf.books.count) \(shelf.books.count == 1 ? "book" : "books") · Style: \(shelf.preset.displayName)")
                .monoCaption()
                .foregroundStyle(AppTheme.ink)
            Text("Drag to reorder. Long-press a book to remove.")
                .font(.sans(13, weight: .light))
                .foregroundStyle(AppTheme.inkMuted)
        }
    }

    private var livePreview: some View {
        ZStack(alignment: .bottom) {
            ShelfBackground(hex: shelf.backgroundColorHex, preset: shelf.preset)
            VStack(spacing: 0) {
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(Array(shelf.orderedBooks.prefix(8))) { book in
                        BookCoverView(coverId: book.coverId, title: book.title)
                            .aspectRatio(2.0/3.0, contentMode: .fit)
                            .frame(maxHeight: 120)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14)
                .padding(.top, 16)
                ShelfPlank(hex: shelf.backgroundColorHex)
            }
        }
        .frame(height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var grid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Books").monoCaption().foregroundStyle(AppTheme.ink)
            if shelf.books.isEmpty {
                VStack(spacing: 10) {
                    Text("Nothing here yet")
                        .font(.serif(22))
                        .foregroundStyle(AppTheme.ink)
                    Button {
                        showingSearch = true
                    } label: {
                        Text("Add books").font(.sans(13, weight: .medium))
                            .padding(.horizontal, 18).padding(.vertical, 10)
                            .overlay(Capsule().stroke(AppTheme.ink, lineWidth: 1))
                    }
                    .foregroundStyle(AppTheme.ink)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(shelf.orderedBooks) { book in
                        BookTile(book: book)
                            .contextMenu {
                                Button(role: .destructive) {
                                    withAnimation { ctx.delete(book) }
                                    try? ctx.save()
                                    WidgetCenter.shared.reloadAllTimelines()
                                } label: { Label("Remove", systemImage: "trash") }
                            }
                            .draggable(book.olid) {
                                BookCoverView(coverId: book.coverId, title: book.title)
                                    .frame(width: 70, height: 100)
                            }
                            .dropDestination(for: String.self) { items, _ in
                                guard let draggedOlid = items.first,
                                      let dragged = shelf.orderedBooks.first(where: { $0.olid == draggedOlid }),
                                      dragged.id != book.id else { return false }
                                reorder(moving: dragged, before: book)
                                return true
                            }
                    }
                }
            }
        }
    }

    private func reorder(moving dragged: Book, before target: Book) {
        var ordered = shelf.orderedBooks
        ordered.removeAll { $0.id == dragged.id }
        if let idx = ordered.firstIndex(where: { $0.id == target.id }) {
            ordered.insert(dragged, at: idx)
        } else {
            ordered.append(dragged)
        }
        for (i, b) in ordered.enumerated() { b.order = i }
        try? ctx.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

private struct BookTile: View {
    let book: Book

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            BookCoverView(coverId: book.coverId, title: book.title)
                .aspectRatio(2.0/3.0, contentMode: .fit)
            Text(book.title)
                .font(.sans(12, weight: .regular))
                .lineLimit(2)
                .foregroundStyle(AppTheme.ink)
            Text(book.authorLine)
                .font(.sans(10, weight: .light))
                .lineLimit(1)
                .foregroundStyle(AppTheme.inkMuted)
        }
    }
}
