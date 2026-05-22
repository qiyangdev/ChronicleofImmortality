import Foundation
import SwiftData

enum WorldSystem {
    static func repairCivilization(for cultivator: Cultivator, world: WorldState, in modelContext: ModelContext) {
        let seed = WorldSeed(
            seed: Int.random(in: 10_000...999_999),
            initialAura: world.aura,
            demonicRate: world.demonicThreat,
            fortuneBias: world.fortune,
            factionDistribution: "正道、魔道、中立、妖族、古族",
            resourceDensity: 52
        )
        seedWorld(for: cultivator, world: world, seed: seed, in: modelContext, repaired: true)
    }

    static func bootstrapWorld(for cultivator: Cultivator, in modelContext: ModelContext) -> WorldState {
        let seed = WorldSeed(
            seed: Int.random(in: 10_000...999_999),
            initialAura: Double.random(in: 34...78),
            demonicRate: Double.random(in: 12...72),
            fortuneBias: Double.random(in: 28...76),
            factionDistribution: ["正道偏盛", "魔道极强", "妖族横行", "诸宗并立", "古族复苏"].randomElement() ?? "诸宗并立",
            resourceDensity: Double.random(in: 32...82)
        )
        let world = WorldState(
            aura: seed.initialAura,
            fortune: seed.fortuneBias,
            demonicThreat: seed.demonicRate,
            civilizationLevel: GameMath.clamp(seed.resourceDensity * 0.6, lower: 18, upper: 60),
            goldenAgeProgress: seed.initialAura > 66 ? 42 : 12,
            calamityPressure: seed.demonicRate > 58 ? 36 : 8
        )
        modelContext.insert(world)
        modelContext.insert(seed)
        modelContext.insert(SaveMetadata(saveVersion: SaveVersionManager.currentVersion, worldAge: world.year, seed: seed.seed))
        seedWorld(for: cultivator, world: world, seed: seed, in: modelContext, repaired: false)
        return world
    }

    static func advanceYear(
        world: WorldState,
        cultivator: Cultivator,
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
    ) -> [HistoryEvent] {
        world.year += 1

        var events: [HistoryEvent] = []
        let previousEra = world.currentEra

        updateWorldClimate(world)
        applySeedInfluence(world: world, seed: worldSeeds.first)
        updateRegions(regions, world: world)

        events.append(contentsOf: majorWorldEvents(world))
        events.append(contentsOf: CivilizationSystem.advance(world: world, factions: factions, legacies: legacies))
        events.append(contentsOf: FactionSystem.advance(factions: factions, regions: regions, sects: sects, world: world, modelContext: modelContext))
        events.append(contentsOf: SectSystem.advance(sects: sects, world: world))
        events.append(contentsOf: NPCSystem.advance(npcs: npcs, sects: sects, world: world, player: cultivator, modelContext: modelContext))
        events.append(contentsOf: TechniqueEvolutionSystem.advance(techniques: techniques, npcs: npcs, factions: factions, legacies: legacies, world: world, modelContext: modelContext))
        events.append(contentsOf: LegacySystem.advance(legacies: legacies, world: world, modelContext: modelContext))
        events.append(contentsOf: KarmaSystem.advance(records: karmaRecords, npcs: npcs, player: cultivator, world: world))

        world.sectReputation = averageSectReputation(sects)
        world.currentEra = era(for: world)

        if previousEra != world.currentEra {
            events.append(
                HistoryEvent(
                    year: world.year,
                    title: "时代更易：\(world.currentEra)",
                    detail: "天地气数推移，修真界由 \(previousEra) 转入 \(world.currentEra)。",
                    category: .world,
                    importance: 3
                )
            )
        }

        return events
    }

