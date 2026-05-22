import SwiftData
import Testing
@testable import Chronicle_of_Immortality

@MainActor
struct GameSimulationTests {
    @Test func realmBreakthroughDoesNotCorruptCultivator() async throws {
        let fixture = try makeFixture()
        let player = fixture.player
        player.qi = player.maxQi * 1.4

        _ = GameEngine.tryBreakthrough(cultivator: player, world: fixture.world)

        #expect(player.stage >= 1)
        #expect(player.qi >= 0)
        #expect(player.maxQi > 0)
        #expect(player.lifespan >= player.age)
    }

    @Test func cultivationRequirementScalesNonlinearly() async throws {
        let early = Cultivator.requiredQi(for: .qiRefining, stage: 1)
        let late = Cultivator.requiredQi(for: .qiRefining, stage: 9)
        let nextRealm = Cultivator.requiredQi(for: .foundation, stage: 1)

        #expect(late > early * 12)
        #expect(nextRealm > early)
    }

    @Test func breakthroughChanceFallsAtHigherStagesAndRealms() async throws {
        let fixture = try makeFixture()
        fixture.world.aura = 60
        fixture.world.fortune = 60
        fixture.world.demonicThreat = 20

        let early = Cultivator(name: "初阶修士", stage: 1, talent: 70, luck: 70, physique: 70, comprehension: 70)
        let late = Cultivator(name: "后期修士", stage: 8, talent: 70, luck: 70, physique: 70, comprehension: 70)
        let highRealm = Cultivator(name: "高阶修士", realm: .nascentSoul, stage: 8, age: 180, talent: 70, luck: 70, physique: 70, comprehension: 70)

        early.qi = early.maxQi * 1.1
        late.qi = late.maxQi * 1.1
        highRealm.qi = highRealm.maxQi * 1.1

        let earlyChance = GameEngine.breakthroughChance(for: early, world: fixture.world)
        let lateChance = GameEngine.breakthroughChance(for: late, world: fixture.world)
        let highRealmChance = GameEngine.breakthroughChance(for: highRealm, world: fixture.world)

        #expect(lateChance < earlyChance)
        #expect(highRealmChance < lateChance)
    }

    @Test func npcLifecycleAdvancesWithoutInvalidValues() async throws {
        let fixture = try makeFixture()
        let events = NPCSystem.advance(npcs: fixture.npcs, sects: fixture.sects, world: fixture.world, player: fixture.player, modelContext: fixture.context)

        #expect(events.count >= 0)
        #expect(fixture.npcs.allSatisfy { $0.age > 0 && $0.lifespan > 0 })
    }

    @Test func npcDiesWhenLifespanIsExhausted() async throws {
        let fixture = try makeFixture()
        let npc = NPC(
            name: "暮年散修",
            age: 129,
            realm: .qiRefining,
            stage: 3,
            talent: 42,
            luck: 36,
            personality: .steady,
            lifespan: 130
        )

        let events = NPCSystem.advance(npcs: [npc], sects: fixture.sects, world: fixture.world, player: fixture.player, modelContext: fixture.context)

        #expect(!npc.isAlive)
        #expect(events.contains { $0.title.contains("坐化") })
    }

    @Test func oldAgeReducesCultivationGain() async throws {
        let fixture = try makeFixture()
        let young = Cultivator(name: "少岁修士", age: 20, talent: 60, luck: 50, physique: 60, comprehension: 60)
        let old = Cultivator(name: "暮年修士", age: 124, talent: 60, luck: 50, physique: 60, comprehension: 60)

        let youngGain = GameEngine.qiGain(for: young, in: fixture.world)
        let oldGain = GameEngine.qiGain(for: old, in: fixture.world)

        #expect(oldGain < youngGain)
    }

