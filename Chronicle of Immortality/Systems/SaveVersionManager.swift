import Foundation
import SwiftData

enum SaveVersionManager {
    static let currentVersion = 6

    static func ensureMetadata(
        metadata: [SaveMetadata],
        world: WorldState?,
        worldSeeds: [WorldSeed],
        modelContext: ModelContext
    ) {
        guard let world else { return }

        if let save = metadata.first {
            save.lastPlayedAt = .now
            save.worldAge = world.year
            save.seed = worldSeeds.first?.seed ?? save.seed
            if save.saveVersion < currentVersion {
                migrate(save: save, world: world)
            }
        } else {
            modelContext.insert(
                SaveMetadata(
                    saveVersion: currentVersion,
                    worldAge: world.year,
                    seed: worldSeeds.first?.seed ?? 0
                )
            )
        }
    }

    static func repairWorldDefaults(_ world: WorldState) {
        world.aura = GameMath.clamp(world.aura, lower: 1, upper: 100)
        world.fortune = GameMath.clamp(world.fortune, lower: 1, upper: 100)
        world.demonicThreat = GameMath.clamp(world.demonicThreat, lower: 0, upper: 100)
        world.civilizationLevel = GameMath.clamp(world.civilizationLevel, lower: 0, upper: 100)
        world.goldenAgeProgress = GameMath.clamp(world.goldenAgeProgress, lower: 0, upper: 100)
        world.calamityPressure = GameMath.clamp(world.calamityPressure, lower: 0, upper: 100)
    }

    static func repairTechniqueDefaults(
        for cultivator: Cultivator,
        world: WorldState,
        techniques: [Technique],
        knowledges: [TechniqueKnowledge],
        legacies: [Legacy],
        modelContext: ModelContext
    ) {
        cultivator.daoFoundation = GameMath.clamp(cultivator.daoFoundation <= 0 ? 60 : cultivator.daoFoundation, lower: 0, upper: 100)
        if cultivator.highestRealmName.isEmpty {
            cultivator.highestRealmName = cultivator.realm.name
        }

        for technique in techniques {
            if technique.minimumLuckToDiscover <= 0 {
                technique.minimumLuckToDiscover = Technique.defaultMinimumLuck(for: technique.rarity)
            }
            if technique.type == .movement && technique.movementSpeedBonus <= 0 {
                technique.movementSpeedBonus = technique.rarity >= .earth ? 28 : 10
            }
        }

        if techniques.allSatisfy({ !$0.isKnownToPlayer }) {
            for technique in techniques where technique.rarity <= .yellow || cultivator.equippedTechnique.map({ technique === $0 }) == true {
                technique.isKnownToPlayer = true
            }
        }

        cultivator.primaryTechnique = cultivator.primaryTechnique ?? cultivator.equippedTechnique ?? techniques.first { $0.isKnownToPlayer && $0.type == .cultivation }
        cultivator.bodyTechnique = cultivator.bodyTechnique ?? techniques.first { $0.isKnownToPlayer && $0.type == .body }
        cultivator.spiritTechnique = cultivator.spiritTechnique ?? techniques.first { $0.isKnownToPlayer && $0.type == .spirit }
        cultivator.combatTechnique = cultivator.combatTechnique ?? techniques.first { $0.isKnownToPlayer && ($0.type == .sword || $0.type == .demonic) }
        cultivator.movementTechnique = cultivator.movementTechnique ?? techniques.first { $0.isKnownToPlayer && $0.type == .movement }
        cultivator.equippedTechnique = cultivator.activePrimaryTechnique
        cultivator.refreshCultivationLimit()
        TechniqueKnowledgeSystem.ensureStartingKnowledge(for: cultivator, world: world, techniques: techniques, knowledges: knowledges, legacies: legacies, modelContext: modelContext)
    }

    private static func migrate(save: SaveMetadata, world: WorldState) {
        repairWorldDefaults(world)
        save.saveVersion = currentVersion
        save.lastPlayedAt = .now
        save.worldAge = world.year
    }
}
