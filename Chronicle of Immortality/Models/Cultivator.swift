import Foundation
import SwiftData

@Model
final class Cultivator {
    var name: String
    var realm: Realm
    var stage: Int
    var age: Int
    var lifespan: Int
    var qi: Double
    var maxQi: Double
    var spiritStone: Int
    var talent: Int
    var luck: Int
    var physique: Int
    var comprehension: Int
    var isAlive: Bool
    var title: String
    var daoFoundation: Double
    var deathSummary: String
    var highestRealmName: String
    var caveLeaseUntilYear: Int
    var protectorUntilYear: Int
    var sect: Sect?
    var sectRole: PlayerSectRole
    var equippedTechnique: Technique?
    var primaryTechnique: Technique?
    var bodyTechnique: Technique?
    var spiritTechnique: Technique?
    var combatTechnique: Technique?
    var movementTechnique: Technique?

    init(
        name: String,
        realm: Realm = .qiRefining,
        stage: Int = 1,
        age: Int = 16,
        spiritStone: Int = 20,
        talent: Int = Int.random(in: 45...85),
        luck: Int = Int.random(in: 35...90),
        physique: Int = Int.random(in: 40...85),
        comprehension: Int = Int.random(in: 45...90),
        title: String = "无名散修",
        daoFoundation: Double = 60,
        deathSummary: String = "",
        highestRealmName: String? = nil,
        caveLeaseUntilYear: Int = 0,
        protectorUntilYear: Int = 0,
        sect: Sect? = nil,
        sectRole: PlayerSectRole = .outerDisciple,
        equippedTechnique: Technique? = nil,
        primaryTechnique: Technique? = nil,
        bodyTechnique: Technique? = nil,
        spiritTechnique: Technique? = nil,
        combatTechnique: Technique? = nil,
        movementTechnique: Technique? = nil
    ) {
        self.name = name
        self.realm = realm
        self.stage = stage
        self.age = age
        self.lifespan = realm.lifespan
        self.qi = 0
        self.maxQi = Cultivator.requiredQi(for: realm, stage: stage)
        self.spiritStone = spiritStone
        self.talent = talent
        self.luck = luck
        self.physique = physique
        self.comprehension = comprehension
        self.isAlive = true
        self.title = title
        self.daoFoundation = min(max(daoFoundation, 0), 100)
        self.deathSummary = deathSummary
        self.highestRealmName = highestRealmName ?? realm.name
        self.caveLeaseUntilYear = caveLeaseUntilYear
        self.protectorUntilYear = protectorUntilYear
        self.sect = sect
        self.sectRole = sectRole
        self.equippedTechnique = equippedTechnique
        self.primaryTechnique = primaryTechnique ?? equippedTechnique
        self.bodyTechnique = bodyTechnique
        self.spiritTechnique = spiritTechnique
        self.combatTechnique = combatTechnique
        self.movementTechnique = movementTechnique
    }

    var realmText: String {
        "\(realm.name) \(stage) 层"
    }

    var qiProgress: Double {
        guard maxQi > 0 else { return 0 }
        return min(qi / maxQi, 1)
    }

    var remainingLifespan: Int {
        max(lifespan - age, 0)
    }

    var hasReachedPeak: Bool {
        realm.isFinal && stage >= 9
    }

    var canReincarnate: Bool {
        realm >= ReincarnationSystem.minimumRealm
    }

    var sectName: String {
        sect?.name ?? "散修"
    }

    var equippedTechniqueText: String {
        activePrimaryTechnique?.name ?? "未主修"
    }

    var activePrimaryTechnique: Technique? {
        primaryTechnique ?? equippedTechnique
    }

    var practicedTechniques: [Technique] {
        var seen: Set<String> = []
        return [activePrimaryTechnique, bodyTechnique, spiritTechnique, combatTechnique, movementTechnique].compactMap { technique in
            guard let technique, !seen.contains(technique.name) else { return nil }
            seen.insert(technique.name)
            return technique
        }
    }