    @Test func daoFoundationAffectsCultivationAndBreakthrough() async throws {
        let fixture = try makeFixture()
        fixture.world.aura = 60
        fixture.world.fortune = 60
        fixture.world.demonicThreat = 20

        let stable = Cultivator(name: "道基稳者", stage: 5, talent: 70, luck: 70, physique: 70, comprehension: 70, daoFoundation: 92)
        let unstable = Cultivator(name: "道基裂者", stage: 5, talent: 70, luck: 70, physique: 70, comprehension: 70, daoFoundation: 18)
        stable.qi = stable.maxQi * 1.1
        unstable.qi = unstable.maxQi * 1.1

        #expect(GameEngine.qiGain(for: stable, in: fixture.world) > GameEngine.qiGain(for: unstable, in: fixture.world))
        #expect(GameEngine.breakthroughChance(for: stable, world: fixture.world) > GameEngine.breakthroughChance(for: unstable, world: fixture.world))
    }

    @Test func worldEvolutionStaysWithinBounds() async throws {
        let fixture = try makeFixture()
        _ = WorldSystem.advanceYear(
            world: fixture.world,
            cultivator: fixture.player,
            sects: fixture.sects,
            npcs: fixture.npcs,
            regions: fixture.regions,
            factions: fixture.factions,
            techniques: fixture.techniques,
            karmaRecords: fixture.karmaRecords,
            legacies: fixture.legacies,
            reincarnationRecords: fixture.reincarnations,
            worldSeeds: fixture.worldSeeds,
            modelContext: fixture.context
        )

        #expect((1...100).contains(fixture.world.aura))
        #expect((1...100).contains(fixture.world.fortune))
        #expect((0...100).contains(fixture.world.demonicThreat))
    }

    @Test func factionWarKeepsInfluenceBounded() async throws {
        let fixture = try makeFixture()
        _ = FactionSystem.advance(factions: fixture.factions, regions: fixture.regions, sects: fixture.sects, world: fixture.world, modelContext: fixture.context)

        #expect(fixture.factions.allSatisfy { (0...100).contains($0.influence) })
    }

    @Test func reincarnationRestoresPlayableCharacter() async throws {
        let fixture = try makeFixture()
        fixture.player.realm = .nascentSoul
        fixture.player.stage = 3
        fixture.player.isAlive = false
        let result = ReincarnationSystem.reincarnate(player: fixture.player, world: fixture.world, karmaRecords: fixture.karmaRecords, modelContext: fixture.context)

        #expect(fixture.player.isAlive)
        #expect(fixture.player.realm == .qiRefining)
        #expect(!result.historyEvents.isEmpty)
    }

    @Test func lowRealmCannotReincarnate() async throws {
        let fixture = try makeFixture()
        fixture.player.realm = .goldenCore
        fixture.player.stage = 9
        fixture.player.isAlive = false

        let result = ReincarnationSystem.reincarnate(player: fixture.player, world: fixture.world, karmaRecords: fixture.karmaRecords, modelContext: fixture.context)

        #expect(!fixture.player.isAlive)
        #expect(result.gameEvents.contains { $0.title == "轮回无门" })
    }

    @Test func techniqueEvolutionCanCreateLineageSafely() async throws {
        let fixture = try makeFixture()
        let events = TechniqueEvolutionSystem.advance(
            techniques: fixture.techniques,
            npcs: fixture.npcs,
            factions: fixture.factions,
            legacies: fixture.legacies,
            world: fixture.world,
            modelContext: fixture.context
        )

        #expect(events.count >= 0)
        #expect(fixture.techniques.allSatisfy { $0.cultivationBonus >= 0 })
    }

    @Test func highRarityTechniquesAreNotInitiallyCommon() async throws {
        let lowLuckFixture = try makeFixture(playerLuck: 50)
        let lowLuckKnownHigh = lowLuckFixture.techniques.filter { $0.isKnownToPlayer && $0.rarity >= .earth }

        let highLuckFixture = try makeFixture(playerLuck: 90)
        let highLuckKnownHigh = highLuckFixture.techniques.filter { $0.isKnownToPlayer && $0.rarity >= .earth }

        #expect(lowLuckKnownHigh.isEmpty)
        #expect(!highLuckKnownHigh.isEmpty)
    }

