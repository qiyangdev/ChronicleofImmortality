import Foundation
import SwiftData

enum NPCSystem {
    static func advance(npcs: [NPC], sects: [Sect], world: WorldState, player: Cultivator, modelContext: ModelContext) -> [HistoryEvent] {
        var events: [HistoryEvent] = []

        for npc in npcs where npc.isAlive {
            npc.age += 1

            if npc.age >= npc.lifespan {
                events.append(kill(npc, world: world, reason: "寿元耗尽"))
                continue
            }

            if npc.sect == nil, let event = joinSect(npc: npc, sects: sects, world: world) {
                events.append(event)
            }

            if let event = defectIfNeeded(npc: npc, sects: sects, world: world) {
                events.append(event)
            }

            npc.cultivationProgress += yearlyCultivation(for: npc, world: world)
            let requirement = Cultivator.requiredQi(for: npc.realm, stage: npc.stage)

            if npc.cultivationProgress >= requirement, let event = attemptBreakthrough(npc: npc, world: world, player: player) {
                events.append(event)
            }
        }

        if let event = birthNewCultivator(npcs: npcs, sects: sects, world: world, modelContext: modelContext) {
            events.append(event)
        }

        events.append(contentsOf: prunePopulation(npcs: npcs, world: world, player: player, modelContext: modelContext))

        return events
    }

    private static func yearlyCultivation(for npc: NPC, world: WorldState) -> Double {
        guard npc.realm <= BalanceConfig.current.maxNPCRealmForAmbientGrowth else { return 0 }
        let sectBonus = (npc.sect?.prosperity ?? 35) / 100
        let talent = Double(npc.talent) / 95
        let luck = Double(npc.luck) / 150
        let aura = world.aura / 72
        let personalityBonus = npc.personality == .secluded ? 1.1 : 1.0
        let oldAgePenalty = oldAgePressure(age: npc.age, lifespan: npc.lifespan) * BalanceConfig.current.npcOldAgeQiPenaltyMax
        let vitality = GameMath.clamp(1 - oldAgePenalty, lower: 0.18, upper: 1)
        return (4 + talent * 6 + luck * 3) * aura * (0.72 + sectBonus * 0.7) * personalityBonus * vitality * BalanceConfig.current.npcGrowthMultiplier
    }

    private static func attemptBreakthrough(npc: NPC, world: WorldState, player: Cultivator) -> HistoryEvent? {
        let isMajorBreakthrough = npc.stage >= 9
        let baseChance = (isMajorBreakthrough ? 10.0 : 18.0)
            + Double(npc.talent) * 0.12
            + Double(npc.luck) * 0.08
            + world.fortune * 0.07
            + world.aura * 0.05
        let agePressure = oldAgePressure(age: npc.age, lifespan: npc.lifespan)
        let stageProgress = Double(max(npc.stage - 1, 0)) / 8
        let stagePenalty = pow(stageProgress, 1.45) * 22
        let highRealmStagePenalty = stageProgress * min(pow(npc.realm.multiplier, 0.45) * 1.2, 12)
        let penalty = pow(npc.realm.multiplier, 0.72) * 2.4
            + world.demonicThreat * 0.05
            + agePressure * BalanceConfig.current.npcOldAgeBreakthroughPenaltyMax
            + stagePenalty
            + highRealmStagePenalty
            + (isMajorBreakthrough ? 18 : 0)
        let chance = GameMath.clamp(
            (baseChance - penalty) * BalanceConfig.current.breakthroughChanceMultiplier,
            lower: isMajorBreakthrough ? 1 : 2,
            upper: isMajorBreakthrough ? 38 : 58
        )
        npc.cultivationProgress = 0

        guard GameMath.chance(chance) else {
            if GameMath.chance(8 + npc.realm.multiplier / 18 + agePressure * 28) {
                let lifespanLoss = Int(Double.random(in: 4...60) + agePressure * Double.random(in: 18...120))
                npc.lifespan = max(npc.age + 1, npc.lifespan - lifespanLoss)

                if isLifespanCritical(npc), GameMath.chance(BalanceConfig.current.desperateBreakthroughDeathChance + agePressure * 38) {
                    return kill(npc, world: world, reason: "寿元将尽时强行破境")
                }

                return HistoryEvent(
                    year: world.year,
                    title: "\(npc.name) 破境受创",
                    detail: "\(npc.name) 冲击 \(npc.realm.name) 瓶颈失败，道基受损，寿元暗折。",
                    category: .npc,
                    importance: 1
                )
            }
            return nil
        }

        let previousRealm = npc.realm
        advanceRealm(for: npc)

        if previousRealm == .tribulation && npc.realm == .trueImmortal {
            npc.isAlive = false
            npc.isAscended = true
            npc.deathYear = world.year
            npc.title = NPC.title(for: npc.realm)
            world.ascensionCount += 1
            world.fortune = GameMath.clamp(world.fortune + 7, lower: 1, upper: 100)
            world.aura = GameMath.clamp(world.aura + 5, lower: 1, upper: 100)

            return HistoryEvent(
                year: world.year,
                title: "\(npc.name) 飞升成仙",
                detail: "\(npc.name) 渡尽雷劫，自 \(previousRealm.name) 登临真仙，成为此世飞升者之一。",
                category: .ascension,
                importance: 3
            )
        }

        let importance = npc.realm >= player.realm ? 2 : 1
        return HistoryEvent(
            year: world.year,
            title: "\(npc.name) 突破\(npc.realm.name)",
            detail: "\(npc.name) 自 \(previousRealm.name) 更进一步，踏入 \(npc.realmText)，\(npc.sectName) 因之震动。",
            category: .npc,
            importance: importance
        )
    }

