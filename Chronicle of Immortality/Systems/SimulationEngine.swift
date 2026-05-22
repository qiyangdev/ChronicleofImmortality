import Foundation
import SwiftData

enum SimulationEngine {
    static func cultivate(
        cultivator: Cultivator,
        world: WorldState,
        sects: [Sect],
        npcs: [NPC],
        regions: [Region],
        factions: [Faction],
        techniques: [Technique],
        techniqueKnowledges: [TechniqueKnowledge],
        karmaRecords: [KarmaRecord],
        legacies: [Legacy],
        reincarnationRecords: [ReincarnationRecord],
        worldSeeds: [WorldSeed],
        recentHistory: [HistoryEvent],
        years: Int,
        modelContext: ModelContext,
        config: BalanceConfig = .current
    ) async -> GameEngineResult {
        var result = GameEngineResult()
        var remainingYears = max(1, years)

        while remainingYears > 0 {
            let step = min(remainingYears, config.batchYieldInterval)
            result.append(
                GameEngine.cultivate(
                    cultivator: cultivator,
                    world: world,
                    sects: sects,
                    npcs: npcs,
                    regions: regions,
                    factions: factions,
                    techniques: techniques,
                    techniqueKnowledges: techniqueKnowledges,
                    karmaRecords: karmaRecords,
                    legacies: legacies,
                    reincarnationRecords: reincarnationRecords,
                    worldSeeds: worldSeeds,
                    years: step,
                    modelContext: modelContext
                )
            )
            remainingYears -= step
            if result.shouldStopAction {
                break
            }
            await Task.yield()
        }

        return filtered(result, recentHistory: recentHistory, config: config)
    }

    static func explore(
        cultivator: Cultivator,
        world: WorldState,
        region: Region,
        sects: [Sect],
        npcs: [NPC],
        regions: [Region],
        factions: [Faction],
        techniques: [Technique],
        techniqueKnowledges: [TechniqueKnowledge],
        karmaRecords: [KarmaRecord],
        legacies: [Legacy],
        reincarnationRecords: [ReincarnationRecord],
        worldSeeds: [WorldSeed],
        recentHistory: [HistoryEvent],
        years: Int,
        modelContext: ModelContext,
        config: BalanceConfig = .current
    ) async -> GameEngineResult {
        var result = GameEngineResult()
        var remainingYears = max(1, years)

        while remainingYears > 0 {
            let step = min(remainingYears, config.batchYieldInterval)
            result.append(
                ExplorationSystem.explore(
                    cultivator: cultivator,
                    world: world,
                    region: region,
                    sects: sects,
                    npcs: npcs,
                    regions: regions,
                    factions: factions,
                    techniques: techniques,
                    techniqueKnowledges: techniqueKnowledges,
                    karmaRecords: karmaRecords,
                    legacies: legacies,
                    reincarnationRecords: reincarnationRecords,
                    worldSeeds: worldSeeds,
                    years: step,
                    modelContext: modelContext
                )
            )
            remainingYears -= step
            if result.shouldStopAction {
                break
            }
            await Task.yield()
        }

        return filtered(result, recentHistory: recentHistory, config: config)
    }

    static func seclude(
        cultivator: Cultivator,
        world: WorldState,
        region: Region?,
        sects: [Sect],
        npcs: [NPC],
        regions: [Region],
        factions: [Faction],
        techniques: [Technique],
        karmaRecords: [KarmaRecord],
        legacies: [Legacy],
        reincarnationRecords: [ReincarnationRecord],
        worldSeeds: [WorldSeed],
        recentHistory: [HistoryEvent],
        modelContext: ModelContext,
        config: BalanceConfig = .current
    ) async -> GameEngineResult {
        let result = SeclusionSystem.enterSeclusion(
            cultivator: cultivator,
            world: world,
            region: region,
            sects: sects,
            npcs: npcs,
            regions: regions,
            factions: factions,
            techniques: techniques,
            karmaRecords: karmaRecords,
            legacies: legacies,
            reincarnationRecords: reincarnationRecords,
            worldSeeds: worldSeeds,
            modelContext: modelContext,
            config: config
        )
        await Task.yield()
        return filtered(result, recentHistory: recentHistory, config: config)
    }

    static func filtered(_ result: GameEngineResult, recentHistory: [HistoryEvent], config: BalanceConfig = .current) -> GameEngineResult {
        GameEngineResult(
            gameEvents: EventFilterSystem.filterGameEvents(result.gameEvents, config: config),
            historyEvents: EventFilterSystem.filterHistoryEvents(result.historyEvents, recentEvents: recentHistory, config: config),
            shouldStopAction: result.shouldStopAction
        )
    }
}
