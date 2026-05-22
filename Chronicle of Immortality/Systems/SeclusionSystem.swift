import Foundation
import SwiftData

struct SeclusionOpportunity {
    let isAvailable: Bool
    let title: String
    let detail: String
    let quality: Double

    var qualityText: String {
        switch quality {
        case 0.82...: "天机明澈"
        case 0.72...: "灵机已至"
        case 0.62...: "似有所感"
        default: "机缘未至"
        }
    }
}

enum SeclusionSystem {
    static func evaluateOpportunity(
        cultivator: Cultivator,
        world: WorldState,
        region: Region?,
        config: BalanceConfig = .current
    ) -> SeclusionOpportunity {
        guard cultivator.isAlive else {
            return SeclusionOpportunity(isAvailable: false, title: "身死道消", detail: "此身已绝，无法再入关修行。", quality: 0)
        }

        guard cultivator.realm != .mortal else {
            return SeclusionOpportunity(isAvailable: false, title: "尚未入道", detail: "凡俗之身难承闭关枯坐，应先踏入炼气。", quality: 0)
        }

        let placeAura = region?.aura ?? world.aura
        let placeDanger = region?.danger ?? 30
        let nameSeed = cultivator.name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        let regionSeed = region?.name.unicodeScalars.reduce(0) { $0 + Int($1.value) } ?? 17
        let pulse = deterministicPulse(world.year + cultivator.stage * 31 + nameSeed + regionSeed)

        let base = 0.08
            + Double(cultivator.luck) / 100 * 0.18
            + Double(cultivator.comprehension) / 100 * 0.14
            + cultivator.qiProgress * 0.2
            + world.fortune / 100 * 0.13
            + placeAura / 100 * 0.18
            - world.demonicThreat / 100 * 0.12
            - placeDanger / 100 * 0.1

        let quality = GameMath.clamp(base + pulse * 0.32, lower: 0, upper: 1)
        let isAvailable = quality >= config.seclusionOpportunityThreshold
        let placeText = region.map { "于\($0.name)" } ?? "择一清静地"
        let detail = isAvailable
            ? "\(placeText)心有所感，灵机牵引，适合顺势入关。闭关多久不可预定，出关与否须看道心。"
            : "\(placeText)灵机尚浅，强行闭关多半损伤道基，不宜枯坐。"

        return SeclusionOpportunity(
            isAvailable: isAvailable,
            title: isAvailable ? "福至心灵" : "机缘未至",
            detail: detail,
            quality: quality
        )
    }

