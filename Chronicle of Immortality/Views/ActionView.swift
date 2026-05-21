import SwiftData
import SwiftUI

struct ActionView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var cultivator: Cultivator
    @Bindable var world: WorldState

    var body: some View {
        List {
            Section("闭关") {
                Button {
                    performCultivation(years: 1)
                } label: {
                    Label("闭关一年", systemImage: "moon.zzz")
                }

                Button {
                    performCultivation(years: 10)
                } label: {
                    Label("闭关十年", systemImage: "calendar")
                }

                Button {
                    performCultivation(years: 100)
                } label: {
                    Label("闭关百年", systemImage: "hourglass.circle")
                }
            }

            Section("历练") {
                Button {
                    performTravel()
                } label: {
                    Label("外出历练", systemImage: "figure.hiking")
                }
            }

            Section("当下") {
                LabeledContent("年份", value: "\(world.year) 年")
                LabeledContent("境界", value: cultivator.realmText)
                LabeledContent("灵气", value: "\(cultivator.qi.wholeNumberText) / \(cultivator.maxQi.wholeNumberText)")
                ProgressView(value: cultivator.qiProgress)
                    .tint(.cyan)
            }
        }
        .disabled(!cultivator.isAlive)
        .overlay {
            if !cultivator.isAlive {
                ContentUnavailableView("长生路已尽", systemImage: "scroll", description: Text("这部修真史已停在 \(world.year) 年。"))
            }
        }
    }

    private func performCultivation(years: Int) {
        let events = GameEngine.cultivate(cultivator: cultivator, world: world, years: years)
        insert(events)
    }

    private func performTravel() {
        let events = GameEngine.travel(cultivator: cultivator, world: world)
        insert(events)
    }

    private func insert(_ events: [GameEvent]) {
        for event in events {
            modelContext.insert(event)
        }
    }
}
