import Foundation
import SwiftData

enum GameEngine {
    static func cultivate(
        cultivator: Cultivator,
        world: WorldState,
        sects: [Sect],
        npcs: [NPC],
        regions: [Region],
        factions: [Faction],
        techniques: [Technique],
        techniqueKnowledges: [TechniqueKnowledge],
        karmaRecords: [KarmaRecord],
        legacies: [Legacy],
        reincarnationRecords: [ReincarnationRecord],
        worldSeeds: [WorldSeed],
        years: Int,
        modelContext: ModelContext
    ) -> GameEngineResult {
        let config = BalanceConfig.current
        guard cultivator.isAlive else {
            let event = GameEvent(
                year: world.year,
                title: "长生路绝",
                detail: "\(cultivator.name) 已身死道消，只余旧事载入山门残卷。",
                importance: 2
            )
            return GameEngineResult(gameEvents: [event], shouldStopAction: true)
        }

        var result = GameEngineResult()
        let cultivationYears = max(years, 1)

        for _ in 0..<cultivationYears {
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

            if let deathEvent = advanceAge(for: cultivator, in: world) {
                result.gameEvents.append(deathEvent)
                result.historyEvents.append(history(from: deathEvent))
                result.historyEvents.append(LegacySystem.preservePlayerLegacy(player: cultivator, world: world, modelContext: modelContext))
                result.shouldStopAction = true
                break
            }

            let yearlyQi = qiGain(for: cultivator, in: world)
            cultivator.qi = min(cultivator.qi + yearlyQi, cultivator.maxQi * 1.25)
            cultivator.changeDaoFoundation(by: BalanceConfig.current.daoFoundationRecoveryPerQuietYear)
            if cultivator.practicedTechniques.contains(where: { $0.type == .demonic }),
               GameMath.chance(BalanceConfig.current.demonicTechniqueDaoLossChance + world.demonicThreat / 45) {
                cultivator.changeDaoFoundation(by: -Double.random(in: 1.0...3.8))
                world.demonicThreat = GameMath.clamp(world.demonicThreat + Double.random(in: 0.4...1.6), lower: 0, upper: 100)
            }
            cultivateSectInfluence(cultivator, world: world)

            if GameMath.chance(42 * config.spiritStoneYieldMultiplier) {
                let stones = max(1, Int((Double.random(in: 1...5) * cultivator.realm.multiplier * config.spiritStoneYieldMultiplier).rounded()))
                cultivator.spiritStone += stones
            }

            if let event = randomEvent(cultivator: cultivator, world: world, techniques: techniques, techniqueKnowledges: techniqueKnowledges, modelContext: modelContext) {
                result.gameEvents.append(event)
                if event.importance >= 2 {
                    result.historyEvents.append(history(from: event))
                }
                if event.importance >= 3, let npc = npcs.filter({ $0.isAlive }).randomElement(), GameMath.chance(18) {
                    result.historyEvents.append(
                        KarmaSystem.record(
                            source: cultivator.name,
                            target: npc.name,
                            reason: "共同经历\(event.title)",
                            value: Int.random(in: 18...48),
                            year: world.year,
                            in: modelContext
                        )
                    )
                }
            }

            if cultivator.qi >= cultivator.maxQi {
                let breakthrough = tryBreakthrough(cultivator: cultivator, world: world)
                result.gameEvents.append(breakthrough.gameEvent)
                result.historyEvents.append(breakthrough.historyEvent)
                if !cultivator.isAlive {
                    result.historyEvents.append(LegacySystem.preservePlayerLegacy(player: cultivator, world: world, modelContext: modelContext))
                    result.shouldStopAction = true
                    break
                }
            }

            if !cultivator.isAlive {
                break
            }
        }

        if result.gameEvents.isEmpty {
            result.gameEvents.append(
                GameEvent(
                    year: world.year,
                    title: "闭关修炼",
                    detail: "\(cultivator.name) 静坐洞府 \(cultivationYears) 年，吐纳天地灵机，世界已在门外悄然改易。"
                )
            )
        }

        return result
    }

