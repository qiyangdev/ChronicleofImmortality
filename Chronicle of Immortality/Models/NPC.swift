import Foundation
import SwiftData

enum NPCPersonality: String, CaseIterable, Codable, Identifiable {
    case steady
    case ambitious
    case kind
    case ruthless
    case secluded

    nonisolated var id: String { rawValue }

    nonisolated var name: String {
        switch self {
        case .steady: "沉稳"
        case .ambitious: "野心"
        case .kind: "仁厚"
        case .ruthless: "狠厉"
        case .secluded: "避世"
        }
    }
}

@Model
final class NPC {
    var name: String
    var age: Int
    var realm: Realm
    var stage: Int
    var talent: Int
    var luck: Int
    var personality: NPCPersonality
    var lifespan: Int
    var sect: Sect?
    var isAlive: Bool
    var relationshipToPlayer: Int
    var title: String
    var cultivationProgress: Double
    var isAscended: Bool
    var deathYear: Int?

    init(
        name: String,
        age: Int,
        realm: Realm,
        stage: Int,
        talent: Int,
        luck: Int,
        personality: NPCPersonality,
        lifespan: Int? = nil,
        sect: Sect? = nil,
        isAlive: Bool = true,
        relationshipToPlayer: Int = 0,
        title: String? = nil,
        cultivationProgress: Double = 0,
        isAscended: Bool = false,
        deathYear: Int? = nil
    ) {
        self.name = name
        self.age = age
        self.realm = realm
        self.stage = stage
        self.talent = talent
        self.luck = luck
        self.personality = personality
        self.lifespan = lifespan ?? realm.lifespan
        self.sect = sect
        self.isAlive = isAlive
        self.relationshipToPlayer = relationshipToPlayer
        self.title = title ?? NPC.title(for: realm)
        self.cultivationProgress = cultivationProgress
        self.isAscended = isAscended
        self.deathYear = deathYear
    }

    var realmText: String {
        "\(realm.name) \(stage) 层"
    }

    var sectName: String {
        sect?.name ?? "散修"
    }

    var isDemonic: Bool {
        personality == .ruthless || (sect?.righteousness ?? 50) < 35
    }

    static func title(for realm: Realm) -> String {
        switch realm {
        case .mortal: "凡民"
        case .qiRefining: "炼气修士"
        case .foundation: "筑基修士"
        case .goldenCore: "金丹真人"
        case .nascentSoul: "元婴长老"
        case .spiritSevering: "化神尊者"
        case .voidRefining: "炼虚大修"
        case .integration: "合体真君"
        case .mahayana: "大乘圣君"
        case .tribulation: "渡劫天尊"
        case .trueImmortal: "飞升真仙"
        case .mysteriousImmortal: "玄仙"
        case .goldenImmortal: "金仙"
        case .taiyiGoldenImmortal: "太乙金仙"
        case .greatLuoGoldenImmortal: "大罗金仙"
        case .daoAncestor: "道祖"
        }
    }
}
