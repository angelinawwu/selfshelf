import SwiftUI

struct SettingsView: View {
    @State private var cacheSize: String = "—"

    var body: some View {
        ZStack {
            AppTheme.paper.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Settings").font(.serif(28)).foregroundStyle(AppTheme.ink)
                    row(title: "Cover cache", value: cacheSize) {
                        Task {
                            await CoverCache.shared.clear()
                            await refresh()
                        }
                    }
                    Text("Book data courtesy of Open Library.")
                        .font(.sans(12, weight: .light))
                        .foregroundStyle(AppTheme.inkMuted)
                }
                .padding(20)
            }
        }
        .task { await refresh() }
    }

    @MainActor
    private func refresh() async {
        let bytes = await CoverCache.shared.diskSizeBytes()
        cacheSize = ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    private func row(title: String, value: String, action: @escaping () -> Void) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.sans(14)).foregroundStyle(AppTheme.ink)
                Text(value).monoCaption().foregroundStyle(AppTheme.ink)
            }
            Spacer()
            Button("Clear", action: action)
                .font(.sans(13, weight: .medium))
                .tint(AppTheme.ink)
        }
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) { Rectangle().frame(height: 0.5).foregroundStyle(AppTheme.hairline) }
    }
}
