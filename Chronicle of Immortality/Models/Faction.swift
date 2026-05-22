import Foundation
import SwiftData

enum FactionAlignment: String, CaseIterable, Codable, Identifiable {
    case righteous
    case demonic
    case neutral
    case yaozu
    case ancient

    nonisolated var id: String { rawValue }

    nonisolated var name: String {
        switch self {
        case .righteous: "正道"
        case .demonic: "魔道"
        case .neutral: "中立"
        case .yaozu: "妖族"
        case .ancient: "古族"
        }
    }
}

@Model
final class Faction {
    var name: String
    var alignment: FactionAlignment
    var influence: Double
    var territory: String
    var leader: String
    var members: String
    var enemies: String
    var allies: String

    init(
        name: String,
        alignment: FactionAlignment,
        influence: Double,
        territory: String,
        leader: String,
        members: String,
        enemies: String = "",
        allies: String = ""
    ) {
        self.name = name
        self.alignment = alignment
        self.influence = influence
        self.territory = territory
        self.leader = leader
        self.members = members
        self.enemies = enemies
        self.allies = allies
    }

    var summaryText: String {
        "\(alignment.name) · \(territory)"
    }
}