    static func tryBreakthrough(cultivator: Cultivator, world: WorldState) -> (gameEvent: GameEvent, historyEvent: HistoryEvent) {
        guard cultivator.isAlive else {
            let event = GameEvent(year: world.year, title: "道途已止", detail: "肉身既灭，境界再无可进。", importance: 2)
            return (event, history(from: event))
        }

        guard !cultivator.hasReachedPeak else {
            cultivator.qi = cultivator.maxQi
            cultivator.title = "道祖"
            let event = GameEvent(
                year: world.year,
                title: "道尽于此",
                detail: "\(cultivator.name) 已立于万道之巅，天地再无更高境界。",
                importance: 3
            )
            return (event, history(from: event, category: .ascension))
        }

        let isMajorBreakthrough = cultivator.stage >= 9
        let successChance = breakthroughChance(for: cultivator, world: world)

        if Double.random(in: 0...1) <= successChance {
            let previousRealmText = cultivator.realmText
            let oldRole = cultivator.sectRole
            let previousMaxQi = cultivator.maxQi
            advanceRealm(for: cultivator)
            cultivator.refreshHighestRealm()
            let newRole = cultivator.updateSectRole()

            cultivator.qi = max(0, cultivator.qi - previousMaxQi * (isMajorBreakthrough ? 1.05 : 0.82))
            cultivator.title = title(for: cultivator)
            cultivator.sect?.reputation = GameMath.clamp((cultivator.sect?.reputation ?? 0) + Double.random(in: 2...8), lower: 0, upper: 100)
            world.fortune = GameMath.clamp(world.fortune + Double.random(in: 0.5...3.0), lower: 0, upper: 100)

            let roleText = newRole > oldRole ? "，宗门身份升为\(newRole.name)" : ""
            let event = GameEvent(
                year: world.year,
                title: "闭关突破",
                detail: "\(cultivator.name) 自 \(previousRealmText) 破境而上，踏入 \(cultivator.realmText)\(roleText)。",
                importance: cultivator.stage == 1 ? 3 : 2
            )
            return (event, history(from: event))
        }

        let vitalityPressure = oldAgePressure(age: cultivator.age, lifespan: cultivator.lifespan)
        let setbackRange: ClosedRange<Double> = isMajorBreakthrough ? 0.58...0.92 : 0.36...0.72
        let setback = Double.random(in: setbackRange) + vitalityPressure * 0.18
        cultivator.qi = max(cultivator.qi * (1 - setback), 0)
        cultivator.changeDaoFoundation(by: -(BalanceConfig.current.daoFoundationFailureLoss + (isMajorBreakthrough ? 3 : 0)))

        let injuryChance = (isMajorBreakthrough ? 42 : 28) + vitalityPressure * 45
        if GameMath.chance(injuryChance) {
            let injuryRange = isMajorBreakthrough ? 6.0...28.0 : 2.0...12.0
            let injuryYears = Int(Double.random(in: injuryRange) + vitalityPressure * Double.random(in: 8...42))
            cultivator.lifespan = max(cultivator.age + 1, cultivator.lifespan - injuryYears)

            if isLifespanCritical(cultivator), GameMath.chance(BalanceConfig.current.desperateBreakthroughDeathChance + vitalityPressure * 36) {
                cultivator.isAlive = false
                recordDeath(cultivator, cause: "寿尽冲关", year: world.year)
                let event = GameEvent(
                    year: world.year,
                    title: "寿尽冲关",
                    detail: "\(cultivator.name) 寿元将尽仍强行叩关，气血枯竭，未能越过生死玄关。",
                    importance: 3
                )
                return (event, history(from: event))
            }

            let event = GameEvent(
                year: world.year,
                title: "破境受挫",
                detail: "\(cultivator.name) 冲关时真气逆行，折损寿元 \(injuryYears) 年，只得闭目调息以稳道基。",
                importance: 2
            )
            return (event, history(from: event))
        }

        let event = GameEvent(
            year: world.year,
            title: "破境未成",
            detail: "\(cultivator.name) 叩问瓶颈未果，灵气散入经脉，所幸根基尚稳。"
        )
        return (event, history(from: event))
    }