    @Test func multipleTechniqueRolesStackWithDifferentWeights() async throws {
        let primary = Technique(name: "主修法", type: .cultivation, rarity: .yellow, cultivationBonus: 0.1, breakthroughBonus: 0.04, lifespanBonus: 8, sideEffect: "稳", isKnownToPlayer: true)
        let body = Technique(name: "炼体法", type: .body, rarity: .profound, cultivationBonus: 0.06, breakthroughBonus: 0.02, lifespanBonus: 20, sideEffect: "厚", isKnownToPlayer: true)
        let movement = Technique(name: "遁法", type: .movement, rarity: .earth, cultivationBonus: 0.02, breakthroughBonus: 0.01, lifespanBonus: 4, sideEffect: "快", isKnownToPlayer: true, movementSpeedBonus: 35)
        let cultivator = Cultivator(name: "兼修者", equippedTechnique: primary, primaryTechnique: primary, bodyTechnique: body, movementTechnique: movement)

        #expect(cultivator.practicedTechniques.count == 3)
        #expect(cultivator.cultivationBonus > primary.cultivationBonus)
        #expect(cultivator.explorationBonus > 0.1)
        #expect(cultivator.movementSpeedBonus == 35)
    }

    @Test func movementTechniqueCanBypassRegionSeal() async throws {
        let fixture = try makeFixture(playerLuck: 50)
        let lockedRegion = try #require(fixture.regions.first { $0.unlockedRealm > fixture.player.realm })
        let movement = Technique(
            name: "缩地试法",
            type: .movement,
            rarity: .heaven,
            cultivationBonus: 0.02,
            breakthroughBonus: 0.01,
            lifespanBonus: 6,
            sideEffect: "险",
            isKnownToPlayer: true,
            movementSpeedBonus: 50,
            canBypassRegionSeal: true
        )
        fixture.context.insert(movement)
        fixture.player.movementTechnique = movement

        let result = ExplorationSystem.explore(
            cultivator: fixture.player,
            world: fixture.world,
            region: lockedRegion,
            sects: fixture.sects,
            npcs: fixture.npcs,
            regions: fixture.regions,
            factions: fixture.factions,
            techniques: fixture.techniques + [movement],
            techniqueKnowledges: fixture.techniqueKnowledges,
            karmaRecords: fixture.karmaRecords,
            legacies: fixture.legacies,
            reincarnationRecords: fixture.reincarnations,
            worldSeeds: fixture.worldSeeds,
            years: 1,
            modelContext: fixture.context
        )

        #expect(!result.gameEvents.contains { $0.title == "境界不足" })
    }

    @Test func newCultivatorDoesNotInheritAllHighTierTechniques() async throws {
        let fixture = try makeFixture(playerLuck: 90)
        let descendant = Cultivator(name: "后世修士", luck: 50)
        fixture.context.insert(descendant)

        TechniqueKnowledgeSystem.ensureStartingKnowledge(
            for: descendant,
            world: fixture.world,
            techniques: fixture.techniques,
            knowledges: [],
            legacies: fixture.legacies,
            modelContext: fixture.context
        )

        let records = try fixture.context.fetch(FetchDescriptor<TechniqueKnowledge>())
            .filter { $0.cultivatorName == descendant.name }
        let highNames = Set(fixture.techniques.filter { $0.rarity >= .earth }.map(\.name))

        #expect(records.allSatisfy { !highNames.contains($0.techniqueName) })
    }

