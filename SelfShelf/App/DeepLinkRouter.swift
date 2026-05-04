import SwiftUI
import Combine

final class DeepLinkRouter: ObservableObject {
    @Published var pendingBookOLID: String?
    @Published var selectedTab: Tab = .shelves

    enum Tab: Hashable { case shelves, search }

    func handle(url: URL) {
        guard url.scheme == "selfshelf" else { return }
        if url.host == "book" {
            let olid = url.pathComponents.dropFirst().first ?? ""
            if !olid.isEmpty {
                pendingBookOLID = olid
                selectedTab = .search
            }
        }
    }
}
