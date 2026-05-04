import WidgetKit
import SwiftUI
import AppIntents
import SwiftData

struct ShelfWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: ShelfSnapshot
}

struct ShelfWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ShelfWidgetEntry {
        ShelfWidgetEntry(date: .now, snapshot: .placeholder)
    }

    func snapshot(for configuration: SelectShelfIntent, in context: Context) async -> ShelfWidgetEntry {
        ShelfWidgetEntry(date: .now, snapshot: await loadSnapshot(for: configuration))
    }

    func timeline(for configuration: SelectShelfIntent, in context: Context) async -> Timeline<ShelfWidgetEntry> {
        let entry = ShelfWidgetEntry(date: .now, snapshot: await loadSnapshot(for: configuration))
        let refresh = Date().addingTimeInterval(60 * 30)
        return Timeline(entries: [entry], policy: .after(refresh))
    }

    @MainActor
    private func loadSnapshot(for configuration: SelectShelfIntent) async -> ShelfSnapshot {
        let ctx = SharedStore.shared.mainContext
        if let id = configuration.shelf?.id {
            let descriptor = FetchDescriptor<Shelf>(predicate: #Predicate { $0.id == id })
            if let s = try? ctx.fetch(descriptor).first { return s.snapshot() }
        }
        let any = FetchDescriptor<Shelf>(sortBy: [SortDescriptor(\.sortIndex), SortDescriptor(\.createdAt)])
        if let first = try? ctx.fetch(any).first { return first.snapshot() }
        return .placeholder
    }
}

struct ShelfWidget: Widget {
    let kind = "ShelfWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectShelfIntent.self, provider: ShelfWidgetProvider()) { entry in
            ShelfWidgetView(snapshot: entry.snapshot)
                .containerBackground(for: .widget) {
                    ShelfBackground(hex: entry.snapshot.backgroundColorHex, preset: entry.snapshot.preset)
                }
        }
        .configurationDisplayName("Bookshelf")
        .description("Display one of your shelves on the home screen.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
