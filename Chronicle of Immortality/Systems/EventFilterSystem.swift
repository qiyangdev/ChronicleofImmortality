import Foundation

enum EventFilterSystem {
    static func filterHistoryEvents(_ events: [HistoryEvent], recentEvents: [HistoryEvent], config: BalanceConfig = .current) -> [HistoryEvent] {
        var accepted: [HistoryEvent] = []
        var seenKeys = Set<String>()
        let currentYear = events.map(\.year).max() ?? 0
        let recentKeys = Set(
            recentEvents
                .filter { currentYear - $0.year <= config.eventCooldownYears }
                .map(cooldownKey)
        )

        for event in events {
            guard shouldEnterChronicle(event, config: config) else { continue }

            let key = cooldownKey(event)
            guard !seenKeys.contains(key), !recentKeys.contains(key) else { continue }

            seenKeys.insert(key)
            accepted.append(event)
        }

        if accepted.count > config.maxHistoryEventsPerBatch {
            return Array(accepted.sorted { $0.importance > $1.importance }.prefix(config.maxHistoryEventsPerBatch))
        }

        return accepted
    }

    static func filterGameEvents(_ events: [GameEvent], config: BalanceConfig = .current) -> [GameEvent] {
        let important = events.filter { $0.importance >= 2 }
        let ordinary = events.filter { $0.importance < 2 }

        var result = Array(important.prefix(config.maxGameEventsPerBatch))
        if ordinary.count >= config.lowValueEventFoldSize, let lastYear = ordinary.map(\.year).max() {
            result.append(
                GameEvent(
                    year: lastYear,
                    title: "岁月简记",
                    detail: "其间共有 \(ordinary.count) 则寻常修行、坊市与山野见闻，皆归入简记。"
                )
            )
        } else {
            result.append(contentsOf: ordinary.prefix(max(0, config.maxGameEventsPerBatch - result.count)))
        }

        return Array(result.prefix(config.maxGameEventsPerBatch))
    }

    static func isChronicleModeCategory(_ category: HistoryCategory) -> Bool {
        switch category {
        case .ascension, .faction, .world, .lineage, .calamity:
            true
        case .player, .npc, .sect, .disaster, .karma, .reincarnation:
            false
        }
    }

    private static func shouldEnterChronicle(_ event: HistoryEvent, config: BalanceConfig) -> Bool {
        if event.importance >= config.majorEventMinimumImportance { return true }

        switch event.category {
        case .ascension, .lineage, .calamity:
            return true
        case .faction:
            return event.title.contains("覆灭") || event.title.contains("战争") || event.title.contains("击退")
        case .world:
            return event.title.contains("黄金") || event.title.contains("灾") || event.title.contains("时代")
        case .sect:
            return event.title.contains("覆灭")
        case .player, .npc, .disaster, .karma, .reincarnation:
            return false
        }
    }

    private static func cooldownKey(_ event: HistoryEvent) -> String {
        "\(event.category.rawValue)-\(event.title)"
    }
}
