import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var cultivators: [Cultivator]
    @Query private var worlds: [WorldState]
    @Query private var sects: [Sect]
    @Query private var regions: [Region]
    @Query private var techniques: [Technique]
    @Query private var techniqueKnowledges: [TechniqueKnowledge]
    @Query private var npcs: [NPC]
    @Query private var factions: [Faction]
    @Query private var worldSeeds: [WorldSeed]
    @Query private var karmaRecords: [KarmaRecord]
    @Query private var legacies: [Legacy]
    @Query private var saveMetadata: [SaveMetadata]
    @State private var showsArchive = false

    var body: some View {
        Group {
            if let cultivator = activeCultivator, let world = worlds.first,
                !showsArchive
            {
                MainTabView(cultivator: cultivator, world: world) {
                    showsArchive = true
                }
            } else {
                CharacterArchiveView(
                    cultivators: sortedCultivators,
                    world: worlds.first
                ) {
                    showsArchive = false
                }
            }
        }
        .task {
            if let cultivator = activeCultivator ?? cultivators.first,
                let world = worlds.first
            {
                SaveVersionManager.ensureMetadata(
                    metadata: saveMetadata,
                    world: world,
                    worldSeeds: worldSeeds,
                    modelContext: modelContext
                )
                SaveVersionManager.repairWorldDefaults(world)
                SaveVersionManager.repairTechniqueDefaults(
                    for: cultivator,
                    world: world,
                    techniques: techniques,
                    knowledges: techniqueKnowledges,
                    legacies: legacies,
                    modelContext: modelContext
                )
                if needsCivilizationSeed {
                    WorldSystem.repairCivilization(
                        for: cultivator,
                        world: world,
                        in: modelContext
                    )
                }
                try? modelContext.save()
            }
        }
    }

    private var needsCivilizationSeed: Bool {
        sects.isEmpty || regions.isEmpty || techniques.isEmpty || npcs.isEmpty
            || factions.isEmpty || worldSeeds.isEmpty || karmaRecords.isEmpty
    }

    private var activeCultivator: Cultivator? {
        sortedCultivators.first { $0.isAlive }
    }

    private var sortedCultivators: [Cultivator] {
        cultivators.sorted {
            if $0.isAlive != $1.isAlive {
                return $0.isAlive && !$1.isAlive
            }
            return $0.age > $1.age
        }
    }
}

private struct CharacterArchiveView: View {
    let cultivators: [Cultivator]
    let world: WorldState?
    let onCreated: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("此界") {
                    if let world {
                        LabeledContent("年份", value: "\(world.year) 年")
                        LabeledContent("时代", value: world.currentEra)
                        LabeledContent("灵气", value: world.aura.percentText)
                    } else {
                        Text("尚未开辟世界")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("历代人物") {
                    if cultivators.isEmpty {
                        Text("尚无角色存档")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(cultivators) { cultivator in
                            HistoricalCultivatorRow(cultivator: cultivator)
                        }
                    }
                }

                NewGameView(
                    existingWorld: world,
                    isEmbedded: true,
                    onCreated: onCreated
                )
            }
            .navigationTitle("长生历")
        }
    }
}

private struct HistoricalCultivatorRow: View {
    let cultivator: Cultivator

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(cultivator.name)
                    .font(.headline)
                Spacer()
                Text(cultivator.isAlive ? "在世" : "已坐化")
                    .font(.caption)
                    .foregroundStyle(cultivator.isAlive ? .green : .secondary)
            }

            Text("\(cultivator.title) · \(cultivator.realmText)")
                .font(.callout)

            Text(
                "\(cultivator.age) 岁 · \(cultivator.sectName) · \(cultivator.equippedTechniqueText)"
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            if !cultivator.deathSummary.isEmpty {
                Text(cultivator.deathSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
