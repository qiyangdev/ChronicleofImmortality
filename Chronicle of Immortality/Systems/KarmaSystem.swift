import Foundation
import SwiftData

enum KarmaSystem {
    static func record(
        source: String,
        target: String,
        reason: String,
        value: Int,
        year: Int,
        in modelContext: ModelContext
    ) -> HistoryEvent {
        modelContext.insert(KarmaRecord(source: source, target: target, reason: reason, karmaValue: value, year: year))
        return HistoryEvent(
            year: year,
            title: "\(source) 与 \(target) 结下因果",
            detail: "\(reason)，此因果或将在数百年后回响。",
            category: .karma,
            importance: abs(value) >= 45 ? 2 : 1
        )
    }

    static func advance(records: [KarmaRecord], npcs: [NPC], player: Cultivator, world: WorldState) -> [HistoryEvent] {
        var events: [HistoryEvent] = []

        for record in records where !record.isResolved {
            let age = world.year - record.year
            guard age > 40, GameMath.chance(Double(min(abs(record.karmaValue), 80)) / 12) else { continue }

            let npcName = record.source == player.name ? record.target : record.source
            guard let npc = npcs.first(where: { $0.name == npcName && $0.isAlive }) else { continue }

            record.isResolved = true

            if record.karmaValue > 0 {
                player.sect?.reputation = GameMath.clamp((player.sect?.reputation ?? 0) + 4, lower: 0, upper: 100)
                world.fortune = GameMath.clamp(world.fortune + 2.5, lower: 1, upper: 100)
                events.append(
                    HistoryEvent(
                        year: world.year,
                        title: "\(npc.name) 偿还旧恩",
                        detail: "昔年因\(record.reason)结下善缘，如今 \(npc.title) \(npc.name) 出手相助，玩家一脉气运回升。",
                        category: .karma,
                        importance: 2
                    )
                )
            } else {
                world.demonicThreat = GameMath.clamp(world.demonicThreat + 3, lower: 0, upper: 100)
                player.lifespan = max(player.age + 1, player.lifespan - Int.random(in: 1...8))
                events.append(
                    HistoryEvent(
                        year: world.year,
                        title: "\(npc.name) 追索旧怨",
                        detail: "\(npc.name) 因\(record.reason)旧恨未消，暗中追杀玩家一脉，天下杀机渐重。",
                        category: .karma,
                        importance: 2
                    )
                )
            }
        }

        return events
    }
}
