import SwiftUI
import WidgetKit

struct PlaceholderEntry: TimelineEntry {
    let date: Date
}

struct PlaceholderProvider: TimelineProvider {
    func placeholder(in context: Context) -> PlaceholderEntry {
        PlaceholderEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (PlaceholderEntry) -> Void) {
        completion(PlaceholderEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PlaceholderEntry>) -> Void) {
        completion(Timeline(entries: [PlaceholderEntry(date: Date())], policy: .never))
    }
}

struct BacktesterNoteWidgetEntryView: View {
    var entry: PlaceholderEntry

    var body: some View {
        Text("Placeholder")
    }
}

struct BacktesterNoteWidget: Widget {
    let kind: String = "BacktesterNoteWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PlaceholderProvider()) { entry in
            BacktesterNoteWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("BacktesterNote")
        .description("占位 Widget")
        .supportedFamilies([.systemSmall])
    }
}

@main
struct BacktesterNoteWidgetsBundle: WidgetBundle {
    var body: some Widget {
        BacktesterNoteWidget()
    }
}
