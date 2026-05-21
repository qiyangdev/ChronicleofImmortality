import SwiftData
import SwiftUI

struct EventLogView: View {
    @Query(sort: [
        SortDescriptor(\GameEvent.year, order: .reverse),
        SortDescriptor(\GameEvent.createdAt, order: .reverse)
    ])
    private var events: [GameEvent]

    var body: some View {
        List(events) { event in
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(event.year) 年 · \(event.title)")
                        .font(event.importance >= 3 ? .headline : .body)
                        .fontWeight(event.importance >= 2 ? .semibold : .regular)

                    Spacer()

                    EventImportanceBadge(importance: event.importance)
                }

                Text(event.detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, event.importance >= 2 ? 6 : 2)
        }
    }
}