    @Test func resourceActionsSpendStonesAndProtectSeclusion() async throws {
        let fixture = try makeFixture()
        fixture.player.spiritStone = 500
        let before = fixture.player.spiritStone

        _ = ResourceSystem.rentCave(cultivator: fixture.player, world: fixture.world, region: fixture.regions.first)
        _ = ResourceSystem.hireProtector(cultivator: fixture.player, world: fixture.world)

        #expect(fixture.player.spiritStone == before - BalanceConfig.current.caveLeaseCost - BalanceConfig.current.protectorCost)
        #expect(fixture.player.hasCaveLease(in: fixture.world))
        #expect(fixture.player.hasProtector(in: fixture.world))
    }

    @Test func regionStateExpiresAndChangesExplorationContext() async throws {
        let fixture = try makeFixture()
        let region = try #require(fixture.regions.first)
        region.state = .relicOpen
        region.stateUntilYear = fixture.world.year

        _ = WorldSystem.advanceYear(
            world: fixture.world,
            cultivator: fixture.player,
            sects: fixture.sects,
            npcs: fixture.npcs,
            regions: fixture.regions,
            factions: fixture.factions,
            techniques: fixture.techniques,
            karmaRecords: fixture.karmaRecords,
            legacies: fixture.legacies,
            reincarnationRecords: fixture.reincarnations,
            worldSeeds: fixture.worldSeeds,
            modelContext: fixture.context
        )

        #expect(region.state == .calm || region.stateUntilYear >= fixture.world.year)
    }

    @Test func playerDeathCreatesBiographySummary() async throws {
        let fixture = try makeFixture()
        fixture.player.age = fixture.player.lifespan - 1

        _ = await SimulationEngine.cultivate(
            cultivator: fixture.player,
            world: fixture.world,
            sects: fixture.sects,
            npcs: fixture.npcs,
            regions: fixture.regions,
            factions: fixture.factions,
            techniques: fixture.techniques,
            techniqueKnowledges: fixture.techniqueKnowledges,
            karmaRecords: fixture.karmaRecords,
            legacies: fixture.legacies,
            reincarnationRecords: fixture.reincarnations,
            worldSeeds: fixture.worldSeeds,
            recentHistory: [],
            years: 1,
            modelContext: fixture.context
        )

        #expect(!fixture.player.isAlive)
        #expect(!fixture.player.deathSummary.isEmpty)
        #expect(fixture.player.deathSummary.contains("最高境界"))
    }

    @Test func seclusionRequiresInsightAndDoesNotPresetThousandYears() async throws {
        let fixture = try makeFixture()
        let region = try #require(fixture.regions.first)
        fixture.player.qi = fixture.player.maxQi * 0.95
        fixture.player.luck = 100
        fixture.player.comprehension = 100
        fixture.world.aura = 100
        fixture.world.fortune = 100
        fixture.world.demonicThreat = 0
        region.aura = 100
        region.danger = 0

        let opportunity = SeclusionSystem.evaluateOpportunity(cultivator: fixture.player, world: fixture.world, region: region)
        #expect(opportunity.isAvailable)

        let result = await SimulationEngine.seclude(
            cultivator: fixture.player,
            world: fixture.world,
            region: region,
            sects: fixture.sects,
            npcs: fixture.npcs,
            regions: fixture.regions,
            factions: fixture.factions,
            techniques: fixture.techniques,
            karmaRecords: fixture.karmaRecords,
            legacies: fixture.legacies,
            reincarnationRecords: fixture.reincarnations,
            worldSeeds: fixture.worldSeeds,
            recentHistory: [],
            modelContext: fixture.context
        )

        #expect(result.shouldStopAction)
        #expect((2...25).contains(fixture.world.year))
    }