    static func randomEvent(
        cultivator: Cultivator,
        world: WorldState,
        forced: Bool = false,
        techniques: [Technique] = [],
        techniqueKnowledges: [TechniqueKnowledge] = [],
        modelContext: ModelContext? = nil
    ) -> GameEvent? {
        guard forced || GameMath.chance(BalanceConfig.current.randomCultivationEventChance) else { return nil }

        let type = Int.random(in: 1...7)
        switch type {
        case 1:
            let qi = Double.random(in: 4...12) * cultivator.realm.multiplier * BalanceConfig.current.randomQiEventMultiplier
            cultivator.qi = min(cultivator.qi + qi, cultivator.maxQi * 1.25)
            cultivator.luck = min(cultivator.luck + Int.random(in: 0...1), 100)
            return GameEvent(
                year: world.year,
                title: "山中奇遇",
                detail: "\(cultivator.name) 于古松下得一缕先天清气，灵台澄澈，修为暗涨。"
            )
        case 2:
            let stones = Int(Double.random(in: 18...90) * BalanceConfig.current.spiritStoneYieldMultiplier)
            cultivator.spiritStone += stones
            return GameEvent(
                year: world.year,
                title: "秘境开启",
                detail: "荒岭现出短暂秘境，\(cultivator.name) 采得灵草与灵石，共计 \(stones) 枚。",
                importance: 2
            )
        case 3:
            let stones = Int(Double.random(in: 8...42) * BalanceConfig.current.spiritStoneYieldMultiplier)
            cultivator.spiritStone += stones
            return GameEvent(
                year: world.year,
                title: "灵石入囊",
                detail: "\(cultivator.name) 在坊市替人护法，得灵石 \(stones) 枚。"
            )
        case 4:
            let wound = Int.random(in: 1...6)
            let qiLoss = cultivator.maxQi * Double.random(in: 0.05...0.18)
            cultivator.lifespan = max(cultivator.age + 1, cultivator.lifespan - wound)
            cultivator.qi = max(cultivator.qi - qiLoss, 0)
            cultivator.changeDaoFoundation(by: -Double.random(in: 0.6...2.2))
            world.demonicThreat = GameMath.clamp(world.demonicThreat + Double.random(in: 1...5), lower: 0, upper: 100)
            return GameEvent(
                year: world.year,
                title: "妖兽袭山",
                detail: "\(cultivator.name) 斩退山魈，却也伤及根本，折寿 \(wound) 年。",
                importance: 2
            )
        case 5:
            let gain = Int.random(in: 1...3)
            cultivator.comprehension = min(cultivator.comprehension + gain, 100)
            cultivator.qi = min(cultivator.qi + cultivator.maxQi * 0.06, cultivator.maxQi * 1.25)
            return GameEvent(
                year: world.year,
                title: "一朝顿悟",
                detail: "\(cultivator.name) 观雨落檐前，忽明一线天机，悟性提升 \(gain) 点。",
                importance: 2
            )
        case 6:
            let pressure = Int.random(in: 2...10)
            world.fortune = GameMath.clamp(world.fortune - Double(pressure), lower: 1, upper: 100)
            world.aura = GameMath.clamp(world.aura + Double.random(in: 2...7), lower: 1, upper: 100)
            return GameEvent(
                year: world.year,
                title: "天劫异象",
                detail: "远天雷云垂落，疑有大能渡劫。天地气运震荡，灵气却一时翻涌。",
                importance: 3
            )
        default:
            if let technique = discoverMinorTechnique(cultivator: cultivator, world: world, techniques: techniques),
               let modelContext {
                TechniqueKnowledgeSystem.grant(
                    technique: technique,
                    to: cultivator,
                    role: .collection,
                    mastery: 8,
                    year: world.year,
                    source: "山谷残卷",
                    existing: techniqueKnowledges,
                    modelContext: modelContext
                )
                return GameEvent(
                    year: world.year,
                    title: "残卷入手",
                    detail: "\(cultivator.name) 在山谷中发现残缺玉简，辨得《\(technique.name)》一脉传承。",
                    importance: technique.rarity >= .earth ? 3 : 2
                )
            }

            let gain = Int.random(in: 1...2)
            cultivator.talent = min(cultivator.talent + gain, 100)
            cultivator.spiritStone += Int(Double.random(in: 10...55) * BalanceConfig.current.spiritStoneYieldMultiplier)
            return GameEvent(
                year: world.year,
                title: "古修遗迹",
                detail: "\(cultivator.name) 在山谷中发现残缺玉简，资质受古法洗练，天赋提升 \(gain) 点。",
                importance: 3
            )
        }
    }

