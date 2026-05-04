import SwiftUI
import SwiftData

struct SearchView: View {
    @EnvironmentObject private var router: DeepLinkRouter
    @Environment(\.modelContext) private var ctx

    @State private var query = ""
    @State private var results: [OLSearchResult] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchTask: Task<Void, Never>?
    @State private var selectedResult: OLSearchResult?
    @State private var pushedBookByDeeplink: Book?

    var preselectedShelf: Shelf? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.paper.ignoresSafeArea()
                VStack(spacing: 0) {
                    searchBar
                    if isLoading {
                        ProgressView().padding(.top, 40)
                            .tint(AppTheme.ink)
                    } else if let errorMessage {
                        Text(errorMessage)
                            .font(.sans(13))
                            .foregroundStyle(AppTheme.inkMuted)
                            .padding(.top, 30)
                    } else if results.isEmpty {
                        placeholder
                    } else {
                        resultsList
                    }
                    Spacer(minLength: 0)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text(preselectedShelf == nil ? "Discover" : "Add to \(preselectedShelf!.name)")
                            .font(.serif(22))
                            .foregroundStyle(AppTheme.ink)
                        Text("Open library").monoCaption()
                            .foregroundStyle(AppTheme.ink)
                    }
                }
            }
            .sheet(item: $selectedResult) { r in
                BookDetailView(result: r, preselectedShelf: preselectedShelf)
            }
            .task(id: router.pendingBookOLID) { await handleDeepLink() }
            .sheet(item: $pushedBookByDeeplink) { b in
                NavigationStack {
                    BookDetailView(book: b)
                }
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(AppTheme.inkMuted)
            TextField("Search authors, titles, subjects", text: $query)
                .font(.sans(15))
                .foregroundStyle(AppTheme.ink)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
                .onSubmit { runSearch() }
                .onChange(of: query) { _, _ in debouncedSearch() }
            if !query.isEmpty {
                Button {
                    query = ""; results = []
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(AppTheme.inkMuted)
                }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(AppTheme.paperDeep)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 12)
    }

    private var placeholder: some View {
        VStack(spacing: 12) {
            Text("A tiny, beautiful library").font(.serif(26)).foregroundStyle(AppTheme.ink)
            Text("Search to begin").monoCaption().foregroundStyle(AppTheme.ink)
        }
        .padding(.top, 60)
    }

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(results) { r in
                    Button { selectedResult = r } label: {
                        ResultRow(result: r)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }

    private func debouncedSearch() {
        searchTask?.cancel()
        let q = query
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            if Task.isCancelled { return }
            await runSearchAsync(q)
        }
    }

    private func runSearch() {
        searchTask?.cancel()
        Task { await runSearchAsync(query) }
    }

    @MainActor
    private func runSearchAsync(_ q: String) async {
        let trimmed = q.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { results = []; errorMessage = nil; return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let res = try await OpenLibraryClient.shared.search(trimmed)
            if !Task.isCancelled { results = res }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func handleDeepLink() async {
        guard let olid = router.pendingBookOLID else { return }
        defer { router.pendingBookOLID = nil }
        let descriptor = FetchDescriptor<Book>(predicate: #Predicate { $0.olid == olid })
        if let existing = try? ctx.fetch(descriptor).first {
            pushedBookByDeeplink = existing
        }
    }
}

private struct ResultRow: View {
    let result: OLSearchResult

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            RemoteCover(coverId: result.coverId, title: result.title)
                .frame(width: 58, height: 86)
            VStack(alignment: .leading, spacing: 3) {
                Text(result.title)
                    .font(.serif(18))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(2)
                Text(result.authors.joined(separator: ", ").ifEmpty("Unknown"))
                    .font(.sans(12, weight: .light))
                    .foregroundStyle(AppTheme.inkMuted)
                    .lineLimit(1)
                if let y = result.firstPublishYear {
                    Text("\(y)").monoCaption().foregroundStyle(AppTheme.ink)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) {
            Rectangle().frame(height: 0.5).foregroundStyle(AppTheme.hairline)
        }
    }
}

struct RemoteCover: View {
    let coverId: Int?
    let title: String
    var body: some View {
        Group {
            if let coverId {
                AsyncImage(url: OpenLibraryClient.coverURL(id: coverId, size: .medium)) { phase in
                    switch phase {
                    case .empty: placeholder
                    case .success(let img): img.resizable().scaledToFill()
                    case .failure: placeholder
                    @unknown default: placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(Color.black.opacity(0.15), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.12), radius: 2, x: 1, y: 1)
    }
    private var placeholder: some View {
        ZStack {
            AppTheme.paperDeep
            Text(String(title.prefix(1)).uppercased())
                .font(.serif(24)).foregroundStyle(AppTheme.ink.opacity(0.45))
        }
    }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String {
        isEmpty ? fallback : self
    }
}