    private static func seedWorld(for cultivator: Cultivator, world: WorldState, seed: WorldSeed, in modelContext: ModelContext, repaired: Bool) {
        let qingyun = Sect(name: "青云宗", reputation: 34, righteousness: 78, prosperity: 46, disciplesCount: 620, elderCount: 7, spiritStoneReserve: 4_800)
        let xuanYin = Sect(name: "玄阴教", reputation: 29, righteousness: 18, prosperity: 41, disciplesCount: 430, elderCount: 5, spiritStoneReserve: 5_300)
        let chiXia = Sect(name: "赤霞门", reputation: 22, righteousness: 56, prosperity: 38, disciplesCount: 310, elderCount: 4, spiritStoneReserve: 2_600)

        let techniques = [
            Technique(name: "青木养气诀", type: .cultivation, rarity: .common, cultivationBonus: 0.04, breakthroughBonus: 0.01, lifespanBonus: 2, sideEffect: "入门心法，胜在平稳。", creator: "青云外门", createdYear: 1, originFaction: "青云宗", inheritedCount: 120, isKnownToPlayer: true),
            Technique(name: "青云吐纳诀", type: .cultivation, rarity: .yellow, cultivationBonus: 0.09, breakthroughBonus: 0.025, lifespanBonus: 6, sideEffect: "灵气温和，适合作为主修。", creator: "玄微子", createdYear: 1, originFaction: "青云宗", inheritedCount: 40, isKnownToPlayer: true),
            Technique(name: "赤霞炼体篇", type: .body, rarity: .profound, cultivationBonus: 0.04, breakthroughBonus: 0.02, lifespanBonus: 20, sideEffect: "锤炼气血，历练更稳，但进境稍慢。", creator: "赤霞祖师", createdYear: 1, originFaction: "赤霞门", inheritedCount: 23),
            Technique(name: "清风步", type: .movement, rarity: .yellow, cultivationBonus: 0.01, breakthroughBonus: 0, lifespanBonus: 0, sideEffect: "身法轻捷，可避小险。", creator: "青云外门", createdYear: 1, originFaction: "青云宗", inheritedCount: 88, isKnownToPlayer: true, movementSpeedBonus: 10),
            Technique(name: "太虚神识录", type: .spirit, rarity: .earth, cultivationBonus: 0.07, breakthroughBonus: 0.08, lifespanBonus: 18, sideEffect: "破境时心魔稍轻。", creator: "太虚散人", createdYear: 1, originFaction: "散修会", inheritedCount: 8),
            Technique(name: "长河剑诀", type: .sword, rarity: .earth, cultivationBonus: 0.04, breakthroughBonus: 0.05, lifespanBonus: 8, sideEffect: "历练斗法更利。", creator: "长河剑主", createdYear: 1, originFaction: "正道盟", inheritedCount: 12),
            Technique(name: "缩地成寸", type: .movement, rarity: .heaven, cultivationBonus: 0.03, breakthroughBonus: 0.02, lifespanBonus: 8, sideEffect: "一念远遁，可穿越多数地域封锁。", creator: "无相真人", createdYear: 1, originFaction: "古族残庭", inheritedCount: 4, minimumLuckToDiscover: 96, movementSpeedBonus: 45, canBypassRegionSeal: true),
            Technique(name: "血河玄功", type: .demonic, rarity: .heaven, cultivationBonus: 0.18, breakthroughBonus: 0.08, lifespanBonus: -18, sideEffect: "修行极快，但易引魔劫。", creator: "血河老祖", createdYear: 1, originFaction: "血河魔宗", inheritedCount: 19)
        ]
        if cultivator.luck >= 88 {
            techniques
                .filter { $0.rarity >= .earth && $0.minimumLuckToDiscover <= cultivator.luck + 8 }
                .randomElement()?
                .isKnownToPlayer = true
        }

        let resourceScale = seed.resourceDensity / 52
        let regions = [
            Region(name: "青云山", aura: 56, danger: 12, resources: 34 * resourceScale, demonicInfluence: 8, unlockedRealm: .qiRefining),
            Region(name: "黑水泽", aura: 42, danger: 38, resources: 52 * resourceScale, demonicInfluence: 36, unlockedRealm: .qiRefining),
            Region(name: "赤霞谷", aura: 68, danger: 28, resources: 62 * resourceScale, demonicInfluence: 16, unlockedRealm: .foundation),
            Region(name: "古修遗迹", aura: 76, danger: 61, resources: 86 * resourceScale, demonicInfluence: 30, unlockedRealm: .goldenCore),
            Region(name: "北荒魔域", aura: 49, danger: 88, resources: 78 * resourceScale, demonicInfluence: 82, unlockedRealm: .nascentSoul)
        ]

        let npcs = [
            NPC(name: "玄微子", age: 11_860, realm: .tribulation, stage: 9, talent: 94, luck: 82, personality: .secluded, lifespan: 12_400, sect: qingyun, title: "渡劫天尊", cultivationProgress: 1_800),
            NPC(name: "李玄", age: 64, realm: .foundation, stage: 8, talent: 88, luck: 73, personality: .steady, sect: qingyun, title: "筑基真传", cultivationProgress: 720),
            NPC(name: "韩厉", age: 91, realm: .goldenCore, stage: 5, talent: 82, luck: 91, personality: .ambitious, sect: qingyun, title: "金丹真人", cultivationProgress: 460),
            NPC(name: "沈青霜", age: 344, realm: .nascentSoul, stage: 3, talent: 86, luck: 61, personality: .kind, sect: chiXia, title: "赤霞长老", cultivationProgress: 580),
            NPC(name: "血鸦道人", age: 506, realm: .spiritSevering, stage: 2, talent: 79, luck: 69, personality: .ruthless, sect: xuanYin, title: "化神魔修", cultivationProgress: 420),
            NPC(name: "陆采薇", age: 22, realm: .qiRefining, stage: 4, talent: 72, luck: 88, personality: .kind, sect: nil, title: "散修", cultivationProgress: 130)
        ]

        let factions = [
            Faction(name: "正道盟", alignment: .righteous, influence: 46, territory: "青云山", leader: qingyun.name, members: "\(qingyun.name)、\(chiXia.name)", enemies: "血河魔宗"),
            Faction(name: "血河魔宗", alignment: .demonic, influence: 38 + seed.demonicRate / 8, territory: "北荒魔域", leader: xuanYin.name, members: xuanYin.name, enemies: "正道盟"),
            Faction(name: "散修会", alignment: .neutral, influence: 22, territory: "黑水泽", leader: "无定散人", members: "散修"),
            Faction(name: "北荒妖庭", alignment: .yaozu, influence: seed.factionDistribution.contains("妖族") ? 45 : 27, territory: "北荒魔域", leader: "青鳞王", members: "妖族诸部"),
            Faction(name: "古族残庭", alignment: .ancient, influence: seed.factionDistribution.contains("古族") ? 36 : 18, territory: "古修遗迹", leader: "无名古族", members: "古族遗民")
        ]

        cultivator.sect = qingyun
        cultivator.sectRole = max(cultivator.sectRole, .outerDisciple)
        let knownTechniques = techniques.filter(\.isKnownToPlayer)
        cultivator.primaryTechnique = cultivator.primaryTechnique ?? knownTechniques.first { $0.type == .cultivation }
        cultivator.bodyTechnique = cultivator.bodyTechnique ?? knownTechniques.first { $0.type == .body }
        cultivator.spiritTechnique = cultivator.spiritTechnique ?? knownTechniques.first { $0.type == .spirit }
        cultivator.combatTechnique = cultivator.combatTechnique ?? knownTechniques.first { $0.type == .sword || $0.type == .demonic }
        cultivator.movementTechnique = cultivator.movementTechnique ?? knownTechniques.first { $0.type == .movement }
        cultivator.equippedTechnique = cultivator.activePrimaryTechnique
        cultivator.refreshCultivationLimit()

        for sect in [qingyun, xuanYin, chiXia] { modelContext.insert(sect) }
        for technique in techniques { modelContext.insert(technique) }
        for region in regions { modelContext.insert(region) }
        for npc in npcs { modelContext.insert(npc) }
        for faction in factions { modelContext.insert(faction) }

        modelContext.insert(KarmaRecord(source: cultivator.name, target: "李玄", reason: "同门护法", karmaValue: 32, year: world.year))
        modelContext.insert(Legacy(founder: "玄微子", faction: "青云宗", technique: "青云吐纳诀", createdYear: 1, influence: 28, descendants: 40))

        for technique in knownTechniques {
            TechniqueKnowledgeSystem.grant(
                technique: technique,
                to: cultivator,
                role: TechniqueKnowledgeSystem.defaultRole(for: technique),
                mastery: technique.rarity <= .yellow ? 22 : 8,
                year: world.year,
                source: technique.rarity <= .yellow ? "入门传承" : "天生气运",
                existing: [],
                modelContext: modelContext
            )
        }

        modelContext.insert(
            HistoryEvent(
                year: world.year,
                title: repaired ? "修真文明重整" : "诸宗并立",
                detail: repaired ? "势力、因果、道统与世界种子补入长生历。" : "\(seed.worldTendencyText) 的世界种子落定，青云宗、玄阴教、赤霞门与诸方势力各据一方。",
                category: .world,
                importance: 2
            )
        )
    }

