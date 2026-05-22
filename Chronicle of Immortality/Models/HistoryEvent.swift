import Foundation
import SwiftData

enum HistoryCategory: String, CaseIterable, Codable, Identifiable {
    case player
    case npc
    case sect
    case world
    case disaster
    case ascension
    case karma
    case faction
    case reincarnation
    case lineage
    case calamity

    nonisolated var id: String { rawValue }

    nonisolated var name: String {
        switch self {
        case .player: "玩家"
        case .npc: "NPC"
        case .sect: "宗门"
        case .world: "天下"
        case .disaster: "灾难"
        case .ascension: "飞升"
        case .karma: "因果"
        case .faction: "势力"
        case .reincarnation: "转世"
        case .lineage: "道统"
        case .calamity: "灾劫"
        }
    }
}

@Model
final class HistoryEvent {
    var year: Int
    var title: String
    var detail: String
    var category: HistoryCategory
    var importance: Int
    var createdAt: Date

    init(
        year: Int,
        title: String,
        detail: String,
        category: HistoryCategory,
        importance: Int = 1,
        createdAt: Date = .now
    ) {
        self.year = year
        self.title = title
        self.detail = detail
        self.category = category
        self.importance = importance
        self.createdAt = createdAt
    }
}
