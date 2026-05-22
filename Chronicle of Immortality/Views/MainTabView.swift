import SwiftData
import SwiftUI

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \KarmaRecord.year, order: .reverse) private var karmaRecords: [KarmaRecord]

    @Bindable var cultivator: Cultivator
    @Bindable var world: WorldState
    let onLeaveWorld: () -> Void

    @State private var showDeathDialog = false

    init(cultivator: Cultivator, world: WorldState, onLeaveWorld: @escaping () -> Void = {}) {
        self.cultivator = cultivator
        self.world = world
        self.onLeaveWorld = onLeaveWorld
    }

    var body: some View {
        TabView {
            Tab("角色", systemImage: "person.text.rectangle") {
                NavigationStack {
                    CharacterView(cultivator: cultivator)
                        .navigationTitle("角色")
                }
            }

            Tab("行动", systemImage: "hourglass") {
                NavigationStack {
                    ActionView(cultivator: cultivator, world: world)
                        .navigationTitle("行动")
                }
            }

            Tab("天地", systemImage: "globe.asia.australia") {
                NavigationStack {
                    WorldView(cultivator: cultivator, world: world)
                        .navigationTitle("天地")
                }
            }

            Tab("日志", systemImage: "scroll") {
                NavigationStack {
                    EventLogView()
                        .navigationTitle("日志")
                }
            }
        }
        .onAppear {
            showDeathDialog = !cultivator.isAlive
        }
        .onChange(of: cultivator.isAlive) { _, isAlive in
            if !isAlive {
                showDeathDialog = true
            }
        }
        .alert("身死道消", isPresented: $showDeathDialog) {
            if cultivator.canReincarnate {
                Button("转世重修") {
                    reincarnate()
                }
            }

            Button(cultivator.canReincarnate ? "暂不转世" : "尘缘已尽", role: cultivator.canReincarnate ? .cancel : nil) {
                onLeaveWorld()
            }
        } message: {
            Text(deathMessage)
        }
    }

    private var deathMessage: String {
        if cultivator.canReincarnate {
            return "\(cultivator.name) 享年 \(cultivator.age) 岁，止步 \(cultivator.realmText)。元神未散，尚可携部分因果与传承入轮回。"
        }

        return "\(cultivator.name) 享年 \(cultivator.age) 岁，止步 \(cultivator.realmText)。未至 \(ReincarnationSystem.minimumRealm.name)，神魂难聚，无法转世。"
    }

    private func reincarnate() {
        let result = ReincarnationSystem.reincarnate(
            player: cultivator,
            world: world,
            karmaRecords: karmaRecords,
            modelContext: modelContext
        )

        for event in result.gameEvents {
            modelContext.insert(event)
        }
        for event in result.historyEvents {
            modelContext.insert(event)
        }
        try? modelContext.save()
    }
}
