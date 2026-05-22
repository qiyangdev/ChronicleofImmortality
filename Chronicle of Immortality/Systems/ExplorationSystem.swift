import Foundation
import SwiftData

enum ExplorationSystem {
    static func explore(
        cultivator: Cultivator,
        world: WorldState,
        region: Region,
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
        guard cultivator.isAlive else {
            return GameEngineResult(
                gameEvents: [
                    GameEvent(year: world.year, title: "尘缘已断", detail: "\(cultivator.name) 已无法再入红尘历练。", importance: 2)
                ],
                shouldStopAction: true
            )
        }

        guard !region.isBlocked(for: cultivator), cultivator.realm >= region.unlockedRealm || cultivator.canBypassRegionSeal else {
            return GameEngineResult(
                gameEvents: [
                    GameEvent(
                        year: world.year,
                        title: "境界不足",
                        detail: "\(region.name) 至少需 \(region.unlockedRealm.name) 境方可前往，贸然入内只会白白送命。",
                        importance: 2
                    )
                ]
            )
        }

        var result = GameEngineResult()
        let duration = max(1, years)

        for _ in 0..<duration {
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

            if let deathEvent = advancePlayerAge(cultivator, world: world) {
                result.gameEvents.append(deathEvent)
                result.historyEvents.append(playerHistory(from: deathEvent))
                result.historyEvents.append(LegacySystem.preservePlayerLegacy(player: cultivator, world: world, modelContext: modelContext))
                result.shouldStopAction = true
                break
            }

            result.append(resolveExplorationYear(cultivator: cultivator, world: world, region: region, techniques: techniques, techniqueKnowledges: techniqueKnowledges, modelContext: modelContext))

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

            if !cultivator.isAlive {
                break
            }
        }

        return result
    }

    private static func resolveExplorationYear(cultivator: Cultivator, world: WorldState, region: Region, techniques: [Technique], techniqueKnowledges: [TechniqueKnowledge], modelContext: ModelContext) -> GameEngineResult {
        let stateRisk = region.state.isDangerous ? 16.0 : -4.0
        let dangerPressure = region.danger * 0.45 + region.demonicInfluence * 0.35 + stateRisk
        let realmShield = cultivator.realm.multiplier * 2.6 + Double(cultivator.physique) * 0.2
        let movementShield = cultivator.movementSpeedBonus * BalanceConfig.current.movementTechniqueRiskReduction
        let bypassPenalty = cultivator.realm < region.unlockedRealm && cultivator.canBypassRegionSeal ? BalanceConfig.current.regionSealBypassRiskPenalty : 0
        let luckShield = Double(cultivator.luck) * 0.18 + cultivator.explorationBonus * 100 + movementShield
        let risk = GameMath.clamp(dangerPressure + bypassPenalty - realmShield - luckShield, lower: 2, upper: 86)

        let roll = Int.random(in: 1...6)
        switch roll {
        case 1:
            return beastEncounter(cultivator: cultivator, world: world, region: region, risk: risk)
        case 2:
            return spiritHerb(cultivator: cultivator, world: world, region: region)
        case 3:
            return ancientRelic(cultivator: cultivator, world: world, region: region, risk: risk, techniques: techniques, techniqueKnowledges: techniqueKnowledges, modelContext: modelContext)
        case 4:
            return demonicCultivator(cultivator: cultivator, world: world, region: region, risk: risk)
        case 5:
            return suddenInsight(cultivator: cultivator, world: world, region: region)
        default:
            return heavenlyFortune(cultivator: cultivator, world: world, region: region, risk: risk, techniques: techniques, techniqueKnowledges: techniqueKnowledges, modelContext: modelContext)
        }
    }