    private static func updateWorldClimate(_ world: WorldState) {
        let shortCycle = sin(Double(world.year) / 48)
        let longCycle = sin(Double(world.year) / 680)
        let auraDrift = (shortCycle * 0.8 + longCycle * 0.55 + Double.random(in: -1.8...2.1)) * BalanceConfig.current.worldAuraChangeMultiplier
        world.aura = GameMath.clamp(world.aura + auraDrift, lower: 1, upper: 100)
        world.fortune = GameMath.clamp(world.fortune + Double.random(in: -1.7...1.9) * BalanceConfig.current.worldAuraChangeMultiplier, lower: 1, upper: 100)
        world.demonicThreat = GameMath.clamp(world.demonicThreat + Double.random(in: -1.2...1.9) * BalanceConfig.current.worldAuraChangeMultiplier, lower: 0, upper: 100)
    }

    private static func applySeedInfluence(world: WorldState, seed: WorldSeed?) {
        guard let seed else { return }
        world.demonicThreat = GameMath.clamp(world.demonicThreat + (seed.demonicRate - 50) / 900, lower: 0, upper: 100)
        world.fortune = GameMath.clamp(world.fortune + (seed.fortuneBias - 50) / 1100, lower: 1, upper: 100)
        world.aura = GameMath.clamp(world.aura + (seed.initialAura - 50) / 1400, lower: 1, upper: 100)
    }