    static func breakthroughChance(for cultivator: Cultivator, world: WorldState, config: BalanceConfig = .current) -> Double {
        let comprehension = Double(cultivator.comprehension) / 100
        let luck = Double(cultivator.luck) / 100
        let fortune = world.fortune / 100
        let aura = world.aura / 100
        let isMajorBreakthrough = cultivator.stage >= 9
        let stageProgress = Double(max(cultivator.stage - 1, 0)) / 8
        let stageDifficulty = pow(stageProgress, 1.45) * config.stageBreakthroughPenaltyMax
        let highRealmStageDifficulty = stageProgress * min(pow(cultivator.realm.multiplier, 0.45) / 10, config.highRealmStagePenaltyMultiplier)
        let overflowRatio = max(cultivator.qi / max(cultivator.maxQi, 1) - 1, 0)
        let overflowBonus = min(overflowRatio / 0.35, 1) * config.breakthroughOverflowBonusMax
        let threatPenalty = world.demonicThreat / 360
        let agePenalty = oldAgeBreakthroughPenalty(for: cultivator)
        let realmDifficulty = min(pow(cultivator.realm.multiplier, 0.76) / 31, 0.52)
        let bottleneckPenalty = isMajorBreakthrough ? config.majorRealmBreakthroughPenalty : 0
        let baseChance = (isMajorBreakthrough ? config.majorBreakthroughBaseChance : config.minorBreakthroughBaseChance)
            + comprehension * 0.16
            + luck * 0.1
            + fortune * 0.1
            + aura * 0.06
            + cultivator.breakthroughBonus * 0.75
            + daoFoundationBreakthroughBonus(for: cultivator, config: config)
            + overflowBonus
        return GameMath.clamp(
            (baseChance - realmDifficulty - stageDifficulty - highRealmStageDifficulty - threatPenalty - agePenalty - bottleneckPenalty) * config.breakthroughChanceMultiplier,
            lower: isMajorBreakthrough ? 0.008 : 0.015,
            upper: isMajorBreakthrough ? 0.36 : 0.58
        )
    }

    private static func discoverMinorTechnique(cultivator: Cultivator, world: WorldState, techniques: [Technique]) -> Technique? {
        let candidates = techniques.filter {
            !$0.isKnownToPlayer
                && $0.rarity <= .profound
                && cultivator.luck >= $0.minimumLuckToDiscover
        }
        guard let technique = candidates.randomElement() else { return nil }

        let chance = (Double(cultivator.luck) * 0.06 + world.fortune * 0.035) * BalanceConfig.current.techniqueDiscoveryMultiplier
        guard GameMath.chance(chance) else { return nil }

        technique.isKnownToPlayer = true
        return technique
    }

    private static func advanceAge(for cultivator: Cultivator, in world: WorldState) -> GameEvent? {
        cultivator.age += 1
        if cultivator.age >= cultivator.lifespan {
            cultivator.isAlive = false
            recordDeath(cultivator, cause: "寿元耗尽", year: world.year)
            return GameEvent(
                year: world.year,
                title: "寿元耗尽",
                detail: "\(cultivator.name) 未能再破生死玄关，于 \(cultivator.age) 岁坐化洞府。",
                importance: 3
            )
        }
        return nil
    }

    private static func advanceRealm(for cultivator: Cultivator) {
        if cultivator.stage < 9 {
            cultivator.stage += 1
        } else if let nextRealm = cultivator.realm.next {
            cultivator.realm = nextRealm
            cultivator.stage = 1
        }
        cultivator.refreshCultivationLimit()
    }

    static func qiGain(for cultivator: Cultivator, in world: WorldState, region: Region? = nil) -> Double {
        let talentFactor = Double(cultivator.talent) / 70
        let comprehensionFactor = Double(cultivator.comprehension) / 95
        let placeAura = region.map { (world.aura * 0.55 + $0.aura * 0.45) } ?? world.aura
        let auraFactor = max(placeAura, 1) / 65
        let physiqueFactor = Double(cultivator.physique) / 120
        let realmFactor = max(0.45, 1.55 - cultivator.realm.multiplier / 140)
        let techniqueFactor = 1 + cultivator.cultivationBonus * BalanceConfig.current.techniqueEffectMultiplier
        let daoFactor = daoFoundationQiFactor(for: cultivator)
        return (4 + talentFactor * 5 + comprehensionFactor * 3 + physiqueFactor * 2) * auraFactor * realmFactor * techniqueFactor * vitalityFactor(for: cultivator) * BalanceConfig.current.cultivationMultiplier
            * daoFactor
    }

