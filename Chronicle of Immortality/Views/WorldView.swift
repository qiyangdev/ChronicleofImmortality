import SwiftData
import SwiftUI

struct WorldView: View {
    @Query(sort: \Sect.name) private var sects: [Sect]
    @Query(sort: \Region.name) private var regions: [Region]
    @Query(sort: \NPC.name) private var npcs: [NPC]
    @Query(sort: \Faction.name) private var factions: [Faction]
    @Query(sort: \Legacy.influence, order: .reverse) private var legacies:
        [Legacy]
    @Query(sort: \WorldSeed.seed) private var worldSeeds: [WorldSeed]

    @Bindable var cultivator: Cultivator
    @Bindable var world: WorldState

    var body: some View {
        List {
            Section("世界状态") {
                LabeledContent("当前年份", value: "\(world.year) 年")
                LabeledContent("当前时代", value: world.currentEra)
                LabeledContent("灵气浓度", value: world.aura.percentText)
                LabeledContent("天地气运", value: world.fortune.percentText)
                LabeledContent("魔道威胁", value: world.demonicThreat.percentText)
                LabeledContent(
                    "文明水位",
                    value: world.civilizationLevel.percentText
                )
                LabeledContent(
                    "黄金大世",
                    value: world.goldenAgeProgress.percentText
                )
                LabeledContent(
                    "灾劫压力",
                    value: world.calamityPressure.percentText
                )
                LabeledContent("飞升记数", value: "\(world.ascensionCount)")
                if let seed = worldSeeds.first {
                    LabeledContent("世界种子", value: "\(seed.seed)")
                    LabeledContent("世界倾向", value: seed.worldTendencyText)
                }
            }

            Section("势力格局") {
                NavigationLink {
                    FactionListView(
                        factions: factions.sorted {
                            $0.influence > $1.influence
                        }
                    )
                    .navigationTitle("天下势力")
                } label: {
                    WorldNavigationRow(
                        title: "天下势力",
                        detail: "\(factions.count) 方势力"
                    )
                }

                NavigationLink {
                    LegacyListView(legacies: Array(legacies))
                        .navigationTitle("道统传承")
                } label: {
                    WorldNavigationRow(
                        title: "道统传承",
                        detail: "\(legacies.count) 脉道统"
                    )
                }
            }

            Section("宗门状态") {
                NavigationLink {
                    CurrentSectView(sect: cultivator.sect)
                        .navigationTitle("当前宗门")
                } label: {
                    WorldNavigationRow(
                        title: "当前宗门",
                        detail: cultivator.sectName
                    )
                }

                NavigationLink {
                    SectListView(
                        sects: sects.sorted { $0.powerScore > $1.powerScore }
                    )
                    .navigationTitle("天下宗门")
                } label: {
                    WorldNavigationRow(
                        title: "天下宗门",
                        detail: "\(sects.count) 座山门"
                    )
                }
            }

            Section("地图区域") {
                NavigationLink {
                    RegionListView(regions: regions, cultivator: cultivator)
                        .navigationTitle("区域列表")
                } label: {
                    WorldNavigationRow(
                        title: "区域列表",
                        detail: "\(regions.count) 处地界"
                    )
                }
            }

            Section("NPC 世界") {
                NavigationLink {
                    NPCListView(
                        emptyText: "暂无成名强者",
                        npcs: strongNPCs,
                        style: .strong
                    )
                        .navigationTitle("强者列表")
                } label: {
                    WorldNavigationRow(
                        title: "强者列表",
                        detail: "\(strongNPCs.count) 人"
                    )
                }

                NavigationLink {
                    NPCListView(
                        emptyText: "尚无人飞升",
                        npcs: ascendedNPCs,
                        style: .ascended
                    )
                        .navigationTitle("飞升者")
                } label: {
                    WorldNavigationRow(
                        title: "飞升者",
                        detail: "\(ascendedNPCs.count) 人"
                    )
                }

                NavigationLink {
                    NPCListView(
                        emptyText: "尚无坐化记录",
                        npcs: deadNPCs,
                        style: .dead
                    )
                        .navigationTitle("已死亡 NPC")
                } label: {
                    WorldNavigationRow(
                        title: "已死亡 NPC",
                        detail: "\(deadNPCs.count) 人"
                    )
                }

                NavigationLink {
                    NPCListView(
                        emptyText: "魔道暂伏",
                        npcs: demonicNPCs,
                        style: .demonic
                    )
                        .navigationTitle("魔道势力")
                } label: {
                    WorldNavigationRow(
                        title: "魔道势力",
                        detail: "\(demonicNPCs.count) 人"
                    )
                }
            }
        }
    }

    private var strongNPCs: [NPC] {
        npcs
            .filter { $0.isAlive }
            .sorted {
                if $0.realm == $1.realm {
                    return $0.stage > $1.stage
                }
                return $0.realm > $1.realm
            }
            .prefix(8)
            .map(\.self)
    }

    private var ascendedNPCs: [NPC] {
        npcs.filter { $0.isAscended }.sorted {
            ($0.deathYear ?? 0) > ($1.deathYear ?? 0)
        }
    }

    private var deadNPCs: [NPC] {
        npcs.filter { !$0.isAlive && !$0.isAscended }.sorted {
            ($0.deathYear ?? 0) > ($1.deathYear ?? 0)
        }
    }

    private var demonicNPCs: [NPC] {
        npcs.filter { $0.isAlive && $0.isDemonic }.sorted {
            $0.realm > $1.realm
        }
    }
}

private enum NPCSummaryStyle {
    case strong
    case ascended
    case dead
    case demonic