    private static func advanceRealm(for npc: NPC) {
        let previousRealm = npc.realm
        if npc.stage < 9 {
            npc.stage += 1
        } else if let nextRealm = npc.realm.next {
            npc.realm = nextRealm
            npc.stage = 1
        }

        npc.title = NPC.title(for: npc.realm)
        if npc.realm != previousRealm {
            npc.lifespan = max(npc.lifespan, npc.realm.lifespan + Int(Double(npc.talent) * 0.8))
        }

        if npc.realm >= .nascentSoul {
            npc.sect?.elderCount += 1
        }
    }

    private static func joinSect(npc: NPC, sects: [Sect], world: WorldState) -> HistoryEvent? {
        guard GameMath.chance(3.5), let sect = sects.randomElement() else { return nil }

        npc.sect = sect
        sect.disciplesCount += 1

        return HistoryEvent(
            year: world.year,
            title: "\(npc.name) 拜入\(sect.name)",
            detail: "散修 \(npc.name) 入 \(sect.name) 山门，从此卷入宗门气运。",
            category: .npc,
            importance: 1
        )
    }

    private static func defectIfNeeded(npc: NPC, sects: [Sect], world: WorldState) -> HistoryEvent? {
        guard npc.sect != nil else { return nil }
        let ambition = npc.personality == .ambitious || npc.personality == .ruthless
        let pressure = world.demonicThreat > 58 || (npc.sect?.prosperity ?? 50) < 22
        guard ambition, pressure, GameMath.chance(1.4 + world.demonicThreat / 80) else { return nil }

        let oldSect = npc.sect
        oldSect?.disciplesCount = max(0, (oldSect?.disciplesCount ?? 0) - 1)

        if let demonicSect = sects.filter({ $0.righteousness < 35 }).randomElement() {
            npc.sect = demonicSect
            demonicSect.disciplesCount += 1
        } else {
            npc.sect = nil
        }

        world.demonicThreat = GameMath.clamp(world.demonicThreat + Double.random(in: 1...4), lower: 0, upper: 100)

        return HistoryEvent(
            year: world.year,
            title: "\(npc.name) 叛出宗门",
            detail: "\(npc.name) 背弃 \(oldSect?.name ?? "旧宗")，投身更险恶的道途，魔道声势暗涨。",
            category: .npc,
            importance: 2
        )
    }

    private static func kill(_ npc: NPC, world: WorldState, reason: String) -> HistoryEvent {
        npc.isAlive = false
        npc.isAscended = false
        npc.deathYear = world.year
        npc.sect?.elderCount = max(0, (npc.sect?.elderCount ?? 0) - (npc.realm >= .nascentSoul ? 1 : 0))

        return HistoryEvent(
            year: world.year,
            title: "\(npc.name) 坐化",
            detail: "\(npc.sectName) \(npc.title) \(npc.name) 因\(reason)而坐化，享年 \(npc.age) 岁。",
            category: .npc,
            importance: npc.realm >= .nascentSoul ? 2 : 1
        )
    }