    private static func updateRegions(_ regions: [Region], world: WorldState) {
        for region in regions {
            if region.stateUntilYear > 0 && world.year > region.stateUntilYear {
                region.state = .calm
                region.stateUntilYear = 0
            }

            if region.state == .calm, GameMath.chance(BalanceConfig.current.regionStateChance) {
                region.state = nextRegionState(for: region, world: world)
                region.stateUntilYear = world.year + Int.random(in: BalanceConfig.current.regionStateDurationRange)
            }

            region.aura = GameMath.clamp(region.aura + (world.aura - 50) / 120 + Double.random(in: -1.4...1.6), lower: 1, upper: 100)
            region.resources = GameMath.clamp(region.resources + (region.aura / 180 - region.danger / 260 + Double.random(in: -1...1.2)) * BalanceConfig.current.explorationRewardMultiplier, lower: 0, upper: 100)
            region.demonicInfluence = GameMath.clamp(region.demonicInfluence + (world.demonicThreat - 45) / 130 + Double.random(in: -1.1...1.4), lower: 0, upper: 100)
            region.danger = GameMath.clamp(region.danger + region.demonicInfluence / 260 + Double.random(in: -0.8...1.0), lower: 0, upper: 100)

            switch region.state {
            case .auraResurgence:
                region.aura = GameMath.clamp(region.aura + 1.6, lower: 1, upper: 100)
                region.resources = GameMath.clamp(region.resources + 1.2, lower: 0, upper: 100)
            case .relicOpen:
                region.resources = GameMath.clamp(region.resources + 1.8, lower: 0, upper: 100)
            case .beastTide:
                region.danger = GameMath.clamp(region.danger + 1.8, lower: 0, upper: 100)
            case .demonicDisaster:
                region.danger = GameMath.clamp(region.danger + 1.2, lower: 0, upper: 100)
                region.demonicInfluence = GameMath.clamp(region.demonicInfluence + 2.0, lower: 0, upper: 100)
            case .sectBlockade:
                region.danger = GameMath.clamp(region.danger + 0.6, lower: 0, upper: 100)
            case .calm:
                break
            }
        }
    }

