import SwiftUI

struct WorldView: View {
    @Bindable var world: WorldState

    var body: some View {
        Form {
            Section("纪年") {
                LabeledContent("当前年份", value: "\(world.year) 年")
                LabeledContent("当前时代", value: world.currentEra)
            }

            Section("天地") {
                MetricProgressView(title: "灵气浓度", value: world.aura, tint: .cyan)
                MetricProgressView(title: "天地气运", value: world.fortune, tint: .green)
                MetricProgressView(title: "魔道威胁", value: world.demonicThreat, tint: .red)
                MetricProgressView(title: "宗门声望", value: world.sectReputation, tint: .orange)
            }
        }
    }
}
