import SwiftData
import SwiftUI

struct EventLogView: View {
    @Query(sort: [
        SortDescriptor(\GameEvent.year, order: .reverse),
        SortDescriptor(\GameEvent.createdAt, order: .reverse)
    ])
    private var gameEvents: [GameEvent]

    @Query(sort: [
        SortDescriptor(\HistoryEvent.year, order: .reverse),
        SortDescriptor(\HistoryEvent.createdAt, order: .reverse)
    ])
    private var historyEvents: [HistoryEvent]

    @State private var selectedCategory: LogCategory = .all
    @State private var selectedRange: TimelineRange = .latest500
    @State private var chronicleOnly = true
    @State private var conciseMode = false

    var body: some View {
        List {
            Section("筛选") {
                Picker("分类", selection: $selectedCategory) {
                    ForEach(LogCategory.allCases) { category in
                        Text(category.name).tag(category)
                    }
                }

                Picker("时间", selection: $selectedRange) {
                    ForEach(TimelineRange.allCases) { range in
                        Text(range.name).tag(range)
                    }
                }

                Toggle("编年史模式", isOn: $chronicleOnly)
                Toggle("简洁模式", isOn: $conciseMode)
            }

            Section("修真编年史") {
                ChronicleTimelineView(entries: timelineEntries)
            }
        }
    }

    private var timelineEntries: [TimelineEntry] {
        let currentYear = max(gameEvents.first?.year ?? 0, historyEvents.first?.year ?? 0)
        return TimelineSystem.entries(
            gameEvents: gameEvents,
            historyEvents: historyEvents,
            category: selectedCategory,
            startYear: selectedRange.startYear(currentYear: currentYear),
            endYear: nil,
            chronicleOnly: chronicleOnly,
            concise: conciseMode
        )
    }
}

private enum TimelineRange: String, CaseIterable, Identifiable {
    case latest100
    case latest500
    case latest1000
    case all

    var id: String { rawValue }

    var name: String {
        switch self {
        case .latest100: "近百年"
        case .latest500: "近五百年"
        case .latest1000: "近千年"
        case .all: "全部"
        }
    }

    func startYear(currentYear: Int) -> Int? {
        switch self {
        case .latest100: max(1, currentYear - 100)
        case .latest500: max(1, currentYear - 500)
        case .latest1000: max(1, currentYear - 1000)
        case .all: nil
        }
    }
}

private struct ChronicleTimelineView: View {
    let entries: [TimelineEntry]

    var body: some View {
        if entries.isEmpty {
            Text("此段岁月暂无可载入史册之事")
                .foregroundStyle(.secondary)
        } else {
            ForEach(entries) { entry in
                TimelineRow(entry: entry)
            }
        }
    }
}

private struct TimelineRow: View {
    let entry: TimelineEntry

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: entry.importance >= 3 ? 12 : 8, height: entry.importance >= 3 ? 12 : 8)
                Rectangle()
                    .fill(color.opacity(0.25))
                    .frame(width: 2)
            }
            .frame(width: 16)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text("第 \(entry.year) 年 · \(entry.title)")
                        .font(entry.importance >= 3 ? .headline : .body)
                        .fontWeight(entry.importance >= 2 ? .semibold : .regular)

                    Spacer()

                    EventImportanceBadge(importance: entry.importance)
                }

                Text(entry.category.name)
                    .font(.caption)
                    .foregroundStyle(color)

                Text(entry.detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, entry.importance >= 2 ? 8 : 4)
    }

    private var color: Color {
        switch entry.category {
        case .player: .cyan
        case .npc: .indigo
        case .sect: .orange
        case .world: .green
        case .disaster: .red
        case .ascension: .purple
        case .karma: .pink
        case .faction: .orange
        case .reincarnation: .teal
        case .lineage: .mint
        case .calamity: .red
        }
    }
}
