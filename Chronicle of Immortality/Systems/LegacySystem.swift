import Foundation
import SwiftData

enum LegacySystem {
    static func advance(legacies: [Legacy], world: WorldState, modelContext: ModelContext) -> [HistoryEvent] {
        var events: [HistoryEvent] = []

        for legacy in legacies {
            legacy.influence = GameMath.clamp(legacy.influence + Double(legacy.descendants) / 120 + Double.random(in: -0.4...1.1), lower: 0, upper: 100)

            if GameMath.chance(2.2 + legacy.influence / 120) {
                let gained = Int.random(in: 1...9)
                legacy.descendants += gained
                events.append(
                    HistoryEvent(
                        year: world.year,
                        title: "\(legacy.technique) 道统流传",
                        detail: "\(legacy.faction) 又有 \(gained) 名后辈承接 \(legacy.founder) 所留道统。",
                        category: .lineage,
                        importance: legacy.influence > 70 ? 2 : 1
                    )
                )
            }

            if legacy.influence > 85, GameMath.chance(1.4) {
                modelContext.insert(
                    Region(
                        name: "\(legacy.founder)遗迹",
                        aura: 70,
                        danger: 48,
                        resources: 82,
                        demonicInfluence: 12,
                        unlockedRealm: .foundation
                    )
                )
                events.append(
                    HistoryEvent(
                        year: world.year,
                        title: "\(legacy.founder) 遗迹现世",
                        detail: "\(legacy.founder) 道统影响日盛，旧日洞府化为后世争夺的传承遗迹。",
                        category: .lineage,
                        importance: 3
                    )
                )
            }
        }

        return events
    }

    static func preservePlayerLegacy(player: Cultivator, world: WorldState, modelContext: ModelContext) -> HistoryEvent {
        let techniqueName = player.equippedTechnique?.name ?? "无名心法"
        let legacy = Legacy(
            founder: player.name,
            faction: player.sectName,
            technique: techniqueName,
            createdYear: world.year,
            influence: max(8, player.realm.multiplier / 2),
            descendants: max(1, player.sectRole >= .elder ? 12 : 2)
        )
        modelContext.insert(legacy)

        return HistoryEvent(
            year: world.year,
            title: "\(player.name) 入人物志",
            detail: player.deathSummary.isEmpty ? "\(player.name) 虽一世将尽，仍在 \(player.sectName) 留下 \(techniqueName) 一脉，后世或将承其余泽。" : "\(player.deathSummary) 其所留 \(techniqueName) 一脉，后世或将承其余泽。",
            category: .lineage,
            importance: 3
        )
    }
}
