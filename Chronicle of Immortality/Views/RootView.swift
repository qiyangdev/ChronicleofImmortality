import SwiftData
import SwiftUI

struct RootView: View {
    @Query private var cultivators: [Cultivator]
    @Query private var worlds: [WorldState]

    var body: some View {
        if let cultivator = cultivators.first, let world = worlds.first {
            MainTabView(cultivator: cultivator, world: world)
        } else {
            NewGameView()
        }
    }
}
