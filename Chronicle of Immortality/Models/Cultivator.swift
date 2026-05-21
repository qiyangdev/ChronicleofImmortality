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
        title: String = "无名散修"
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

    static func requiredQi(for realm: Realm, stage: Int) -> Double {
        let stageFactor = Double(max(stage, 1)) * 85
        return (stageFactor * realm.multiplier).rounded()
    }

    func refreshCultivationLimit() {
        lifespan = max(lifespan, realm.lifespan)
        maxQi = Cultivator.requiredQi(for: realm, stage: stage)
        qi = min(qi, maxQi)
    }
}
