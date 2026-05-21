import SwiftUI

struct MainTabView: View {
    @Bindable var cultivator: Cultivator
    @Bindable var world: WorldState

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
                    WorldView(world: world)
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
    }
}