    private static func beastEncounter(cultivator: Cultivator, world: WorldState, region: Region, risk: Double) -> GameEngineResult {
        if GameMath.chance(risk) {
            let wound = Int.random(in: 2...18)
            cultivator.lifespan = max(cultivator.age + 1, cultivator.lifespan - wound)
            cultivator.qi = max(0, cultivator.qi - cultivator.maxQi * Double.random(in: 0.08...0.24))
            cultivator.changeDaoFoundation(by: -Double.random(in: 0.8...3.4))

            if GameMath.chance(risk / 7), cultivator.remainingLifespan <= 1 {
                cultivator.isAlive = false
                recordDeath(cultivator, cause: "历练重伤", year: world.year)
            }

            let event = GameEvent(
                year: world.year,
                title: "遇到妖兽",
                detail: "\(cultivator.name) 在 \(region.name) 遭妖兽伏击，折寿 \(wound) 年，险死还生。",
                importance: 2
            )
            return GameEngineResult(gameEvents: [event], historyEvents: [playerHistory(from: event)])
        }

        let stateMultiplier = region.state == .beastTide ? 1.35 : 1.0
        let stones = Int((Double.random(in: 18...70) * region.resources / 50 * BalanceConfig.current.explorationRewardMultiplier * stateMultiplier).rounded())
        cultivator.spiritStone += stones
        cultivator.qi = min(cultivator.qi + cultivator.maxQi * 0.035, cultivator.maxQi * 1.25)

        let event = GameEvent(
            year: world.year,
            title: "斩妖获宝",
            detail: "\(cultivator.name) 于 \(region.name) 斩退妖兽，得灵石 \(stones) 枚，胆气更盛。"
        )
        return GameEngineResult(gameEvents: [event])
    }

    private static func spiritHerb(cultivator: Cultivator, world: WorldState, region: Region) -> GameEngineResult {
        let stateMultiplier = region.state == .auraResurgence ? 1.35 : 1.0
        let stones = Int((Double.random(in: 24...110) * region.resources / 55 * BalanceConfig.current.explorationRewardMultiplier * stateMultiplier).rounded())
        cultivator.spiritStone += stones
        cultivator.qi = min(cultivator.qi + cultivator.maxQi * 0.055, cultivator.maxQi * 1.25)

        let event = GameEvent(
            year: world.year,
            title: "发现灵草",
            detail: "\(cultivator.name) 在 \(region.name) 采得灵草，折换灵石 \(stones) 枚，药力亦化入经脉。"
        )
        return GameEngineResult(gameEvents: [event])
    }

    private static func ancientRelic(cultivator: Cultivator, world: WorldState, region: Region, risk: Double, techniques: [Technique], techniqueKnowledges: [TechniqueKnowledge], modelContext: ModelContext) -> GameEngineResult {
        if GameMath.chance(risk * 0.55) {
            let loss = Int.random(in: 1...10)
            cultivator.lifespan = max(cultivator.age + 1, cultivator.lifespan - loss)
            cultivator.changeDaoFoundation(by: -Double.random(in: 1...4))
            let event = GameEvent(
                year: world.year,
                title: "发现遗迹",
                detail: "\(cultivator.name) 误触 \(region.name) 古阵禁制，虽脱困而出，却折损寿元 \(loss) 年。",
                importance: 2
            )
            return GameEngineResult(gameEvents: [event], historyEvents: [playerHistory(from: event)])
        }

        let qi = cultivator.maxQi * Double.random(in: 0.1...0.22)
        let gain = Int.random(in: 1...4)
        cultivator.qi = min(cultivator.qi + qi, cultivator.maxQi * 1.3)
        cultivator.comprehension = min(100, cultivator.comprehension + gain)

        if let technique = discoverTechnique(cultivator: cultivator, world: world, region: region, techniques: techniques, fortuneWeight: region.state == .relicOpen ? 1.5 : 0.85) {
            TechniqueKnowledgeSystem.grant(technique: technique, to: cultivator, role: .collection, mastery: 10, year: world.year, source: "\(region.name)遗迹", existing: techniqueKnowledges, modelContext: modelContext)
            let event = GameEvent(
                year: world.year,
                title: "古修传承",
                detail: "\(cultivator.name) 参悟 \(region.name) 残碑，得《\(technique.name)》残篇，从此可修 \(technique.summaryText)。",
                importance: technique.rarity >= .earth ? 3 : 2
            )
            return GameEngineResult(gameEvents: [event], historyEvents: technique.rarity >= .earth ? [playerHistory(from: event)] : [])
        }

        let event = GameEvent(
            year: world.year,
            title: "古修遗迹",
            detail: "\(cultivator.name) 参悟 \(region.name) 残碑，悟性提升 \(gain) 点，修为大进。",
            importance: 2
        )
        return GameEngineResult(gameEvents: [event], historyEvents: [playerHistory(from: event)])
    }

