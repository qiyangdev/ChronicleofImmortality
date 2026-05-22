import Foundation
import SwiftData

enum TechniqueEvolutionSystem {
    static func advance(
        techniques: [Technique],
        npcs: [NPC],
        factions: [Faction],
        legacies: [Legacy],
        world: WorldState,
        modelContext: ModelContext
    ) -> [HistoryEvent] {
        var events: [HistoryEvent] = []

        for technique in techniques where GameMath.chance((2.0 + Double(technique.inheritedCount) / 80) * BalanceConfig.current.techniqueEffectMultiplier) {
            technique.inheritedCount += Int.random(in: 1...5)
            if let legacy = legacies.first(where: { $0.technique == technique.name }) {
                legacy.descendants += Int.random(in: 1...3)
                legacy.influence = GameMath.clamp(legacy.influence + Double.random(in: 0.4...2.0), lower: 0, upper: 100)
            }
        }

        guard GameMath.chance((1.8 + world.civilizationLevel / 80) * BalanceConfig.current.techniqueEffectMultiplier), let creator = npcs.filter({ $0.isAlive && $0.realm >= .goldenCore }).randomElement() else {
            return events
        }

        let base = techniques.randomElement()
        let names = ["太阴长生经", "玄阳洞真录", "九劫化龙诀", "青冥剑典", "万象归元法", "血海不灭经", "浮光遁影诀"]
        let factionName = creator.sect?.name ?? factions.randomElement()?.name ?? "散修道统"
        let rarity = nextRarity(after: base?.rarity ?? .yellow)
        let type = base?.type ?? TechniqueType.allCases.randomElement() ?? .cultivation
        let newTechnique = Technique(
            name: names.randomElement() ?? "无名新法",
            type: type,
            rarity: rarity,
            cultivationBonus: (base?.cultivationBonus ?? 0.08) + Double.random(in: 0.02...0.07),
            breakthroughBonus: (base?.breakthroughBonus ?? 0.03) + Double.random(in: 0.01...0.05),
            lifespanBonus: (base?.lifespanBonus ?? 8) + Int.random(in: 4...28),
            sideEffect: "新法未稳，修行者需自辨道心。",
            creator: creator.name,
            createdYear: world.year,
            originFaction: factionName,
            inheritedCount: 1,
            movementSpeedBonus: type == .movement ? Double.random(in: 12...34) : 0,
            canBypassRegionSeal: type == .movement && rarity >= .heaven
        )
        modelContext.insert(newTechnique)

        let legacy = Legacy(founder: creator.name, faction: factionName, technique: newTechnique.name, createdYear: world.year, influence: 12, descendants: 1)
        modelContext.insert(legacy)

        events.append(
            HistoryEvent(
                year: world.year,
                title: "\(creator.name) 创《\(newTechnique.name)》",
                detail: "\(creator.title) \(creator.name) 参照旧法推演新道，《\(newTechnique.name)》自 \(factionName) 流传后世。",
                category: .lineage,
                importance: 3
            )
        )

        return events
    }

    private static func nextRarity(after rarity: TechniqueRarity) -> TechniqueRarity {
        let all = TechniqueRarity.allCases
        guard let index = all.firstIndex(of: rarity) else { return .profound }
        let nextIndex = all.index(after: index)
        return nextIndex < all.endIndex ? all[nextIndex] : rarity
    }
}
