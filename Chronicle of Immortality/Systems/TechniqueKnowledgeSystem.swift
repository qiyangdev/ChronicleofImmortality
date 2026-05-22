import Foundation
import SwiftData

enum TechniqueKnowledgeSystem {
    static func knownTechniques(
        for cultivator: Cultivator,
        techniques: [Technique],
        knowledges: [TechniqueKnowledge]
    ) -> [Technique] {
        let names = Set(knowledges.filter { $0.cultivatorName == cultivator.name }.map(\.techniqueName))
        var result = techniques.filter { names.contains($0.name) }
        for technique in cultivator.practicedTechniques where !result.contains(where: { $0.name == technique.name }) {
            result.append(technique)
        }
        return result.sorted { $0.rarity == $1.rarity ? $0.name < $1.name : $0.rarity < $1.rarity }
    }

    static func knowledge(
        for cultivator: Cultivator,
        technique: Technique,
        knowledges: [TechniqueKnowledge]
    ) -> TechniqueKnowledge? {
        knowledges.first { $0.cultivatorName == cultivator.name && $0.techniqueName == technique.name }
    }

    @discardableResult
    static func grant(
        technique: Technique,
        to cultivator: Cultivator,
        role: TechniquePracticeRole = .collection,
        mastery: Double,
        year: Int,
        source: String,
        existing: [TechniqueKnowledge],
        modelContext: ModelContext
    ) -> TechniqueKnowledge {
        technique.isKnownToPlayer = true
        if let current = knowledge(for: cultivator, technique: technique, knowledges: existing) {
            current.mastery = max(current.mastery, mastery)
            if current.role == .collection {
                current.role = role
            }
            return current
        }

        let knowledge = TechniqueKnowledge(
            cultivatorName: cultivator.name,
            techniqueName: technique.name,
            role: role,
            mastery: mastery,
            acquiredYear: year,
            source: source
        )
        modelContext.insert(knowledge)
        return knowledge
    }

    static func ensureStartingKnowledge(
        for cultivator: Cultivator,
        world: WorldState,
        techniques: [Technique],
        knowledges: [TechniqueKnowledge],
        legacies: [Legacy],
        modelContext: ModelContext
    ) {
        let existing = knowledges.filter { $0.cultivatorName == cultivator.name }
        guard existing.isEmpty else { return }

        for technique in techniques where technique.rarity <= .yellow {
            let role = defaultRole(for: technique)
            grant(technique: technique, to: cultivator, role: role, mastery: 18, year: world.year, source: "入门传承", existing: knowledges, modelContext: modelContext)
            assign(technique: technique, role: role, to: cultivator)
        }

        for legacy in legacies where legacy.influence >= 25 {
            guard let technique = techniques.first(where: { $0.name == legacy.technique && $0.rarity <= .earth }) else { continue }
            if GameMath.chance(min(18 + legacy.influence / 4, 38)) {
                grant(technique: technique, to: cultivator, role: defaultRole(for: technique), mastery: 8, year: world.year, source: "道统余泽", existing: knowledges, modelContext: modelContext)
            }
        }

        cultivator.refreshCultivationLimit()
    }

    static func setPracticeRole(
        cultivator: Cultivator,
        technique: Technique?,
        role: TechniquePracticeRole,
        knowledges: [TechniqueKnowledge]
    ) {
        for knowledge in knowledges where knowledge.cultivatorName == cultivator.name && knowledge.role == role {
            knowledge.role = .collection
        }
        if let technique, let knowledge = knowledge(for: cultivator, technique: technique, knowledges: knowledges) {
            knowledge.role = role
        }
        assign(technique: technique, role: role, to: cultivator)
        cultivator.refreshCultivationLimit()
    }

    static func improveMastery(
        cultivator: Cultivator,
        technique: Technique,
        knowledges: [TechniqueKnowledge],
        amount: Double
    ) {
        guard let knowledge = knowledge(for: cultivator, technique: technique, knowledges: knowledges) else { return }
        knowledge.mastery = GameMath.clamp(knowledge.mastery + amount, lower: 0, upper: 100)
    }

    static func defaultRole(for technique: Technique) -> TechniquePracticeRole {
        switch technique.type {
        case .cultivation: .primary
        case .body: .body
        case .spirit: .spirit
        case .sword, .demonic: .combat
        case .movement: .movement
        }
    }

    private static func assign(technique: Technique?, role: TechniquePracticeRole, to cultivator: Cultivator) {
        switch role {
        case .primary:
            cultivator.primaryTechnique = technique
            cultivator.equippedTechnique = technique
        case .body:
            cultivator.bodyTechnique = technique
        case .spirit:
            cultivator.spiritTechnique = technique
        case .combat:
            cultivator.combatTechnique = technique
        case .movement:
            cultivator.movementTechnique = technique
        case .collection:
            break
        }
    }
}