    private static func demonicCultivator(cultivator: Cultivator, world: WorldState, region: Region, risk: Double) -> GameEngineResult {
        world.demonicThreat = GameMath.clamp(world.demonicThreat + Double.random(in: 0.6...2.4), lower: 0, upper: 100)

        if GameMath.chance(risk + region.demonicInfluence / 4) {
            let wound = Int.random(in: 3...22)
            cultivator.lifespan = max(cultivator.age + 1, cultivator.lifespan - wound)
            cultivator.qi = max(0, cultivator.qi - cultivator.maxQi * Double.random(in: 0.12...0.34))
            cultivator.changeDaoFoundation(by: -Double.random(in: 1.2...4.8))
            let event = GameEvent(
                year: world.year,
                title: "遭遇魔修",
                detail: "\(cultivator.name) 于 \(region.name) 遭魔修截杀，折寿 \(wound) 年，天下魔焰更炽。",
                importance: 2
            )
            return GameEngineResult(gameEvents: [event], historyEvents: [playerHistory(from: event)])
        }

        let stones = Int(Double.random(in: 42...180) * BalanceConfig.current.explorationRewardMultiplier)
        cultivator.spiritStone += stones
        let event = GameEvent(
            year: world.year,
            title: "退敌夺宝",
            detail: "\(cultivator.name) 击退魔修，夺得灵石 \(stones) 枚，声名传入附近坊市。",
            importance: 2
        )
        return GameEngineResult(gameEvents: [event], historyEvents: [playerHistory(from: event)])
    }

    private static func suddenInsight(cultivator: Cultivator, world: WorldState, region: Region) -> GameEngineResult {
        let gain = Int.random(in: 1...5)
        cultivator.comprehension = min(100, cultivator.comprehension + gain)
        cultivator.qi = min(cultivator.qi + cultivator.maxQi * Double.random(in: 0.07...0.16), cultivator.maxQi * 1.25)

        let event = GameEvent(
            year: world.year,
            title: "顿悟",
            detail: "\(cultivator.name) 行至 \(region.name)，观天地气象而顿悟，悟性提升 \(gain) 点。",
            importance: 2
        )
        return GameEngineResult(gameEvents: [event], historyEvents: [playerHistory(from: event)])
    }

