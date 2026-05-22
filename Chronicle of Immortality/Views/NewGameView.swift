import SwiftData
import SwiftUI

struct NewGameView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Sect.reputation, order: .reverse) private var sects: [Sect]
    @Query(sort: \Technique.name) private var techniques: [Technique]
    @Query(sort: \TechniqueKnowledge.acquiredYear, order: .reverse) private var techniqueKnowledges: [TechniqueKnowledge]
    @Query(sort: \Legacy.createdYear, order: .reverse) private var legacies: [Legacy]

    let existingWorld: WorldState?
    let onCreated: () -> Void
    let isEmbedded: Bool

    @State private var name = ""

    init(
        existingWorld: WorldState? = nil,
        isEmbedded: Bool = false,
        onCreated: @escaping () -> Void = {}
    ) {
        self.existingWorld = existingWorld
        self.isEmbedded = isEmbedded
        self.onCreated = onCreated
    }

    var body: some View {
        if isEmbedded {
            creationContent
        } else if existingWorld == nil {
            NavigationStack {
                formContent
                    .navigationTitle("长生历")
            }
        } else {
            creationContent
        }
    }

    private var formContent: some View {
        Form {
            creationSection

            Section("卷首") {
                Text("天地初启，山门未兴。你将在漫长岁月中闭关、历练、破境，并见证修真文明的起落。")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var creationContent: some View {
        Section {
            TextField("道号或本名", text: $name)
                .textInputAutocapitalization(.never)

            Button {
                createGame()
            } label: {
                Label(
                    existingWorld == nil ? "开辟长生历" : "此世再开一传",
                    systemImage: "sparkles"
                )
            }
            .disabled(trimmedName.isEmpty)
        } header: {
            Text("立传")
        } footer: {
            Text(existingWorld == nil ? "天地初启，山门未兴。" : "旧人已入史册，此界仍会继续演化。")
        }
    }

    private var creationSection: some View {
        creationContent
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func createGame() {
        let cultivator = Cultivator(name: trimmedName)
        let world: WorldState
        if let existingWorld {
            world = existingWorld
            configure(cultivator, for: world)
        } else {
            world = WorldSystem.bootstrapWorld(
                for: cultivator,
                in: modelContext
            )
        }

        let event = GameEvent(
            year: world.year,
            title: "长生历开卷",
            detail:
                "\(cultivator.name) 入山求道，拜入 \(cultivator.sectName)，自此在第 \(world.year) 年续写长生历。",
            importance: 3
        )
        let history = HistoryEvent(
            year: world.year,
            title: "\(cultivator.name) 入世",
            detail:
                "\(cultivator.name) 承此界旧史而来，拜入 \(cultivator.sectName)，成为新一代求道人。",
            category: .player,
            importance: 2
        )

        modelContext.insert(cultivator)
        modelContext.insert(event)
        modelContext.insert(history)
        try? modelContext.save()
        name = ""
        onCreated()
    }

    private func configure(_ cultivator: Cultivator, for world: WorldState) {
        cultivator.sect = sects.first
        cultivator.sectRole = .outerDisciple

        let knownTechniques = techniques.filter { $0.rarity <= .yellow }
        cultivator.primaryTechnique = knownTechniques.first {
            $0.type == .cultivation
        }
        cultivator.movementTechnique = knownTechniques.first {
            $0.type == .movement
        }
        cultivator.equippedTechnique = cultivator.activePrimaryTechnique
        cultivator.refreshCultivationLimit()
        TechniqueKnowledgeSystem.ensureStartingKnowledge(
            for: cultivator,
            world: world,
            techniques: techniques,
            knowledges: techniqueKnowledges,
            legacies: legacies,
            modelContext: modelContext
        )

        world.fortune = GameMath.clamp(
            world.fortune + Double.random(in: -1.5...2.5),
            lower: 1,
            upper: 100
        )
    }
}
