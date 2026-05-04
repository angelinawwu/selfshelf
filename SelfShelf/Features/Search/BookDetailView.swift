import SwiftUI
import SwiftData
import WidgetKit

struct BookDetailView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    let result: OLSearchResult?
    var preselectedShelf: Shelf? = nil
    var existingBook: Book?

    @Query(sort: [SortDescriptor(\Shelf.sortIndex)]) private var shelves: [Shelf]
    @State private var description: String?
    @State private var isLoadingDetail = false
    @State private var selectedShelfIDs: Set<UUID> = []

    init(result: OLSearchResult, preselectedShelf: Shelf? = nil) {
        self.result = result
        self.preselectedShelf = preselectedShelf
        self.existingBook = nil
    }

    init(book: Book) {
        self.result = OLSearchResult(
            id: book.olid, olid: book.olid, title: book.title, authors: book.authors,
            coverId: book.coverId, firstPublishYear: book.firstPublishYear
        )
        self.existingBook = book
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.paper.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        hero
                        if isLoadingDetail {
                            ProgressView().tint(AppTheme.ink)
                        }
                        if let description, !description.isEmpty {
                            Text("About").monoCaption().foregroundStyle(AppTheme.ink)
                            Text(description)
                                .font(.sans(14, weight: .light))
                                .foregroundStyle(AppTheme.ink)
                        }
                        shelvesSection
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { save(); dismiss() }
                        .font(.sans(14, weight: .medium))
                        .tint(AppTheme.ink)
                }
            }
            .task { await load() }
        }
    }

    private var hero: some View {
        HStack(alignment: .top, spacing: 16) {
            RemoteCover(coverId: result?.coverId, title: result?.title ?? "")
                .frame(width: 110, height: 164)
            VStack(alignment: .leading, spacing: 6) {
                Text(result?.title ?? "")
                    .font(.serif(26))
                    .foregroundStyle(AppTheme.ink)
                Text((result?.authors ?? []).joined(separator: ", "))
                    .font(.sans(13, weight: .light))
                    .foregroundStyle(AppTheme.inkMuted)
                if let y = result?.firstPublishYear {
                    Text("\(y)").monoCaption().foregroundStyle(AppTheme.ink)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var shelvesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Shelves").monoCaption().foregroundStyle(AppTheme.ink)
            ForEach(shelves) { shelf in
                Button {
                    toggle(shelf)
                } label: {
                    HStack {
                        Circle().fill(Color(hex: shelf.backgroundColorHex)).frame(width: 14, height: 14)
                            .overlay(Circle().strokeBorder(AppTheme.ink.opacity(0.3), lineWidth: 0.5))
                        Text(shelf.name).font(.sans(15)).foregroundStyle(AppTheme.ink)
                        Spacer()
                        Image(systemName: selectedShelfIDs.contains(shelf.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selectedShelfIDs.contains(shelf.id) ? AppTheme.ink : AppTheme.inkMuted)
                    }
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                Divider().overlay(AppTheme.hairline)
            }
            if shelves.isEmpty {
                Text("Create a shelf from the Shelves tab first.")
                    .font(.sans(12, weight: .light))
                    .foregroundStyle(AppTheme.inkMuted)
            }
        }
    }

    private func toggle(_ shelf: Shelf) {
        if selectedShelfIDs.contains(shelf.id) { selectedShelfIDs.remove(shelf.id) }
        else { selectedShelfIDs.insert(shelf.id) }
    }

    @MainActor
    private func load() async {
        if let pre = preselectedShelf { selectedShelfIDs.insert(pre.id) }
        if let existing = existingBook, let shelf = existing.shelf {
            selectedShelfIDs.insert(shelf.id)
        }
        guard let result else { return }
        isLoadingDetail = true
        defer { isLoadingDetail = false }
        if let detail = try? await OpenLibraryClient.shared.workDetail(olid: result.olid) {
            description = detail.description
        }
        if let coverId = result.coverId {
            Task.detached(priority: .utility) {
                _ = await CoverCache.shared.fetch(coverId: coverId, size: .medium)
                _ = await CoverCache.shared.fetch(coverId: coverId, size: .small)
            }
        }
    }

    @MainActor
    private func save() {
        guard let result else { return }
        for shelf in shelves {
            let shouldBeOn = selectedShelfIDs.contains(shelf.id)
            let existing = shelf.books.first(where: { $0.olid == result.olid })
            if shouldBeOn && existing == nil {
                let count = shelf.books.count
                let book = Book(
                    olid: result.olid,
                    title: result.title,
                    authors: result.authors,
                    coverId: result.coverId,
                    firstPublishYear: result.firstPublishYear,
                    order: count
                )
                book.shelf = shelf
                ctx.insert(book)
            } else if !shouldBeOn, let existing {
                ctx.delete(existing)
            }
        }
        try? ctx.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
