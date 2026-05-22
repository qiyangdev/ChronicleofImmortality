import Foundation
import SwiftData

enum PlayerSectRole: String, CaseIterable, Codable, Identifiable, Comparable {
    case outerDisciple
    case innerDisciple
    case trueDisciple
    case elder
    case sectMaster

    nonisolated var id: String { rawValue }

    nonisolated var name: String {
        switch self {
        case .outerDisciple: "外门弟子"
        case .innerDisciple: "内门弟子"
        case .trueDisciple: "真传弟子"
        case .elder: "长老"
        case .sectMaster: "掌门"
        }
    }

    nonisolated static func < (lhs: PlayerSectRole, rhs: PlayerSectRole) -> Bool {
        allCases.firstIndex(of: lhs) ?? 0 < allCases.firstIndex(of: rhs) ?? 0
    }
}

@Model
final class Sect {
    var name: String
    var reputation: Double
    var righteousness: Double
    var prosperity: Double
    var disciplesCount: Int
    var elderCount: Int
    var spiritStoneReserve: Int

    init(
        name: String,
        reputation: Double,
        righteousness: Double,
        prosperity: Double,
        disciplesCount: Int,
        elderCount: Int,
        spiritStoneReserve: Int
    ) {
        self.name = name
        self.reputation = reputation
        self.righteousness = righteousness
        self.prosperity = prosperity
        self.disciplesCount = disciplesCount
        self.elderCount = elderCount
        self.spiritStoneReserve = spiritStoneReserve
    }

    var alignmentText: String {
        if righteousness >= 65 { return "正道" }
        if righteousness <= 35 { return "魔道" }
        return "中立"
    }

    var powerScore: Double {
        reputation * 0.35 + prosperity * 0.35 + Double(elderCount) * 2.4 + Double(disciplesCount) * 0.04
    }
}
