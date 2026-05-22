import SwiftData
import SwiftUI

struct CharacterView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Technique.name) private var techniques: [Technique]
    @Query(sort: \TechniqueKnowledge.acquiredYear, order: .reverse) private var techniqueKnowledges: [TechniqueKnowledge]
    @Query(sort: \KarmaRecord.year, order: .reverse) private var karmaRecords: [KarmaRecord]
    @Query(sort: \Legacy.createdYear, order: .reverse) private var legacies: [Legacy]
    @Query(sort: \ReincarnationRecord.year, order: .reverse) private var reincarnationRecords: [ReincarnationRecord]
    @Bindable var cultivator: Cultivator

    var body: some View {
        Form {
            Section("身份") {
                LabeledContent("姓名", value: cultivator.name)
                LabeledContent("称号", value: cultivator.title)
                LabeledContent("年龄", value: "\(cultivator.age) 岁")
                LabeledContent("境界", value: cultivator.realmText)
                LabeledContent("宗门", value: cultivator.sectName)
                LabeledContent("身份", value: cultivator.sectRole.name)
                LabeledContent("状态", value: cultivator.isAlive ? "求道中" : "已坐化")
            }

            Section("修为") {
                LabeledContent("当前灵气", value: cultivator.qi.wholeNumberText)
                LabeledContent("最大灵气", value: cultivator.maxQi.wholeNumberText)
                LabeledContent("修为进度", value: (cultivator.qiProgress * 100).percentText)
                LabeledContent("道基", value: "\(cultivator.daoFoundation.percentText) · \(cultivator.cultivationStateText)")
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

            Section("功法") {
                LabeledContent("主修", value: cultivator.equippedTechniqueText)
                LabeledContent("已得传承", value: "\(availableTechniques.count) 部")
                LabeledContent("未得法门", value: "\(unknownTechniqueCount) 部")

                techniquePicker("主修功法", selection: selectedPrimaryTechniqueName, candidates: availableTechniques.filter { $0.type != .movement })
                techniquePicker("炼体辅修", selection: selectedBodyTechniqueName, candidates: availableTechniques.filter { $0.type == .body })
                techniquePicker("神识辅修", selection: selectedSpiritTechniqueName, candidates: availableTechniques.filter { $0.type == .spirit })
                techniquePicker("斗法辅修", selection: selectedCombatTechniqueName, candidates: availableTechniques.filter { $0.type == .sword || $0.type == .demonic })
                techniquePicker("遁法", selection: selectedMovementTechniqueName, candidates: availableTechniques.filter { $0.type == .movement })

                if !cultivator.practicedTechniques.isEmpty {
                    ForEach(cultivator.practicedTechniques) { technique in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(technique.name) · \(technique.summaryText)")
                                .font(.headline)
                            Text(techniqueEffectText(for: technique))
                                .font(.callout)
                                .foregroundStyle(.secondary)
                            if let knowledge = playerKnowledge(for: technique) {
                                Text("掌握 \(knowledge.mastery.percentText) · \(knowledge.source)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(technique.sideEffect)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("寿元") {
                LabeledContent("当前年龄", value: "\(cultivator.age) 岁")
                LabeledContent("最大寿元", value: "\(cultivator.lifespan) 年")
                LabeledContent("剩余寿元", value: "\(cultivator.remainingLifespan) 年")
                if !cultivator.deathSummary.isEmpty {
                    Text(cultivator.deathSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("因果") {
                if playerKarma.isEmpty {
                    Text("尚无深重因果")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(playerKarma.prefix(5)) { record in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(record.relationshipText) · \(record.source) / \(record.target)")
                                .font(.headline)
                            Text("第 \(record.year) 年 · \(record.reason)")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("道统") {
                if playerLegacies.isEmpty {
                    Text("尚无传世道统")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(playerLegacies.prefix(5)) { legacy in
                        LabeledContent(legacy.technique, value: "影响 \(legacy.influence.percentText)")
                    }
                }
            }

            Section("转世") {
                if reincarnationRecords.isEmpty {
                    Text("尚未经历轮回")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(reincarnationRecords.prefix(3)) { record in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(record.previousName) → \(record.currentName)")
                                .font(.headline)
                            Text("第 \(record.year) 年 · 前世 \(record.previousRealm.name) · 因果承载 \(record.karmaCarryOver)")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                            Text(record.inheritance)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var playerKarma: [KarmaRecord] {
        karmaRecords.filter { $0.source == cultivator.name || $0.target == cultivator.name || $0.source.contains("转世") || $0.target.contains("转世") }
    }

    private var playerLegacies: [Legacy] {
        legacies.filter { $0.founder == cultivator.name || $0.founder.contains(cultivator.name.replacingOccurrences(of: "转世", with: "")) }
    }

    private var availableTechniques: [Technique] {
        TechniqueKnowledgeSystem.knownTechniques(for: cultivator, techniques: techniques, knowledges: techniqueKnowledges)
    }

    private var unknownTechniqueCount: Int {
        max(0, techniques.count - availableTechniques.count)
    }

    private func playerKnowledge(for technique: Technique) -> TechniqueKnowledge? {
        TechniqueKnowledgeSystem.knowledge(for: cultivator, technique: technique, knowledges: techniqueKnowledges)
    }

    @ViewBuilder
    private func techniquePicker(_ title: String, selection: Binding<String>, candidates: [Technique]) -> some View {
        Picker(title, selection: selection) {
            Text("未修").tag("")
            ForEach(candidates) { technique in
                Text("\(technique.name) · \(technique.rarity.name)").tag(technique.name)
            }
        }
    }

    private func techniqueEffectText(for technique: Technique) -> String {
        if technique.type == .movement {
            let sealText = technique.canBypassRegionSeal ? "，可破区域封锁" : ""
            return "身法 \(technique.movementSpeedBonus.percentText)\(sealText)"
        }
        return "修炼 \(technique.cultivationBonus.percentText) · 破境 \(technique.breakthroughBonus.percentText) · 寿元 \(technique.lifespanBonus)"
    }

    private var selectedPrimaryTechniqueName: Binding<String> {
        Binding {
            cultivator.activePrimaryTechnique?.name ?? ""
        } set: { name in
            let technique = availableTechniques.first { $0.name == name }
            TechniqueKnowledgeSystem.setPracticeRole(cultivator: cultivator, technique: technique, role: .primary, knowledges: techniqueKnowledges)
            try? modelContext.save()
        }
    }

    private var selectedBodyTechniqueName: Binding<String> {
        techniqueBinding(for: \.bodyTechnique, role: .body)
    }

    private var selectedSpiritTechniqueName: Binding<String> {
        techniqueBinding(for: \.spiritTechnique, role: .spirit)
    }

    private var selectedCombatTechniqueName: Binding<String> {
        techniqueBinding(for: \.combatTechnique, role: .combat)
    }

    private var selectedMovementTechniqueName: Binding<String> {
        techniqueBinding(for: \.movementTechnique, role: .movement)
    }

    private func techniqueBinding(for keyPath: ReferenceWritableKeyPath<Cultivator, Technique?>, role: TechniquePracticeRole) -> Binding<String> {
        Binding {
            cultivator[keyPath: keyPath]?.name ?? ""
        } set: { name in
            let technique = availableTechniques.first { $0.name == name }
            TechniqueKnowledgeSystem.setPracticeRole(cultivator: cultivator, technique: technique, role: role, knowledges: techniqueKnowledges)
            try? modelContext.save()
        }
    }
}
