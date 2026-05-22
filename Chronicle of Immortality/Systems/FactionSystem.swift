import Foundation
import SwiftData

enum FactionSystem {
    static func advance(
        factions: [Faction],
        regions: [Region],
        sects: [Sect],
        world: WorldState,
        modelContext: ModelContext
    ) -> [HistoryEvent] {
        var events: [HistoryEvent] = []

        for faction in factions {
            let alignmentBias = faction.alignment == .demonic ? world.demonicThreat / 120 : world.fortune / 160
            let drift = GameMath.clamp(
                (alignmentBias + Double.random(in: -1.6...2.0)) * BalanceConfig.current.factionExpansionMultiplier,
                lower: -BalanceConfig.current.maxFactionInfluenceChangePerYear,
                upper: BalanceConfig.current.maxFactionInfluenceChangePerYear
            )
            faction.influence = GameMath.clamp(faction.influence + drift, lower: 0, upper: 100)

            if faction.alignment == .demonic {
                world.demonicThreat = GameMath.clamp(world.demonicThreat + faction.influence / 2200, lower: 0, upper: 100)
            }

            if GameMath.chance((1.8 + faction.influence / 80) * BalanceConfig.current.factionExpansionMultiplier), let region = regions.randomElement() {
                faction.territory = region.name
                region.demonicInfluence = GameMath.clamp(region.demonicInfluence + (faction.alignment == .demonic ? 4 : -2), lower: 0, upper: 100)
                events.append(
                    HistoryEvent(
                        year: world.year,
                        title: "\(faction.name) 迁移势力",
                        detail: "\(faction.name) 将势力重心移至 \(region.name)，当地格局随之变动。",
                        category: .faction,
                        importance: 1
                    )
                )
            }

            if GameMath.chance((1.4 + world.calamityPressure / 90) * BalanceConfig.current.factionExpansionMultiplier), let enemy = factions.filter({ $0.name != faction.name }).randomElement() {
                faction.enemies = appendName(enemy.name, to: faction.enemies)
                enemy.enemies = appendName(faction.name, to: enemy.enemies)
                let winner = faction.influence >= enemy.influence ? faction : enemy
                let loser = winner.name == faction.name ? enemy : faction
                winner.influence = GameMath.clamp(winner.influence + Double.random(in: 2...7), lower: 0, upper: 100)
                loser.influence = GameMath.clamp(loser.influence - Double.random(in: 4...12), lower: 0, upper: 100)
                events.append(
                    HistoryEvent(
                        year: world.year,
                        title: "\(winner.name) 击退 \(loser.name)",
                        detail: "\(winner.name) 与 \(loser.name) 爆发势力战争，胜者吞并诸多灵地。",
                        category: .faction,
                        importance: 2
                    )
                )
            }

            if faction.influence < 8, GameMath.chance(12) {
                events.append(splitOrCollapse(faction: faction, sects: sects, world: world, modelContext: modelContext))
            }

            if GameMath.chance(1.2), let ally = factions.filter({ $0.name != faction.name && $0.alignment == faction.alignment }).randomElement() {
                faction.allies = appendName(ally.name, to: faction.allies)
                ally.allies = appendName(faction.name, to: ally.allies)
                events.append(
                    HistoryEvent(
                        year: world.year,
                        title: "\(faction.name) 与 \(ally.name) 结盟",
                        detail: "两方势力互换誓书，约定共抗大劫。",
                        category: .faction,
                        importance: 1
                    )
                )
            }
        }

        return events
    }

    private static func splitOrCollapse(faction: Faction, sects: [Sect], world: WorldState, modelContext: ModelContext) -> HistoryEvent {
        if GameMath.chance(45), let sect = sects.randomElement() {
            let newFaction = Faction(
                name: "\(sect.name)新盟",
                alignment: faction.alignment,
                influence: 18,
                territory: sect.name,
                leader: sect.name,
                members: sect.name
            )
            modelContext.insert(newFaction)
            faction.influence = 5
            return HistoryEvent(
                year: world.year,
                title: "\(faction.name) 分裂",
                detail: "\(faction.name) 气运衰微，\(sect.name)另立新盟，天下势力重新洗牌。",
                category: .faction,
                importance: 2
            )
        }

        faction.influence = 0
        return HistoryEvent(
            year: world.year,
            title: "\(faction.name) 覆灭",
            detail: "\(faction.name) 内外交困，旧日旗号自修真界除名。",
            category: .faction,
            importance: 3
        )
    }

    private static func appendName(_ name: String, to list: String) -> String {
        let names = list.split(separator: "、").map(String.init)
        guard !names.contains(name) else { return list }
        return (names + [name]).joined(separator: "、")
    }
}