    @Test func thousandYearSimulationIsStable() async throws {
        let fixture = try makeFixture()
        let result = await SimulationEngine.cultivate(
            cultivator: fixture.player,
            world: fixture.world,
            sects: fixture.sects,
            npcs: fixture.npcs,
            regions: fixture.regions,
            factions: fixture.factions,
            techniques: fixture.techniques,
            techniqueKnowledges: fixture.techniqueKnowledges,
            karmaRecords: fixture.karmaRecords,
            legacies: fixture.legacies,
            reincarnationRecords: fixture.reincarnations,
            worldSeeds: fixture.worldSeeds,
            recentHistory: [],
            years: 1_000,
            modelContext: fixture.context
        )

        #expect((2...1_001).contains(fixture.world.year))
        #expect(result.historyEvents.count <= BalanceConfig.current.maxHistoryEventsPerBatch)
        #expect((0...100).contains(fixture.world.civilizationLevel))
    }

    @Test func tenThousandYearWorldDoesNotRunAway() async throws {
        let fixture = try makeFixture()

        for _ in 0..<10_000 {
            _ = WorldSystem.advanceYear(
                world: fixture.world,
                cultivator: fixture.player,
                sects: fixture.sects,
                npcs: fixture.npcs,
                regions: fixture.regions,
                factions: fixture.factions,
                techniques: fixture.techniques,
                karmaRecords: fixture.karmaRecords,
                legacies: fixture.legacies,
                reincarnationRecords: fixture.reincarnations,
                worldSeeds: fixture.worldSeeds,
                modelContext: fixture.context
            )
        }

        #expect(fixture.world.year == 10_001)
        #expect((1...100).contains(fixture.world.aura))
        #expect((0...100).contains(fixture.world.calamityPressure))
        #expect(fixture.factions.allSatisfy { (0...100).contains($0.influence) })
    }

    @Test func worldSeedProducesValidStartingWorld() async throws {
        let fixture = try makeFixture()
        let seed = try #require(fixture.worldSeeds.first)

        #expect(seed.seed > 0)
        #expect(fixture.world.aura == seed.initialAura)
        #expect(!seed.worldTendencyText.isEmpty)
    }

    private func makeFixture(playerLuck: Int? = nil) throws -> SimulationFixture {
        let schema = Schema([
            Cultivator.self,
            WorldState.self,
            GameEvent.self,
            HistoryEvent.self,
            NPC.self,
            Sect.self,
            Region.self,
            Technique.self,
            TechniqueKnowledge.self,
            KarmaRecord.self,
            Faction.self,
            Legacy.self,
            ReincarnationRecord.self,
            WorldSeed.self,
            SaveMetadata.self
        ])
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let player = Cultivator(name: "测试修士", luck: playerLuck ?? Int.random(in: 35...90))
        context.insert(player)
        let world = WorldSystem.bootstrapWorld(for: player, in: context)

        return SimulationFixture(
            context: context,
            player: player,
            world: world,
            sects: try context.fetch(FetchDescriptor<Sect>()),
            npcs: try context.fetch(FetchDescriptor<NPC>()),
            regions: try context.fetch(FetchDescriptor<Region>()),
            factions: try context.fetch(FetchDescriptor<Faction>()),
            techniques: try context.fetch(FetchDescriptor<Technique>()),
            techniqueKnowledges: try context.fetch(FetchDescriptor<TechniqueKnowledge>()),
            karmaRecords: try context.fetch(FetchDescriptor<KarmaRecord>()),
            legacies: try context.fetch(FetchDescriptor<Legacy>()),
            reincarnations: try context.fetch(FetchDescriptor<ReincarnationRecord>()),
            worldSeeds: try context.fetch(FetchDescriptor<WorldSeed>())
        )
    }
}

@MainActor
private struct SimulationFixture {
    let context: ModelContext
    let player: Cultivator
    let world: WorldState
    let sects: [Sect]
    let npcs: [NPC]
    let regions: [Region]
    let factions: [Faction]
    let techniques: [Technique]
    let techniqueKnowledges: [TechniqueKnowledge]
    let karmaRecords: [KarmaRecord]
    let legacies: [Legacy]
    let reincarnations: [ReincarnationRecord]
    let worldSeeds: [WorldSeed]
}
