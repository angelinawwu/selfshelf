import SwiftUI
import SwiftData

@main
struct SelfShelfApp: App {
    @StateObject private var router = DeepLinkRouter()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(router)
                .tint(AppTheme.ink)
                .preferredColorScheme(.light)
                .onAppear { seedIfNeeded() }
                .onOpenURL { url in router.handle(url: url) }
        }
        .modelContainer(SharedStore.shared)
    }

    @MainActor
    private func seedIfNeeded() {
        let ctx = SharedStore.shared.mainContext
        let count = (try? ctx.fetchCount(FetchDescriptor<Shelf>())) ?? 0
        guard count == 0 else { return }
        let s = Shelf(
            name: "Favorites",
            sortIndex: 0,
            backgroundColorHex: ShelfStyle.palette[1].hex,
            preset: .flat
        )
        ctx.insert(s)
        try? ctx.save()
    }
}