    private static func heavenlyFortune(cultivator: Cultivator, world: WorldState, region: Region, risk: Double, techniques: [Technique], techniqueKnowledges: [TechniqueKnowledge], modelContext: ModelContext) -> GameEngineResult {
        let stateBonus = region.state == .auraResurgence || region.state == .relicOpen ? 12.0 : 0
        let fortuneChance = Double(cultivator.luck) * 0.42 + region.resources * 0.28 - risk * 0.15 + stateBonus
        guard GameMath.chance(fortuneChance) else {
            let event = GameEvent(
                year: world.year,
                title: "空山独行",
                detail: "\(cultivator.name) 在 \(region.name) 行走一年，未得重宝，却也磨砺了心境。"
            )
            return GameEngineResult(gameEvents: [event])
        }

        let stones = Int(Double.random(in: 120...520) * BalanceConfig.current.explorationRewardMultiplier)
        cultivator.spiritStone += stones
        cultivator.qi = min(cultivator.qi + cultivator.maxQi * 0.18, cultivator.maxQi * 1.3)
        world.fortune = GameMath.clamp(world.fortune + Double.random(in: 1...4), lower: 1, upper: 100)

        if let technique = discoverTechnique(cultivator: cultivator, world: world, region: region, techniques: techniques, fortuneWeight: 1.35) {
            TechniqueKnowledgeSystem.grant(technique: technique, to: cultivator, role: .collection, mastery: 14, year: world.year, source: "\(region.name)机缘", existing: techniqueKnowledges, modelContext: modelContext)
            let event = GameEvent(
                year: world.year,
                title: "天授法门",
                detail: "\(cultivator.name) 于 \(region.name) 得天降机缘，灵石 \(stones) 枚入囊，并悟得《\(technique.name)》。",
                importance: technique.rarity >= .earth ? 3 : 2
            )
            return GameEngineResult(gameEvents: [event], historyEvents: technique.rarity >= .earth ? [playerHistory(from: event)] : [])
        }

        let event = GameEvent(
            year: world.year,
            title: "天降机缘",
            detail: "\(cultivator.name) 于 \(region.name) 得一桩天降机缘，灵石 \(stones) 枚入囊，道心大振。",
            importance: 3
        )
        return GameEngineResult(gameEvents: [event], historyEvents: [playerHistory(from: event)])
    }

    private static func discoverTechnique(
        cultivator: Cultivator,
        world: WorldState,
        region: Region,
        techniques: [Technique],
        fortuneWeight: Double
    ) -> Technique? {
        let candidates = techniques.filter { technique in
            !technique.isKnownToPlayer
                && cultivator.luck + Int(region.resources / 8) >= technique.minimumLuckToDiscover
                && (technique.rarity <= .profound || region.unlockedRealm >= .foundation || cultivator.luck >= 88)
        }
        guard !candidates.isEmpty else { return nil }

        let baseChance = (Double(cultivator.luck) * 0.08 + region.resources * 0.05 + world.fortune * 0.04) * BalanceConfig.current.techniqueDiscoveryMultiplier * fortuneWeight
        let highRarityPenalty = candidates.contains { $0.rarity >= .earth } ? BalanceConfig.current.highRarityTechniqueDiscoveryPenalty : 1
        guard GameMath.chance(baseChance * highRarityPenalty) else { return nil }

        let sorted = candidates.sorted {
            if $0.rarity == $1.rarity { return $0.minimumLuckToDiscover < $1.minimumLuckToDiscover }
            return $0.rarity < $1.rarity
        }
        let technique = weightedTechnique(from: sorted, luck: cultivator.luck)
        technique.isKnownToPlayer = true
        return technique
    }

    private static func weightedTechnique(from techniques: [Technique], luck: Int) -> Technique {
        let reachable = techniques.filter { $0.minimumLuckToDiscover <= luck + 12 }
        let pool = reachable.isEmpty ? techniques : reachable
        let lowRarity = pool.filter { $0.rarity <= .profound }
        if !lowRarity.isEmpty, luck < 92 {
            return lowRarity.randomElement() ?? pool[0]
        }
        return pool.randomElement() ?? techniques[0]
    }

    private static func advancePlayerAge(_ cultivator: Cultivator, world: WorldState) -> GameEvent? {
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

    private static func playerHistory(from event: GameEvent) -> HistoryEvent {
        HistoryEvent(year: event.year, title: event.title, detail: event.detail, category: .player, importance: event.importance)
    }

    private static func recordDeath(_ cultivator: Cultivator, cause: String, year: Int) {
        cultivator.refreshHighestRealm()
        cultivator.deathSummary = "第 \(year) 年，\(cultivator.name) 享年 \(cultivator.age) 岁，最高境界 \(cultivator.highestRealmName)，因\(cause)而终。主修 \(cultivator.equippedTechniqueText)，\(cultivator.cultivationStateText)。"
    }
}