    func statusText(for npc: NPC) -> String? {
        switch self {
        case .strong:
            npc.isAlive ? "在世" : nil
        case .ascended:
            if let year = npc.deathYear {
                "第 \(year) 年飞升"
            } else {
                "已飞升"
            }
        case .dead:
            if let year = npc.deathYear {
                "第 \(year) 年坐化"
            } else {
                "已陨落"
            }
        case .demonic:
            "魔道相关"
        }
    }
}

private struct WorldNavigationRow: View {
    let title: String
    let detail: String

    var body: some View {
        LabeledContent(title, value: detail)
    }
}

private struct FactionListView: View {
    let factions: [Faction]

    var body: some View {
        List {
            if factions.isEmpty {
                ContentUnavailableView(
                    "天下无势力",
                    systemImage: "globe.asia.australia"
                )
            } else {
                ForEach(factions) { faction in
                    FactionSummaryView(faction: faction)
                }
            }
        }
    }
}

private struct LegacyListView: View {
    let legacies: [Legacy]

    var body: some View {
        List {
            if legacies.isEmpty {
                ContentUnavailableView("尚无显赫道统", systemImage: "books.vertical")
            } else {
                ForEach(legacies) { legacy in
                    LegacySummaryView(legacy: legacy)
                }
            }
        }
    }
}

private struct CurrentSectView: View {
    let sect: Sect?

    var body: some View {
        List {
            if let sect {
                SectSummaryView(sect: sect)
            } else {
                ContentUnavailableView(
                    "尚未拜入宗门",
                    systemImage: "building.columns"
                )
            }
        }
    }
}

private struct SectListView: View {
    let sects: [Sect]

    var body: some View {
        List {
            if sects.isEmpty {
                ContentUnavailableView("天下无宗", systemImage: "building.columns")
            } else {
                ForEach(sects) { sect in
                    SectSummaryView(sect: sect)
                }
            }
        }
    }
}

private struct RegionListView: View {
    let regions: [Region]
    let cultivator: Cultivator

    var body: some View {
        List {
            if regions.isEmpty {
                ContentUnavailableView("尚无区域", systemImage: "map")
            } else {
                ForEach(regions) { region in
                    RegionSummaryView(
                        region: region,
                        unlocked: cultivator.realm >= region.unlockedRealm
                    )
                }
            }
        }
    }
}

private struct NPCListView: View {
    let emptyText: String
    let npcs: [NPC]
    let style: NPCSummaryStyle

    var body: some View {
        List {
            if npcs.isEmpty {
                ContentUnavailableView(emptyText, systemImage: "person.3")
            } else {
                ForEach(npcs) { npc in
                    NPCSummaryView(npc: npc, statusText: style.statusText(for: npc))
                }
            }
        }
    }
}

private struct FactionSummaryView: View {
    let faction: Faction

    var body: some View {
        Section {
            LabeledContent("影响", value: faction.influence.percentText)
            LabeledContent("领袖", value: faction.leader)
            LabeledContent(
                "成员",
                value: faction.members.isEmpty ? "无" : faction.members
            )
            LabeledContent(
                "盟友",
                value: faction.allies.isEmpty ? "无" : faction.allies
            )
            LabeledContent(
                "敌对",
                value: faction.enemies.isEmpty ? "无" : faction.enemies
            )
        } header: {
            HStack {
                Text(faction.name)
                Spacer()
                Text(faction.summaryText)
            }
        }
    }
}

private struct LegacySummaryView: View {
    let legacy: Legacy

    var body: some View {
        Section {
            LabeledContent("祖师", value: legacy.founder)
            LabeledContent("源流", value: legacy.faction)
            LabeledContent("影响", value: legacy.influence.percentText)
            LabeledContent("传人", value: "\(legacy.descendants)")
        } header: {
            Text(legacy.technique)
        }
    }
}

private struct SectSummaryView: View {
    let sect: Sect

    var body: some View {
        Section {
            LabeledContent("声望", value: sect.reputation.percentText)
            LabeledContent("繁荣", value: sect.prosperity.percentText)
            LabeledContent("倾向", value: sect.righteousness.percentText)
            LabeledContent("弟子", value: "\(sect.disciplesCount)")
            LabeledContent("长老", value: "\(sect.elderCount)")
            LabeledContent("库藏灵石", value: "\(sect.spiritStoneReserve)")
        } header: {
            HStack {
                Text(sect.name)
                Spacer()
                Text(sect.alignmentText)
            }
        }
    }
}

private struct RegionSummaryView: View {
    let region: Region
    let unlocked: Bool

    var body: some View {
        Section {
            LabeledContent("灵气", value: region.aura.percentText)
            LabeledContent("危险", value: region.danger.percentText)
            LabeledContent("资源", value: region.resources.percentText)
            LabeledContent("魔染", value: region.demonicInfluence.percentText)
            LabeledContent("状态", value: region.state.name)
        } header: {
            Text(region.name)
        } footer: {
            Text(unlocked ? "可前往" : region.unlockText)
        }
    }
}

private struct NPCSummaryView: View {
    let npc: NPC
    let statusText: String?

    var body: some View {
        Section {
            if let statusText {
                LabeledContent("状态", value: statusText)
            }
            LabeledContent("境界", value: npc.realmText)
            LabeledContent("年龄", value: "\(npc.age) 岁")
            LabeledContent("宗门", value: npc.sectName)
            LabeledContent("性情", value: npc.personality.name)
        } header: {
            HStack {
                Text(npc.name)
                Spacer()
                Text(npc.title)
            }
        }
    }
}