    private static func nextRegionState(for region: Region, world: WorldState) -> RegionState {
        if world.demonicThreat > 68 || region.demonicInfluence > 70 { return .demonicDisaster }
        if region.danger > 70 { return .beastTide }
        if region.resources > 72 && GameMath.chance(45) { return .relicOpen }
        if world.aura > 66 && GameMath.chance(45) { return .auraResurgence }
        if GameMath.chance(30) { return .sectBlockade }
        return .relicOpen
    }

    private static func majorWorldEvents(_ world: WorldState) -> [HistoryEvent] {
        var events: [HistoryEvent] = []

        if world.year.isMultiple(of: 120), world.aura < 30 {
            world.fortune = GameMath.clamp(world.fortune - 6, lower: 1, upper: 100)
            events.append(HistoryEvent(year: world.year, title: "灵脉枯竭", detail: "多地灵泉断流，低阶修士进境艰难，宗门库藏亦受牵连。", category: .calamity, importance: 3))
        }

        if world.year.isMultiple(of: 160), world.aura > 72 {
            world.fortune = GameMath.clamp(world.fortune + 8, lower: 1, upper: 100)
            events.append(HistoryEvent(year: world.year, title: "天地灵气复苏", detail: "群山灵机翻涌，闭关者多有所悟，天下似有黄金大世之兆。", category: .world, importance: 3))
        }

        if world.demonicThreat > 78, GameMath.chance(3.8) {
            world.fortune = GameMath.clamp(world.fortune - 5, lower: 1, upper: 100)
            events.append(HistoryEvent(year: world.year, title: "魔道扩张", detail: "北荒魔焰南侵，多处坊市闭门，正道宗门被迫结盟自保。", category: .calamity, importance: 3))
        }

        if world.year.isMultiple(of: 900), world.aura > 68 && world.fortune > 58 {
            world.ascensionCount += 1
            events.append(HistoryEvent(year: world.year, title: "飞升潮初现", detail: "数位隐世大能相继叩问仙门，天下皆言飞升潮将至。", category: .ascension, importance: 3))
        }

        if world.year.isMultiple(of: 2_100), world.aura < 34 {
            events.append(HistoryEvent(year: world.year, title: "灵气枯竭纪", detail: "第 \(world.year) 年，天地灵气跌入谷底，旧有修真秩序开始崩塌。", category: .calamity, importance: 3))
        }

        return events
    }

    private static func averageSectReputation(_ sects: [Sect]) -> Double {
        guard !sects.isEmpty else { return 0 }
        let total = sects.reduce(0) { $0 + $1.reputation }
        return total / Double(sects.count)
    }

    private static func era(for world: WorldState) -> String {
        if world.demonicThreat > 76 { return "黑暗动乱" }
        if world.calamityPressure > 72 { return "天地大劫" }
        if world.aura < 28 { return "末法时代" }
        if world.aura > 78 && world.fortune > 66 || world.goldenAgeProgress > 78 { return "黄金大世" }
        if world.sectReputation > 62 { return "万宗争霸" }
        if world.aura > 62 { return "灵气复苏" }
        return "开山纪"
    }
}
