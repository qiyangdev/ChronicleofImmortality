import SwiftData
import SwiftUI

struct ActionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Sect.name) private var sects: [Sect]
    @Query(sort: \NPC.name) private var npcs: [NPC]
    @Query(sort: \Region.name) private var regions: [Region]
    @Query(sort: \Faction.name) private var factions: [Faction]
    @Query(sort: \Technique.name) private var techniques: [Technique]
    @Query(sort: \TechniqueKnowledge.acquiredYear, order: .reverse) private var techniqueKnowledges: [TechniqueKnowledge]
    @Query(sort: \KarmaRecord.year, order: .reverse) private var karmaRecords: [KarmaRecord]
    @Query(sort: \Legacy.createdYear, order: .reverse) private var legacies: [Legacy]
    @Query(sort: \ReincarnationRecord.year, order: .reverse) private var reincarnationRecords: [ReincarnationRecord]
    @Query(sort: \WorldSeed.seed) private var worldSeeds: [WorldSeed]
    @Query(sort: \HistoryEvent.year, order: .reverse) private var recentHistoryEvents: [HistoryEvent]

    @Bindable var cultivator: Cultivator
    @Bindable var world: WorldState

    @State private var selectedRegionName = "青云山"
    @State private var explorationYears = 1
    @State private var isSimulating = false

    var body: some View {
        List {
            Section("日常修行") {
                Button {
                    performCultivation(years: 1)
                } label: {
                    Label("吐纳一年", systemImage: "leaf")
                }

                Button {
                    performCultivation(years: 10)
                } label: {
                    Label("潜修十年", systemImage: "calendar")
                }
            }

            Section("闭关机缘") {
                Picker("闭关地", selection: $selectedRegionName) {
                    ForEach(regions) { region in
                        Text(region.name).tag(region.name)
                    }
                }

                if let region = selectedRegion {
                    LabeledContent("灵气", value: region.aura.percentText)
                    LabeledContent("危险", value: region.danger.percentText)
                }

                LabeledContent("灵机", value: seclusionOpportunity.qualityText)
                Text(seclusionOpportunity.detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Button {
                    performSeclusion()
                } label: {
                    Label("顺势入关", systemImage: "moon.zzz")
                }
                .disabled(!seclusionOpportunity.isAvailable || selectedRegion == nil)
            }

            Section("外出历练") {
                Picker("区域", selection: $selectedRegionName) {
                    ForEach(regions) { region in
                        Text(region.name).tag(region.name)
                    }
                }

                Picker("时长", selection: $explorationYears) {
                    Text("一年").tag(1)
                    Text("三年").tag(3)
                    Text("十年").tag(10)
                }

                if let region = selectedRegion {
                    LabeledContent("灵气", value: region.aura.percentText)
                    LabeledContent("危险", value: region.danger.percentText)
                    LabeledContent("资源", value: region.resources.percentText)
                    LabeledContent("通行", value: accessText(for: region))
                }

                Button {
                    performExploration()
                } label: {
                    Label("外出历练", systemImage: "figure.hiking")
                }
                .disabled(selectedRegion == nil)
            }

            Section("推演") {
                Button {
                    performTechniqueInference()
                } label: {
                    Label("灵机推演", systemImage: "book.closed")
                }
                .disabled(isSimulating)
            }

            Section("资源筹谋") {
                Button {
                    performResourceAction(.rentCave)
                } label: {
                    Label("租用洞府", systemImage: "mountain.2")
                }

                Button {
                    performResourceAction(.hireProtector)
                } label: {
                    Label("请人护法", systemImage: "shield")
                }

                Button {
                    performResourceAction(.buyFragment)
                } label: {
                    Label("购买低阶残卷", systemImage: "doc.text")
                }

                Button {
                    performResourceAction(.donateSect)
                } label: {
                    Label("宗门供奉", systemImage: "building.columns")
                }
            }

            Section("宗门事务") {
                Button {
                    performSectDuty()
                } label: {
                    Label("处理三年宗务", systemImage: "building.columns")
                }
            }

            Section("当下") {
                LabeledContent("年份", value: "\(world.year) 年")
                LabeledContent("时代", value: world.currentEra)
                LabeledContent("模拟状态", value: isSimulating ? "推演中" : "静候法旨")
                LabeledContent("宗门", value: cultivator.sectName)
                LabeledContent("境界", value: cultivator.realmText)
                LabeledContent("灵气", value: "\(cultivator.qi.wholeNumberText) / \(cultivator.maxQi.wholeNumberText)")
                LabeledContent("修为进度", value: (cultivator.qiProgress * 100).percentText)
                LabeledContent("道基", value: "\(cultivator.daoFoundation.percentText) · \(cultivator.cultivationStateText)")
            }
        }
        .disabled(!cultivator.isAlive || isSimulating)
        .overlay {
            if !cultivator.isAlive {
                ContentUnavailableView("长生路已尽", systemImage: "scroll", description: Text("这部修真史已停在 \(world.year) 年。"))
            }
        }
        .onAppear {
            if selectedRegion == nil, let firstRegion = regions.first {
                selectedRegionName = firstRegion.name
            }
        }
    }

    private var selectedRegion: Region? {
        regions.first { $0.name == selectedRegionName } ?? regions.first
    }

    private var seclusionOpportunity: SeclusionOpportunity {
        SeclusionSystem.evaluateOpportunity(cultivator: cultivator, world: world, region: selectedRegion)
    }

    private func accessText(for region: Region) -> String {
        if cultivator.realm >= region.unlockedRealm {
            return "可前往"
        }
        if cultivator.canBypassRegionSeal {
            return "可凭遁法强行穿越"
        }
        return region.unlockText
    }

    private func performCultivation(years: Int) {
        guard !isSimulating else { return }
        isSimulating = true
        Task { @MainActor in
            let result = await SimulationEngine.cultivate(
                cultivator: cultivator,
                world: world,
                sects: sects,
                npcs: npcs,
                regions: regions,
                factions: factions,
                techniques: techniques,
                techniqueKnowledges: techniqueKnowledges,
                karmaRecords: karmaRecords,
                legacies: legacies,
                reincarnationRecords: reincarnationRecords,
                worldSeeds: worldSeeds,
                recentHistory: Array(recentHistoryEvents.prefix(120)),
                years: years,
                modelContext: modelContext
            )
            insert(result)
            isSimulating = false
        }
    }

    private func performExploration() {
        guard let selectedRegion, !isSimulating else { return }

        isSimulating = true
        Task { @MainActor in
            let result = await SimulationEngine.explore(
                cultivator: cultivator,
                world: world,
                region: selectedRegion,
                sects: sects,
                npcs: npcs,
                regions: regions,
                factions: factions,
                techniques: techniques,
                techniqueKnowledges: techniqueKnowledges,
                karmaRecords: karmaRecords,
                legacies: legacies,
                reincarnationRecords: reincarnationRecords,
                worldSeeds: worldSeeds,
                recentHistory: Array(recentHistoryEvents.prefix(120)),
                years: explorationYears,
                modelContext: modelContext
            )
            insert(result)
            isSimulating = false
        }
    }

    private func performTechniqueInference() {
        guard !isSimulating else { return }
        let result = ResourceSystem.inferTechnique(
            cultivator: cultivator,
            world: world,
            techniques: techniques,
            knowledges: techniqueKnowledges,
            modelContext: modelContext
        )
        insert(result)
    }

    private func performResourceAction(_ action: ResourceAction) {
        guard !isSimulating else { return }
        let result: GameEngineResult
        switch action {
        case .rentCave:
            result = ResourceSystem.rentCave(cultivator: cultivator, world: world, region: selectedRegion)
        case .hireProtector:
            result = ResourceSystem.hireProtector(cultivator: cultivator, world: world)
        case .buyFragment:
            result = ResourceSystem.buyLowTierFragment(cultivator: cultivator, world: world, techniques: techniques, knowledges: techniqueKnowledges, modelContext: modelContext)
        case .donateSect:
            result = ResourceSystem.donateToSect(cultivator: cultivator, world: world)
        }
        insert(result)
    }

    private func performSectDuty() {
        guard !isSimulating else { return }
        isSimulating = true
        Task { @MainActor in
            let result = ResourceSystem.handleSectDuty(
                cultivator: cultivator,
                world: world,
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
            insert(SimulationEngine.filtered(result, recentHistory: Array(recentHistoryEvents.prefix(120))))
            isSimulating = false
        }
    }

    private func performSeclusion() {
        guard !isSimulating else { return }

        isSimulating = true
        Task { @MainActor in
            let result = await SimulationEngine.seclude(
                cultivator: cultivator,
                world: world,
                region: selectedRegion,
                sects: sects,
                npcs: npcs,
                regions: regions,
                factions: factions,
                techniques: techniques,
                karmaRecords: karmaRecords,
                legacies: legacies,
                reincarnationRecords: reincarnationRecords,
                worldSeeds: worldSeeds,
                recentHistory: Array(recentHistoryEvents.prefix(120)),
                modelContext: modelContext
            )
            insert(result)
            isSimulating = false
        }
    }

    private func insert(_ result: GameEngineResult) {
        for event in result.gameEvents {
            modelContext.insert(event)
        }
        for event in result.historyEvents {
            modelContext.insert(event)
        }
        try? modelContext.save()
    }
}

private enum ResourceAction {
    case rentCave
    case hireProtector
    case buyFragment
    case donateSect
}
