import Foundation
import SwiftData

enum ResourceSystem {
    static func rentCave(cultivator: Cultivator, world: WorldState, region: Region?) -> GameEngineResult {
        guard spend(BalanceConfig.current.caveLeaseCost, from: cultivator) else {
            return insufficientStones(world: world, title: "洞府无缘")
        }
        cultivator.caveLeaseUntilYear = max(cultivator.caveLeaseUntilYear, world.year + BalanceConfig.current.caveLeaseYears)
        region?.aura = GameMath.clamp((region?.aura ?? world.aura) + 2, lower: 1, upper: 100)
        return GameEngineResult(gameEvents: [
            GameEvent(year: world.year, title: "租用洞府", detail: "\(cultivator.name) 耗费 \(BalanceConfig.current.caveLeaseCost) 枚灵石租下灵气洞府，闭关地灵机暂盛。", importance: 2)
        ])
    }

    static func hireProtector(cultivator: Cultivator, world: WorldState) -> GameEngineResult {
        guard spend(BalanceConfig.current.protectorCost, from: cultivator) else {
            return insufficientStones(world: world, title: "护法未成")
        }
        cultivator.protectorUntilYear = max(cultivator.protectorUntilYear, world.year + BalanceConfig.current.protectorYears)
        cultivator.changeDaoFoundation(by: 1.5)
        return GameEngineResult(gameEvents: [
            GameEvent(year: world.year, title: "请人护法", detail: "\(cultivator.name) 请同门护持道场，闭关遭外劫惊扰的风险暂降。", importance: 2)
        ])
    }

    static func buyLowTierFragment(
        cultivator: Cultivator,
        world: WorldState,
        techniques: [Technique],
        knowledges: [TechniqueKnowledge],
        modelContext: ModelContext
    ) -> GameEngineResult {
        guard spend(BalanceConfig.current.fragmentCost, from: cultivator) else {
            return insufficientStones(world: world, title: "残卷难购")
        }
        let candidates = techniques.filter {
            $0.rarity <= .profound
                && TechniqueKnowledgeSystem.knowledge(for: cultivator, technique: $0, knowledges: knowledges) == nil
        }
        guard let technique = candidates.randomElement() else {
            cultivator.spiritStone += BalanceConfig.current.fragmentCost
            return GameEngineResult(gameEvents: [
                GameEvent(year: world.year, title: "残卷无获", detail: "坊市中已无适合 \(cultivator.name) 的低阶残卷。")
            ])
        }

        let role = TechniqueKnowledgeSystem.defaultRole(for: technique)
        TechniqueKnowledgeSystem.grant(
            technique: technique,
            to: cultivator,
            role: role == .primary && cultivator.activePrimaryTechnique != nil ? .collection : role,
            mastery: 10,
            year: world.year,
            source: "坊市残卷",
            existing: knowledges,
            modelContext: modelContext
        )
        return GameEngineResult(gameEvents: [
            GameEvent(year: world.year, title: "购得残卷", detail: "\(cultivator.name) 耗费灵石，购得《\(technique.name)》残卷。", importance: 2)
        ])
    }

    static func donateToSect(cultivator: Cultivator, world: WorldState) -> GameEngineResult {
        guard let sect = cultivator.sect else {
            return GameEngineResult(gameEvents: [GameEvent(year: world.year, title: "无宗可供", detail: "散修无宗门可供奉。")])
        }
        guard spend(BalanceConfig.current.sectDonationCost, from: cultivator) else {
            return insufficientStones(world: world, title: "供奉未成")
        }
        sect.spiritStoneReserve += BalanceConfig.current.sectDonationCost
        sect.reputation = GameMath.clamp(sect.reputation + 1.2, lower: 0, upper: 100)
        sect.prosperity = GameMath.clamp(sect.prosperity + 1.8, lower: 0, upper: 100)
        cultivator.changeDaoFoundation(by: 0.8)
        return GameEngineResult(gameEvents: [
            GameEvent(year: world.year, title: "宗门供奉", detail: "\(cultivator.name) 向 \(sect.name) 供奉灵石，宗门库藏渐丰。", importance: 2)
        ])
    }