    private static func cultivateSectInfluence(_ cultivator: Cultivator, world: WorldState) {
        guard let sect = cultivator.sect else { return }

        let contribution = max(1, Int(cultivator.realm.multiplier.rounded()))
        sect.spiritStoneReserve += contribution
        sect.prosperity = GameMath.clamp(sect.prosperity + cultivator.realm.multiplier / 800, lower: 0, upper: 100)
        world.sectReputation = GameMath.clamp(world.sectReputation + cultivator.realm.multiplier / 1200, lower: 0, upper: 100)
    }

    private static func title(for cultivator: Cultivator) -> String {
        switch cultivator.realm {
        case .mortal: "凡俗"
        case .qiRefining: "入道散修"
        case .foundation: "筑基修士"
        case .goldenCore: "金丹真人"
        case .nascentSoul: "元婴老祖"
        case .spiritSevering: "化神尊者"
        case .voidRefining: "炼虚大修"
        case .integration: "合体真君"
        case .mahayana: "大乘圣君"
        case .tribulation: "渡劫天尊"
        case .trueImmortal: "真仙"
        case .mysteriousImmortal: "玄仙上人"
        case .goldenImmortal: "金仙"
        case .taiyiGoldenImmortal: "太乙金仙"
        case .greatLuoGoldenImmortal: "大罗金仙"
        case .daoAncestor: "道祖"
        }
    }

    private static func history(from event: GameEvent, category: HistoryCategory = .player) -> HistoryEvent {
        HistoryEvent(
            year: event.year,
            title: event.title,
            detail: event.detail,
            category: category,
            importance: event.importance
        )
    }

    private static func vitalityFactor(for cultivator: Cultivator) -> Double {
        let pressure = oldAgePressure(age: cultivator.age, lifespan: cultivator.lifespan)
        let penalty = pressure * BalanceConfig.current.playerOldAgeQiPenaltyMax
        return GameMath.clamp(1 - penalty, lower: 0.28, upper: 1)
    }

    private static func daoFoundationQiFactor(for cultivator: Cultivator) -> Double {
        let normalized = (cultivator.daoFoundation - 60) / 40
        return GameMath.clamp(1 + normalized * BalanceConfig.current.daoFoundationQiMultiplierMax, lower: 0.62, upper: 1.28)
    }

    private static func daoFoundationBreakthroughBonus(for cultivator: Cultivator, config: BalanceConfig) -> Double {
        let normalized = (cultivator.daoFoundation - 60) / 40
        return GameMath.clamp(normalized * config.daoFoundationBreakthroughMultiplierMax, lower: -0.24, upper: 0.18)
    }

    private static func oldAgeBreakthroughPenalty(for cultivator: Cultivator) -> Double {
        oldAgePressure(age: cultivator.age, lifespan: cultivator.lifespan) * BalanceConfig.current.playerOldAgeBreakthroughPenaltyMax
    }

    private static func oldAgePressure(age: Int, lifespan: Int) -> Double {
        guard lifespan > 0 else { return 1 }
        let ratio = Double(age) / Double(lifespan)
        let start = BalanceConfig.current.oldAgeDeclineStartRatio
        guard ratio > start else { return 0 }
        return GameMath.clamp((ratio - start) / max(0.01, 1 - start), lower: 0, upper: 1)
    }

    private static func isLifespanCritical(_ cultivator: Cultivator) -> Bool {
        guard cultivator.lifespan > 0 else { return true }
        let remainingRatio = Double(cultivator.remainingLifespan) / Double(cultivator.lifespan)
        return remainingRatio <= BalanceConfig.current.lifespanWarningRatio
    }

    private static func recordDeath(_ cultivator: Cultivator, cause: String, year: Int) {
        cultivator.refreshHighestRealm()
        cultivator.deathSummary = "第 \(year) 年，\(cultivator.name) 享年 \(cultivator.age) 岁，最高境界 \(cultivator.highestRealmName)，因\(cause)而终。主修 \(cultivator.equippedTechniqueText)，\(cultivator.cultivationStateText)。"
    }
}
