import SwiftUI
import WidgetKit

struct ShelfWidgetView: View {
    @Environment(\.widgetFamily) var family
    let snapshot: ShelfSnapshot

    var body: some View {
        switch family {
        case .systemSmall: ShelfWidgetSmallView(snapshot: snapshot)
        case .systemMedium: ShelfWidgetMediumView(snapshot: snapshot)
        case .systemLarge: ShelfWidgetLargeView(snapshot: snapshot)
        default: ShelfWidgetMediumView(snapshot: snapshot)
        }
    }
}
