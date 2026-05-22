import Foundation
import SwiftData

enum RegionState: String, CaseIterable, Codable, Identifiable {
    case calm
    case auraResurgence
    case relicOpen
    case beastTide
    case demonicDisaster
    case sectBlockade

    nonisolated var id: String { rawValue }

    nonisolated var name: String {
        switch self {
        case .calm: "平静"
        case .auraResurgence: "灵脉复苏"
        case .relicOpen: "遗迹开启"
        case .beastTide: "兽潮"
        case .demonicDisaster: "魔灾"
        case .sectBlockade: "宗门封锁"
        }
    }

    nonisolated var isDangerous: Bool {
        switch self {
        case .beastTide, .demonicDisaster, .sectBlockade: true
        case .calm, .auraResurgence, .relicOpen: false
        }
    }
}

@Model
final class Region {
    var name: String
    var aura: Double
    var danger: Double
    var resources: Double
    var demonicInfluence: Double
    var unlockedRealm: Realm
    var state: RegionState
    var stateUntilYear: Int

    init(
        name: String,
        aura: Double,
        danger: Double,
        resources: Double,
        demonicInfluence: Double,
        unlockedRealm: Realm,
        state: RegionState = .calm,
        stateUntilYear: Int = 0
    ) {
        self.name = name
        self.aura = aura
        self.danger = danger
        self.resources = resources
        self.demonicInfluence = demonicInfluence
        self.unlockedRealm = unlockedRealm
        self.state = state
        self.stateUntilYear = stateUntilYear
    }

    var unlockText: String {
        "此地凶险，非\(unlockedRealm.name)之上不可入内"
    }

    func isBlocked(for cultivator: Cultivator) -> Bool {
        state == .sectBlockade && cultivator.realm < unlockedRealm && !cultivator.canBypassRegionSeal
    }
}