    private static func birthNewCultivator(npcs: [NPC], sects: [Sect], world: WorldState, modelContext: ModelContext) -> HistoryEvent? {
        let aliveCount = npcs.filter(\.isAlive).count
        guard aliveCount < BalanceConfig.current.npcPopulationTarget else { return nil }

        let eraBonus: Double
        if world.currentEra == "黄金大世" {
            eraBonus = 18
        } else if world.currentEra == "末法时代" {
            eraBonus = -8
        } else {
            eraBonus = 0
        }
        let chance = BalanceConfig.current.npcBirthBaseChance
            + world.aura / 8
            + world.civilizationLevel / 12
            + eraBonus
            - Double(aliveCount) / 2
        guard GameMath.chance(GameMath.clamp(chance, lower: 2, upper: 62)) else { return nil }

        let given = ["陆", "沈", "李", "韩", "顾", "谢", "楚", "秦", "白", "宁", "苏", "叶"].randomElement() ?? "陆"
        let name = "\(given)\(["玄", "青", "明", "寒", "照", "微", "衡", "昭"].randomElement() ?? "玄")\(["尘", "霜", "舟", "岳", "宁", "仪", "川", "离"].randomElement() ?? "尘")"
        let goldenAgeBonus = world.currentEra == "黄金大世" ? BalanceConfig.current.npcGoldenAgeTalentBonus : 0
        let demonic = world.demonicThreat > 68 && GameMath.chance(32)
        let talent = min(100, Int.random(in: 42...82) + goldenAgeBonus + (GameMath.chance(5) ? 16 : 0))
        let luck = min(100, Int.random(in: 35...88) + (world.fortune > 68 ? 8 : 0))
        let sect = demonic ? sects.filter { $0.righteousness < 35 }.randomElement() : sects.randomElement()
        let npc = NPC(
            name: name,
            age: Int.random(in: 14...24),
            realm: .qiRefining,
            stage: Int.random(in: 1...3),
            talent: talent,
            luck: luck,
            personality: demonic ? .ruthless : (talent >= 88 ? .ambitious : NPCPersonality.allCases.randomElement() ?? .steady),
            sect: sect,
            title: talent >= 90 ? "新晋天骄" : nil
        )
        modelContext.insert(npc)
        sect?.disciplesCount += 1

        guard talent >= 90 || demonic else { return nil }
        return HistoryEvent(
            year: world.year,
            title: talent >= 90 ? "\(name) 入道" : "\(name) 魔胎初现",
            detail: talent >= 90 ? "\(name) 天资卓绝，拜入 \(sect?.name ?? "散修一脉")，被视作新一代天骄。" : "\(name) 生逢魔气炽盛之年，早早踏上凶险魔途。",
            category: .npc,
            importance: 2
        )
    }

    private static func prunePopulation(npcs: [NPC], world: WorldState, player: Cultivator, modelContext: ModelContext) -> [HistoryEvent] {
        guard npcs.count > BalanceConfig.current.npcPopulationHardCap else { return [] }

        let candidates = npcs.filter {
            !$0.isAlive
                && !$0.isAscended
                && $0.realm < .nascentSoul
                && $0.name != player.name
                && (world.year - ($0.deathYear ?? 0)) > 240
        }
        let removeCount = min(candidates.count, npcs.count - BalanceConfig.current.npcPopulationTarget)
        for npc in candidates.prefix(removeCount) {
            modelContext.delete(npc)
        }
        return []
    }

    private static func oldAgePressure(age: Int, lifespan: Int) -> Double {
        guard lifespan > 0 else { return 1 }
        let ratio = Double(age) / Double(lifespan)
        let start = BalanceConfig.current.oldAgeDeclineStartRatio
        guard ratio > start else { return 0 }
        return GameMath.clamp((ratio - start) / max(0.01, 1 - start), lower: 0, upper: 1)
    }

    private static func isLifespanCritical(_ npc: NPC) -> Bool {
        guard npc.lifespan > 0 else { return true }
        let remaining = max(npc.lifespan - npc.age, 0)
        let remainingRatio = Double(remaining) / Double(npc.lifespan)
        return remainingRatio <= BalanceConfig.current.lifespanWarningRatio
    }
}