    static func enterSeclusion(
        cultivator: Cultivator,
        world: WorldState,
        region: Region?,
        sects: [Sect],
        npcs: [NPC],
        regions: [Region],
        factions: [Faction],
        techniques: [Technique],
        karmaRecords: [KarmaRecord],
        legacies: [Legacy],
        reincarnationRecords: [ReincarnationRecord],
        worldSeeds: [WorldSeed],
        modelContext: ModelContext,
        requireOpportunity: Bool = true,
        config: BalanceConfig = .current
    ) -> GameEngineResult {
        let opportunity = evaluateOpportunity(cultivator: cultivator, world: world, region: region, config: config)
        guard !requireOpportunity || opportunity.isAvailable else {
            let event = GameEvent(
                year: world.year,
                title: "闭关未成",
                detail: "\(cultivator.name) 欲强求闭关，却觉心神浮动，终究没有封洞入定。\(opportunity.detail)"
            )
            return GameEngineResult(gameEvents: [event])
        }

        var result = GameEngineResult()
        let targetYears = seclusionYears(for: cultivator, world: world, region: region, opportunity: opportunity)
        var elapsedYears = 0

        for yearIndex in 0..<targetYears {
            result.historyEvents.append(
                contentsOf: WorldSystem.advanceYear(
                    world: world,
                    cultivator: cultivator,
                    sects: sects,
                    npcs: npcs,
                    regions: regions,
                    factions: factions,
                    techniques: techniques,
                    karmaRecords: karmaRecords,
                    legacies: legacies,
                    reincarnationRecords: reincarnationRecords,
                    worldSeeds: worldSeeds,
                    modelContext: modelContext
                )
            )

            elapsedYears += 1
            cultivator.age += 1

            if cultivator.age >= cultivator.lifespan {
                result.append(
                    deathResult(
                        cultivator: cultivator,
                        world: world,
                        karmaRecords: karmaRecords,
                        modelContext: modelContext,
                        title: "闭关坐化",
                        detail: "\(cultivator.name) 闭死关 \(elapsedYears) 年，终未叩开生死玄关，于洞府中寿尽坐化。"
                    )
                )
                break
            }

            let caveBonus = cultivator.hasCaveLease(in: world) ? config.caveAuraBonus : 0
            let placeAura = (region?.aura ?? world.aura) + caveBonus
            let placeDanger = region?.danger ?? 20
            let placeStability = GameMath.clamp((placeAura - placeDanger) / 120 + 1, lower: 0.65, upper: 1.35)
            let yearlyQi = GameEngine.qiGain(for: cultivator, in: world, region: region) * config.seclusionQiMultiplier * placeStability
            cultivator.qi = min(cultivator.qi + yearlyQi, cultivator.maxQi * 1.35)

            if cultivator.qi >= cultivator.maxQi {
                let breakthrough = GameEngine.tryBreakthrough(cultivator: cultivator, world: world)
                result.gameEvents.append(breakthrough.gameEvent)
                result.historyEvents.append(breakthrough.historyEvent)
                if !cultivator.isAlive {
                    result.historyEvents.append(LegacySystem.preservePlayerLegacy(player: cultivator, world: world, modelContext: modelContext))
                    result.shouldStopAction = true
                    break
                }
            }

            if shouldMeetHeartDemon(cultivator: cultivator, world: world, region: region, elapsedYears: elapsedYears, targetYears: targetYears, config: config) {
                if heartDemonKills(cultivator: cultivator, world: world, region: region, elapsedYears: elapsedYears, targetYears: targetYears) {
                    result.append(
                        deathResult(
                            cultivator: cultivator,
                            world: world,
                            karmaRecords: karmaRecords,
                            modelContext: modelContext,
                            title: "心魔入体",
                            detail: "\(cultivator.name) 闭关 \(elapsedYears) 年后心魔炽盛，道心崩裂，身死于静室。"
                        )
                    )
                } else {
                    let event = applyForcedExitPenalty(to: cultivator, world: world, elapsedYears: elapsedYears, reason: "心魔扰动")
                    result.gameEvents.append(event)
                    if event.importance >= 3 {
                        result.historyEvents.append(history(from: event))
                    }
                    result.shouldStopAction = true
                }
                break
            }

            if shouldBeForcedOut(cultivator: cultivator, world: world, region: region, config: config) {
                let event = applyForcedExitPenalty(to: cultivator, world: world, elapsedYears: elapsedYears, reason: "外劫惊关")
                result.gameEvents.append(event)
                if event.importance >= 3 {
                    result.historyEvents.append(history(from: event))
                }
                result.shouldStopAction = true
                break
            }

            if result.shouldStopAction || !cultivator.isAlive {
                break
            }

            _ = yearIndex
        }

        if !result.shouldStopAction {
            let event = GameEvent(
                year: world.year,
                title: "闭关出关",
                detail: "\(cultivator.name) 于\(region?.name ?? "洞府")入定 \(elapsedYears) 年，灵机自尽而醒，修为沉淀至 \(cultivator.realmText)。",
                importance: elapsedYears >= 100 ? 3 : 2
            )
            result.gameEvents.append(event)
            cultivator.changeDaoFoundation(by: min(3.0, Double(elapsedYears) / 40))
            if event.importance >= 3 {
                result.historyEvents.append(history(from: event))
            }
            result.shouldStopAction = true
        }

        return result
    }

    private static func seclusionYears(for cultivator: Cultivator, world: WorldState, region: Region?, opportunity: SeclusionOpportunity) -> Int {
        let baseRange: ClosedRange<Int>
        switch cultivator.realm {
        case .mortal:
            baseRange = 1...1
        case .qiRefining:
            baseRange = 1...12
        case .foundation:
            baseRange = 3...30
        case .goldenCore:
            baseRange = 8...80
        case .nascentSoul:
            baseRange = 20...180
        case .spiritSevering:
            baseRange = 60...420
        case .voidRefining:
            baseRange = 120...800
        case .integration:
            baseRange = 240...1_500
        case .mahayana:
            baseRange = 500...2_600
        case .tribulation:
            baseRange = 800...4_000
        case .trueImmortal, .mysteriousImmortal:
            baseRange = 1_000...6_000
        case .goldenImmortal, .taiyiGoldenImmortal:
            baseRange = 2_000...12_000
        case .greatLuoGoldenImmortal, .daoAncestor:
            baseRange = 5_000...30_000
        }

        let raw = Int.random(in: baseRange)
        let placeAura = region?.aura ?? world.aura
        let auraFactor = GameMath.clamp(0.75 + placeAura / 180 + opportunity.quality / 4, lower: 0.7, upper: 1.45)
        return max(1, Int(Double(raw) * auraFactor))
    }

    private static func shouldMeetHeartDemon(
        cultivator: Cultivator,
        world: WorldState,
        region: Region?,
        elapsedYears: Int,
        targetYears: Int,
        config: BalanceConfig
    ) -> Bool {
        let pressure = Double(elapsedYears) / Double(max(targetYears, 1))
        let danger = region?.danger ?? 20
        let demonic = world.demonicThreat
        let realmStability = min(cultivator.realm.multiplier / 120, 0.42)
        let risk = config.seclusionHeartDemonBaseRisk
            + pressure * 1.15
            + demonic / 230
            + danger / 260
            + world.calamityPressure / 320
            - Double(cultivator.comprehension) / 260
            - cultivator.daoFoundation / 260
            - realmStability
        return GameMath.chance(GameMath.clamp(risk, lower: 0.05, upper: 4.2))
    }

