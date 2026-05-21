import Foundation

enum Realm: String, CaseIterable, Codable, Identifiable, Comparable {
    case mortal
    case qiRefining
    case foundation
    case goldenCore
    case nascentSoul
    case spiritSevering
    case voidRefining
    case integration
    case mahayana
    case tribulation
    case trueImmortal
    case mysteriousImmortal
    case goldenImmortal
    case taiyiGoldenImmortal
    case greatLuoGoldenImmortal
    case daoAncestor

    nonisolated var id: String { rawValue }

    nonisolated var name: String {
        switch self {
        case .mortal: "凡人"
        case .qiRefining: "炼气"
        case .foundation: "筑基"
        case .goldenCore: "金丹"
        case .nascentSoul: "元婴"
        case .spiritSevering: "化神"
        case .voidRefining: "炼虚"
        case .integration: "合体"
        case .mahayana: "大乘"
        case .tribulation: "渡劫"
        case .trueImmortal: "真仙"
        case .mysteriousImmortal: "玄仙"
        case .goldenImmortal: "金仙"
        case .taiyiGoldenImmortal: "太乙金仙"
        case .greatLuoGoldenImmortal: "大罗金仙"
        case .daoAncestor: "道祖"
        }
    }

    nonisolated var multiplier: Double {
        switch self {
        case .mortal: 0.6
        case .qiRefining: 1.0
        case .foundation: 1.7
        case .goldenCore: 2.8
        case .nascentSoul: 4.4
        case .spiritSevering: 6.5
        case .voidRefining: 9.2
        case .integration: 12.8
        case .mahayana: 17.5
        case .tribulation: 23.0
        case .trueImmortal: 32.0
        case .mysteriousImmortal: 44.0
        case .goldenImmortal: 60.0
        case .taiyiGoldenImmortal: 84.0
        case .greatLuoGoldenImmortal: 118.0
        case .daoAncestor: 168.0
        }
    }

    nonisolated var lifespan: Int {
        switch self {
        case .mortal: 90
        case .qiRefining: 130
        case .foundation: 220
        case .goldenCore: 420
        case .nascentSoul: 850
        case .spiritSevering: 1_600
        case .voidRefining: 3_000
        case .integration: 5_500
        case .mahayana: 9_000
        case .tribulation: 12_000
        case .trueImmortal: 30_000
        case .mysteriousImmortal: 60_000
        case .goldenImmortal: 120_000
        case .taiyiGoldenImmortal: 240_000
        case .greatLuoGoldenImmortal: 500_000
        case .daoAncestor: 1_000_000
        }
    }

    nonisolated var next: Realm? {
        let realms = Realm.allCases
        guard let index = realms.firstIndex(of: self) else { return nil }
        let nextIndex = realms.index(after: index)
        guard nextIndex < realms.endIndex else { return nil }
        return realms[nextIndex]
    }

    nonisolated var isFinal: Bool {
        next == nil
    }

    nonisolated static func < (lhs: Realm, rhs: Realm) -> Bool {
        allCases.firstIndex(of: lhs) ?? 0 < allCases.firstIndex(of: rhs) ?? 0
    }
}
