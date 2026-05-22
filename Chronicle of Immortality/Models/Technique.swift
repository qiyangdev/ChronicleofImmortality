import Foundation
import SwiftData

enum TechniqueType: String, CaseIterable, Codable, Identifiable {
    case cultivation
    case body
    case spirit
    case sword
    case movement
    case demonic

    nonisolated var id: String { rawValue }

    nonisolated var name: String {
        switch self {
        case .cultivation: "修炼功法"
        case .body: "炼体功法"
        case .spirit: "神识功法"
        case .sword: "剑诀"
        case .movement: "遁法"
        case .demonic: "魔功"
        }
    }
}

enum TechniqueRarity: String, CaseIterable, Codable, Identifiable, Comparable {
    case common
    case yellow
    case profound
    case earth
    case heaven
    case saint

    nonisolated var id: String { rawValue }

    nonisolated var name: String {
        switch self {
        case .common: "凡阶"
        case .yellow: "黄阶"
        case .profound: "玄阶"
        case .earth: "地阶"
        case .heaven: "天阶"
        case .saint: "圣阶"
        }
    }

    nonisolated var rank: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }

    nonisolated static func < (lhs: TechniqueRarity, rhs: TechniqueRarity) -> Bool {
        lhs.rank < rhs.rank
    }
}

@Model
final class Technique {
    var name: String
    var type: TechniqueType
    var rarity: TechniqueRarity
    var cultivationBonus: Double
    var breakthroughBonus: Double
    var lifespanBonus: Int
    var sideEffect: String
    var creator: String
    var createdYear: Int
    var originFaction: String
    var inheritedCount: Int
    var isKnownToPlayer: Bool = false
    var minimumLuckToDiscover: Int = 40
    var movementSpeedBonus: Double = 0
    var canBypassRegionSeal: Bool = false

    init(
        name: String,
        type: TechniqueType,
        rarity: TechniqueRarity,
        cultivationBonus: Double,
        breakthroughBonus: Double,
        lifespanBonus: Int,
        sideEffect: String,
        creator: String = "佚名古修",
        createdYear: Int = 0,
        originFaction: String = "无源道统",
        inheritedCount: Int = 0,
        isKnownToPlayer: Bool = false,
        minimumLuckToDiscover: Int? = nil,
        movementSpeedBonus: Double = 0,
        canBypassRegionSeal: Bool = false
    ) {
        self.name = name
        self.type = type
        self.rarity = rarity
        self.cultivationBonus = cultivationBonus
        self.breakthroughBonus = breakthroughBonus
        self.lifespanBonus = lifespanBonus
        self.sideEffect = sideEffect
        self.creator = creator
        self.createdYear = createdYear
        self.originFaction = originFaction
        self.inheritedCount = inheritedCount
        self.isKnownToPlayer = isKnownToPlayer
        self.minimumLuckToDiscover = minimumLuckToDiscover ?? Technique.defaultMinimumLuck(for: rarity)
        self.movementSpeedBonus = movementSpeedBonus
        self.canBypassRegionSeal = canBypassRegionSeal
    }

    var summaryText: String {
        "\(rarity.name) · \(type.name)"
    }

    var discoveryText: String {
        isKnownToPlayer ? "已掌握" : "未得传承"
    }

    nonisolated static func defaultMinimumLuck(for rarity: TechniqueRarity) -> Int {
        switch rarity {
        case .common: 20
        case .yellow: 38
        case .profound: 64
        case .earth: 82
        case .heaven: 94
        case .saint: 99
        }
    }
}
