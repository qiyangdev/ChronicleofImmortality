import Foundation

enum LogCategory: String, CaseIterable, Identifiable {
    case all
    case player
    case biography
    case npc
    case sect
    case faction
    case world
    case ascension
    case calamity
    case lineage

    var id: String { rawValue }

    var name: String {
        switch self {
        case .all: "全部"
        case .player: "玩家"
        case .biography: "人物志"
        case .npc: "NPC"
        case .sect: "宗门"
        case .faction: "势力"
        case .world: "天下"
        case .ascension: "飞升"
        case .calamity: "灾劫"
        case .lineage: "道统"
        }
    }

    func contains(_ category: HistoryCategory) -> Bool {
        switch self {
        case .all: true
        case .player: category == .player || category == .karma || category == .reincarnation
        case .biography: category == .player || category == .reincarnation || category == .lineage
        case .npc: category == .npc
        case .sect: category == .sect
        case .faction: category == .faction
        case .world: category == .world
        case .ascension: category == .ascension
        case .calamity: category == .calamity || category == .disaster
        case .lineage: category == .lineage
        }
    }
}

struct TimelineEntry: Identifiable {
    let id: String
    let year: Int
    let title: String
    let detail: String
    let category: HistoryCategory
    let importance: Int
    let createdAt: Date
}

enum TimelineSystem {
    static func entries(
        gameEvents: [GameEvent],
        historyEvents: [HistoryEvent],
        category: LogCategory,
        startYear: Int?,
        endYear: Int?,
        chronicleOnly: Bool,
        concise: Bool,
        config: BalanceConfig = .current
    ) -> [TimelineEntry] {
        let playerEntries = chronicleOnly ? [] : gameEvents.map {
            TimelineEntry(
                id: "game-\($0.year)-\($0.createdAt.timeIntervalSince1970)-\($0.title)",
                year: $0.year,
                title: $0.title,
                detail: concise ? String($0.detail.prefix(42)) : $0.detail,
                category: .player,
                importance: $0.importance,
                createdAt: $0.createdAt
            )
        }

        let historyEntries = historyEvents.map {
            TimelineEntry(
                id: "history-\($0.year)-\($0.createdAt.timeIntervalSince1970)-\($0.title)",
                year: $0.year,
                title: $0.title,
                detail: concise ? String($0.detail.prefix(42)) : $0.detail,
                category: $0.category,
                importance: $0.importance,
                createdAt: $0.createdAt
            )
        }

        return (playerEntries + historyEntries)
            .filter { category.contains($0.category) }
            .filter { entry in
                guard !chronicleOnly || EventFilterSystem.isChronicleModeCategory(entry.category) || entry.importance >= 3 else { return false }
                if let startYear, entry.year < startYear { return false }
                if let endYear, entry.year > endYear { return false }
                return true
            }
            .sorted {
                if $0.year == $1.year { return $0.createdAt > $1.createdAt }
                return $0.year > $1.year
            }
            .prefix(config.maxVisibleTimelineEntries)
            .map(\.self)
    }
}