    private static func heartDemonKills(
        cultivator: Cultivator,
        world: WorldState,
        region: Region?,
        elapsedYears: Int,
        targetYears: Int
    ) -> Bool {
        let pressure = Double(elapsedYears) / Double(max(targetYears, 1))
        let danger = region?.danger ?? 20
        let risk = 18
            + pressure * 36
            + world.demonicThreat / 3
            + danger / 4
            - Double(cultivator.comprehension) / 4
            - Double(cultivator.luck) / 6
            - cultivator.daoFoundation / 4
        return GameMath.chance(GameMath.clamp(risk, lower: 5, upper: 78))
    }

    private static func shouldBeForcedOut(
        cultivator: Cultivator,
        world: WorldState,
        region: Region?,
        config: BalanceConfig
    ) -> Bool {
        let danger = region?.danger ?? 20
        let risk = config.seclusionForcedExitBaseRisk
            + danger / 240
            + world.demonicThreat / 360
            + world.calamityPressure / 420
            - Double(cultivator.luck) / 520
        let protectedRisk = cultivator.hasProtector(in: world) ? risk * (1 - config.protectorRiskReduction) : risk
        return GameMath.chance(GameMath.clamp(protectedRisk, lower: 0.03, upper: 2.6))
    }

    private static func applyForcedExitPenalty(to cultivator: Cultivator, world: WorldState, elapsedYears: Int, reason: String) -> GameEvent {
        let severeChance = BalanceConfig.current.forcedExitSeverePenaltyChance + world.demonicThreat / 5
        if GameMath.chance(severeChance) {
            cultivator.changeDaoFoundation(by: -BalanceConfig.current.daoFoundationForcedExitLoss * 1.5)
            cultivator.realm = max(.qiRefining, cultivator.realm.previous ?? .qiRefining)
            cultivator.stage = 1
            cultivator.qi = 0
            cultivator.lifespan = max(cultivator.age + 1, cultivator.lifespan - Int.random(in: 12...80))
            cultivator.title = "道基破碎"
            cultivator.refreshCultivationLimit()
            cultivator.qi = 0
            return GameEvent(
                year: world.year,
                title: "强行出关",
                detail: "\(cultivator.name) 闭关 \(elapsedYears) 年后因\(reason)强行出关，气机逆冲，道基破碎，境界跌落至 \(cultivator.realmText)。",
                importance: 3
            )
        }

        let oldStage = cultivator.stage
        cultivator.qi = max(0, cultivator.qi * Double.random(in: 0.12...0.55))
        cultivator.changeDaoFoundation(by: -BalanceConfig.current.daoFoundationForcedExitLoss)
        if cultivator.stage > 1, GameMath.chance(42) {
            cultivator.stage -= 1
            cultivator.refreshCultivationLimit()
        }
        cultivator.lifespan = max(cultivator.age + 1, cultivator.lifespan - Int.random(in: 2...18))
        return GameEvent(
            year: world.year,
            title: "仓促出关",
            detail: "\(cultivator.name) 闭关 \(elapsedYears) 年后因\(reason)不得不中断，修为大损\(oldStage == cultivator.stage ? "" : "，层次倒退")。",
            importance: 2
        )
    }

    private static func deathResult(
        cultivator: Cultivator,
        world: WorldState,
        karmaRecords: [KarmaRecord],
        modelContext: ModelContext,
        title: String,
        detail: String
    ) -> GameEngineResult {
        cultivator.isAlive = false
        cultivator.refreshHighestRealm()
        cultivator.deathSummary = "第 \(world.year) 年，\(cultivator.name) 享年 \(cultivator.age) 岁，最高境界 \(cultivator.highestRealmName)，因\(title)而终。主修 \(cultivator.equippedTechniqueText)，\(cultivator.cultivationStateText)。"
        let event = GameEvent(year: world.year, title: title, detail: detail, importance: 3)
        var result = GameEngineResult(gameEvents: [event], historyEvents: [history(from: event)], shouldStopAction: true)
        result.historyEvents.append(LegacySystem.preservePlayerLegacy(player: cultivator, world: world, modelContext: modelContext))
        result.shouldStopAction = true
        return result
    }

    private static func history(from event: GameEvent) -> HistoryEvent {
        HistoryEvent(year: event.year, title: event.title, detail: event.detail, category: .player, importance: event.importance)
    }

    private static func deterministicPulse(_ seed: Int) -> Double {
        let value = sin(Double(seed) * 12.9898) * 43_758.5453
        return value - floor(value)
    }
}
