import SwiftUI
import SwiftData
import WidgetKit

struct ShelvesListView: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: [SortDescriptor(\Shelf.sortIndex), SortDescriptor(\Shelf.createdAt)])
    private var shelves: [Shelf]

    @State private var showingCreate = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.paper.ignoresSafeArea()
                if shelves.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("SelfShelf")
                            .font(.serif(22))
                            .foregroundStyle(AppTheme.ink)
                        Text("Your shelves").monoCaption()
                            .foregroundStyle(AppTheme.ink)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .tint(AppTheme.ink)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreate = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .tint(AppTheme.ink)
                }
            }
            .sheet(isPresented: $showingCreate) {
                ShelfEditorView(mode: .create)
            }
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 22) {
                ForEach(shelves) { shelf in
                    NavigationLink(value: shelf) {
                        ShelfPreviewCard(shelf: shelf)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationDestination(for: Shelf.self) { shelf in
            ShelfDetailView(shelf: shelf)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Text("No shelves yet")
                .font(.serif(28))
                .foregroundStyle(AppTheme.ink)
            Text("Create your first shelf")
                .monoCaption()
                .foregroundStyle(AppTheme.ink)
            Button {
                showingCreate = true
            } label: {
                Text("New shelf").font(.sans(14, weight: .medium))
                    .padding(.horizontal, 22).padding(.vertical, 12)
                    .overlay(Capsule().stroke(AppTheme.ink, lineWidth: 1))
            }
            .padding(.top, 6)
            .foregroundStyle(AppTheme.ink)
        }
    }
}

private struct ShelfPreviewCard: View {
    let shelf: Shelf

    var body: some View {
        // Render the same view used by the home-screen widget so the in-app
        // preview matches exactly. Widget medium family aspect ~338:158.
        ZStack {
            ShelfBackground(hex: shelf.backgroundColorHex, preset: shelf.preset)
            ShelfWidgetMediumView(snapshot: shelf.snapshot())
                .padding(16)
        }
        .aspectRatio(338.0/158.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(AppTheme.hairline, lineWidth: 1)
        )
    }
}
