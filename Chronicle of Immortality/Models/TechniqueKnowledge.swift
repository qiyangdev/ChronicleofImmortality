import Foundation
import SwiftData

enum TechniquePracticeRole: String, CaseIterable, Codable, Identifiable {
    case primary
    case body
    case spirit
    case combat
    case movement
    case collection

    nonisolated var id: String { rawValue }

    nonisolated var name: String {
        switch self {
        case .primary: "主修"
        case .body: "炼体"
        case .spirit: "神识"
        case .combat: "斗法"
        case .movement: "遁法"
        case .collection: "收藏"
        }
    }
}

@Model
final class TechniqueKnowledge {
    var cultivatorName: String
    var techniqueName: String
    var role: TechniquePracticeRole
    var mastery: Double
    var acquiredYear: Int
    var source: String

    init(
        cultivatorName: String,
        techniqueName: String,
        role: TechniquePracticeRole = .collection,
        mastery: Double = 8,
        acquiredYear: Int,
        source: String
    ) {
        self.cultivatorName = cultivatorName
        self.techniqueName = techniqueName
        self.role = role
        self.mastery = min(max(mastery, 0), 100)
        self.acquiredYear = acquiredYear
        self.source = source
    }
}
