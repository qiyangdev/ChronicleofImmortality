import Foundation
import SwiftData

enum ReincarnationSystem {
    nonisolated static let minimumRealm: Realm = .nascentSoul

    static func reincarnate(player: Cultivator, world: WorldState, karmaRecords: [KarmaRecord], modelContext: ModelContext) -> GameEngineResult {
        guard player.realm >= minimumRealm else {
            let event = GameEvent(
                year: world.year,
                title: "轮回无门",
                detail: "\(player.name) 生前仅至 \(player.realmText)，神魂未成，难入轮回重修。",
                importance: 3
            )
            let history = HistoryEvent(
                year: world.year,
                title: "\(player.name) 道途断绝",
                detail: "\(player.name) 未能修成元神，身死之后因果散入天地，无法转世。",
                category: .reincarnation,
                importance: 3
            )
            return GameEngineResult(gameEvents: [event], historyEvents: [history], shouldStopAction: true)
        }

        let previousName = player.name
        let previousRealm = player.realm
        let inheritedTalent = min(100, max(35, Int(Double(player.talent) * 0.62) + Int.random(in: 8...22)))
        let inheritedLuck = min(100, max(25, Int(Double(player.luck) * 0.55) + Int.random(in: 5...18)))
        let karmaCarry = karmaRecords
            .filter { !$0.isResolved && ($0.source == previousName || $0.target == previousName) }
            .reduce(0) { $0 + $1.karmaValue / 3 }

        let newName = "\(previousName)转世"
        player.name = newName
        player.realm = .qiRefining
        player.stage = 1
        player.age = 16
        player.lifespan = Realm.qiRefining.lifespan + max(0, previousRealm.lifespan / 80)
        player.qi = 0
        player.maxQi = Cultivator.requiredQi(for: .qiRefining, stage: 1)
        player.spiritStone = max(10, player.spiritStone / 5)
        player.talent = inheritedTalent
        player.luck = inheritedLuck
        player.physique = max(35, min(100, player.physique - Int.random(in: 0...12)))
        player.comprehension = max(35, min(100, player.comprehension - Int.random(in: 0...10)))
        player.isAlive = true
        player.title = "转世修士"
        player.sectRole = .outerDisciple
        player.refreshCultivationLimit()
        world.reincarnationCount += 1

        let inheritance = "承前世\(previousRealm.name)记忆碎片与\(player.equippedTechniqueText)残篇"
        modelContext.insert(
            ReincarnationRecord(
                previousName: previousName,
                currentName: newName,
                previousRealm: previousRealm,
                inheritance: inheritance,
                karmaCarryOver: karmaCarry,
                year: world.year
            )
        )

        let gameEvent = GameEvent(
            year: world.year,
            title: "轮回重修",
            detail: "\(previousName) 一世终结，转生为 \(newName)，携部分因果与传承重入长生路。",
            importance: 3
        )
        let history = HistoryEvent(
            year: world.year,
            title: "\(previousName) 转世",
            detail: "\(previousName) 死后未绝，于轮回中重修，继承：\(inheritance)。",
            category: .reincarnation,
            importance: 3
        )
        return GameEngineResult(gameEvents: [gameEvent], historyEvents: [history])
    }
}
