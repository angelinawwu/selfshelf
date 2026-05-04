import SwiftUI

struct RootTabView: View {
    @EnvironmentObject var router: DeepLinkRouter

    var body: some View {
        TabView(selection: $router.selectedTab) {
            ShelvesListView()
                .tabItem {
                    Label {
                        Text("Shelves").font(.sans(11))
                    } icon: {
                        Image(systemName: "books.vertical")
                    }
                }
                .tag(DeepLinkRouter.Tab.shelves)

            SearchView()
                .tabItem {
                    Label {
                        Text("Search").font(.sans(11))
                    } icon: {
                        Image(systemName: "magnifyingglass")
                    }
                }
                .tag(DeepLinkRouter.Tab.search)
        }
        .background(AppTheme.paper.ignoresSafeArea())
        .tint(AppTheme.ink)
    }
}