    var cultivationBonus: Double {
        let primary = activePrimaryTechnique?.cultivationBonus ?? 0
        let body = bodyTechnique.map { $0.cultivationBonus * 0.25 } ?? 0
        let spirit = spiritTechnique.map { $0.cultivationBonus * 0.35 } ?? 0
        let combat = combatTechnique.map { $0.cultivationBonus * 0.18 } ?? 0
        let movement = movementTechnique.map { $0.cultivationBonus * 0.08 } ?? 0
        return primary + body + spirit + combat + movement
    }

    var breakthroughBonus: Double {
        let primary = activePrimaryTechnique?.breakthroughBonus ?? 0
        let spirit = spiritTechnique.map { $0.breakthroughBonus * 0.55 } ?? 0
        let body = bodyTechnique.map { $0.breakthroughBonus * 0.18 } ?? 0
        let combat = combatTechnique.map { $0.breakthroughBonus * 0.12 } ?? 0
        return primary + spirit + body + combat
    }

    var explorationBonus: Double {
        practicedTechniques.reduce(0) { partial, technique in
            let base: Double
            switch technique.type {
            case .body: base = 0.08
            case .spirit: base = 0.06
            case .sword: base = 0.1
            case .movement: base = 0.04 + technique.movementSpeedBonus / 100
            case .demonic: base = 0.05
            case .cultivation: base = 0.03
            }
            return partial + base
        }
    }

    var movementSpeedBonus: Double {
        movementTechnique?.movementSpeedBonus ?? 0
    }

    var canBypassRegionSeal: Bool {
        movementTechnique?.canBypassRegionSeal == true
    }

    var cultivationStateText: String {
        switch daoFoundation {
        case 82...: "道基浑厚"
        case 64...: "根基稳固"
        case 42...: "道基尚可"
        case 22...: "根基浮动"
        default: "道基濒裂"
        }
    }

    func changeDaoFoundation(by amount: Double) {
        daoFoundation = min(max(daoFoundation + amount, 0), 100)
    }

    func refreshHighestRealm() {
        guard let current = Realm.allCases.first(where: { $0.name == highestRealmName }) else {
            highestRealmName = realm.name
            return
        }
        if realm >= current {
            highestRealmName = realm.name
        }
    }

    func hasCaveLease(in world: WorldState) -> Bool {
        caveLeaseUntilYear >= world.year
    }

    func hasProtector(in world: WorldState) -> Bool {
        protectorUntilYear >= world.year
    }

    static func requiredQi(for realm: Realm, stage: Int) -> Double {
        let stageFactor = pow(Double(max(stage, 1)), 1.45) * 155
        let realmFactor = pow(realm.multiplier, 1.18)
        return (stageFactor * realmFactor).rounded()
    }

    func refreshCultivationLimit() {
        equippedTechnique = activePrimaryTechnique
        let techniqueLife = practicedTechniques.reduce(0) { total, technique in
            let weight: Double
            if activePrimaryTechnique.map({ technique === $0 }) == true {
                weight = 1
            } else if bodyTechnique.map({ technique === $0 }) == true {
                weight = 0.55
            } else if spiritTechnique.map({ technique === $0 }) == true {
                weight = 0.25
            } else {
                weight = 0.12
            }
            return total + Int(Double(technique.lifespanBonus) * weight)
        }
        lifespan = max(lifespan, Int(Double(realm.lifespan + techniqueLife) * BalanceConfig.current.lifespanMultiplier))
        maxQi = Cultivator.requiredQi(for: realm, stage: stage)
        qi = min(qi, maxQi)
    }

    func updateSectRole() -> PlayerSectRole {
        let nextRole: PlayerSectRole
        switch realm {
        case .mortal, .qiRefining:
            nextRole = stage >= 6 ? .innerDisciple : .outerDisciple
        case .foundation, .goldenCore:
            nextRole = .trueDisciple
        case .nascentSoul, .spiritSevering, .voidRefining:
            nextRole = .elder
        case .integration, .mahayana, .tribulation, .trueImmortal, .mysteriousImmortal, .goldenImmortal, .taiyiGoldenImmortal, .greatLuoGoldenImmortal, .daoAncestor:
            nextRole = .sectMaster
        }

        sectRole = max(sectRole, nextRole)
        return sectRole
    }
}