    static func handleSectDuty(
        cultivator: Cultivator,
        world: WorldState,
        sects: [Sect],
        npcs: [NPC],
        regions: [Region],
        factions: [Faction],
        techniques: [Technique],
        karmaRecords: [KarmaRecord],
        legacies: [Legacy],
        reincarnationRecords: [ReincarnationRecord],
        worldSeeds: [WorldSeed],
        modelContext: ModelContext
    ) -> GameEngineResult {
        var result = GameEngineResult()
        for _ in 0..<3 {
            result.historyEvents.append(contentsOf: WorldSystem.advanceYear(world: world, cultivator: cultivator, sects: sects, npcs: npcs, regions: regions, factions: factions, techniques: techniques, karmaRecords: karmaRecords, legacies: legacies, reincarnationRecords: reincarnationRecords, worldSeeds: worldSeeds, modelContext: modelContext))
            cultivator.age += 1
            if cultivator.age >= cultivator.lifespan {
                cultivator.isAlive = false
                cultivator.refreshHighestRealm()
                cultivator.deathSummary = "第 \(world.year) 年，\(cultivator.name) 享年 \(cultivator.age) 岁，最高境界 \(cultivator.highestRealmName)，因寿元耗尽而终。主修 \(cultivator.equippedTechniqueText)，\(cultivator.cultivationStateText)。"
                let event = GameEvent(year: world.year, title: "寿元耗尽", detail: "\(cultivator.name) 于宗门事务间寿元耗尽，坐化山门。", importance: 3)
                result.gameEvents.append(event)
                result.historyEvents.append(HistoryEvent(year: event.year, title: event.title, detail: event.detail, category: .player, importance: event.importance))
                result.historyEvents.append(LegacySystem.preservePlayerLegacy(player: cultivator, world: world, modelContext: modelContext))
                result.shouldStopAction = true
                return result
            }
        }
        if let sect = cultivator.sect {
            sect.reputation = GameMath.clamp(sect.reputation + Double.random(in: 1.0...3.6), lower: 0, upper: 100)
            sect.prosperity = GameMath.clamp(sect.prosperity + Double.random(in: 0.8...2.8), lower: 0, upper: 100)
            sect.spiritStoneReserve += Int(Double.random(in: 40...160) * BalanceConfig.current.spiritStoneYieldMultiplier)
            cultivator.spiritStone += Int(Double.random(in: 8...28) * BalanceConfig.current.spiritStoneYieldMultiplier)
            cultivator.changeDaoFoundation(by: Double.random(in: 0.8...2.2))
            _ = cultivator.updateSectRole()
            result.gameEvents.append(GameEvent(year: world.year, title: "宗门事务", detail: "\(cultivator.name) 处理三年宗务，\(sect.name) 声望与库藏皆有所增。", importance: 2))
        }
        return result
    }

    static func inferTechnique(
        cultivator: Cultivator,
        world: WorldState,
        techniques: [Technique],
        knowledges: [TechniqueKnowledge],
        modelContext: ModelContext
    ) -> GameEngineResult {
        let known = TechniqueKnowledgeSystem.knownTechniques(for: cultivator, techniques: techniques, knowledges: knowledges)
        guard let technique = known.randomElement(), cultivator.comprehension >= 55 else {
            return GameEngineResult(gameEvents: [GameEvent(year: world.year, title: "推演未成", detail: "\(cultivator.name) 静观经卷，灵机尚浅，未能推演新义。")])
        }
        TechniqueKnowledgeSystem.improveMastery(cultivator: cultivator, technique: technique, knowledges: knowledges, amount: BalanceConfig.current.techniqueMasteryGain + Double(cultivator.comprehension) / 40)
        cultivator.changeDaoFoundation(by: 0.6)
        return GameEngineResult(gameEvents: [
            GameEvent(year: world.year, title: "灵机推演", detail: "\(cultivator.name) 推演《\(technique.name)》，对其道理更明一分。", importance: 2)
        ])
    }

    private static func spend(_ cost: Int, from cultivator: Cultivator) -> Bool {
        guard cultivator.spiritStone >= cost else { return false }
        cultivator.spiritStone -= cost
        return true
    }

    private static func insufficientStones(world: WorldState, title: String) -> GameEngineResult {
        GameEngineResult(gameEvents: [
            GameEvent(year: world.year, title: title, detail: "灵石不足，此事只得暂缓。")
        ])
    }
}
