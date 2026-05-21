import SwiftUI

struct CharacterView: View {
    @Bindable var cultivator: Cultivator

    var body: some View {
        Form {
            Section("身份") {
                LabeledContent("姓名", value: cultivator.name)
                LabeledContent("称号", value: cultivator.title)
                LabeledContent("年龄", value: "\(cultivator.age) 岁")
                LabeledContent("境界", value: cultivator.realmText)
                LabeledContent("状态", value: cultivator.isAlive ? "求道中" : "已坐化")
            }

            Section("修为") {
                LabeledContent("当前灵气", value: cultivator.qi.wholeNumberText)
                LabeledContent("最大灵气", value: cultivator.maxQi.wholeNumberText)
                ProgressView(value: cultivator.qiProgress)
                    .tint(.cyan)
            }

            Section("资质") {
                LabeledContent("天赋", value: "\(cultivator.talent)")
                LabeledContent("悟性", value: "\(cultivator.comprehension)")
                LabeledContent("体魄", value: "\(cultivator.physique)")
                LabeledContent("气运", value: "\(cultivator.luck)")
            }

            Section("资源") {
                LabeledContent("灵石", value: "\(cultivator.spiritStone)")
            }

            Section("寿元") {
                LabeledContent("当前年龄", value: "\(cultivator.age) 岁")
                LabeledContent("最大寿元", value: "\(cultivator.lifespan) 年")
                LabeledContent("剩余寿元", value: "\(cultivator.remainingLifespan) 年")
                ProgressView(value: Double(cultivator.age), total: Double(max(cultivator.lifespan, 1)))
                    .tint(cultivator.remainingLifespan > 20 ? .green : .red)
            }
        }
    }
}
