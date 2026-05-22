import Foundation

enum SectSystem {
    static func advance(sects: [Sect], world: WorldState) -> [HistoryEvent] {
        var events: [HistoryEvent] = []

        for sect in sects {
            let auraIncome = world.aura * sect.prosperity / 145
            let riskCost = world.demonicThreat * (100 - sect.righteousness) / 900
            let reserveChange = Int((auraIncome - riskCost + Double.random(in: -4...8)).rounded())
            sect.spiritStoneReserve = max(0, sect.spiritStoneReserve + reserveChange)

            sect.prosperity = GameMath.clamp(
                sect.prosperity + world.aura / 150 - world.demonicThreat / 210 + Double.random(in: -1.2...1.5),
                lower: 0,
                upper: 100
            )
            sect.reputation = GameMath.clamp(
                sect.reputation + sect.prosperity / 260 - world.demonicThreat / 300 + Double.random(in: -1...1.3),
                lower: 0,
                upper: 100
            )

            if sect.righteousness < 34 {
                world.demonicThreat = GameMath.clamp(world.demonicThreat + 0.08, lower: 0, upper: 100)
            }

            if GameMath.chance((2.8 + sect.prosperity / 80) * BalanceConfig.current.factionExpansionMultiplier) {
                events.append(recruitDisciples(for: sect, world: world))
            }

            if GameMath.chance(1.7 * BalanceConfig.current.factionExpansionMultiplier), world.aura > 58 {
                events.append(spiritVeinRevives(for: sect, world: world))
            }

            if GameMath.chance((1.6 + world.demonicThreat / 70) * BalanceConfig.current.factionExpansionMultiplier) {
                events.append(sectWar(for: sect, world: world))
            }

            if sect.prosperity < 18 || sect.spiritStoneReserve < 120 {
                if GameMath.chance(3.2 * BalanceConfig.current.factionExpansionMultiplier) {
                    events.append(sectDeclines(for: sect, world: world))
                }
            }

            if world.year.isMultiple(of: 30), GameMath.chance(18 * BalanceConfig.current.factionExpansionMultiplier) {
                events.append(sectCompetition(for: sect, world: world))
            }
        }

        return events
    }

    private static func recruitDisciples(for sect: Sect, world: WorldState) -> HistoryEvent {
        let recruits = Int(Double.random(in: 12...96) * BalanceConfig.current.factionExpansionMultiplier)
        sect.disciplesCount += recruits
        sect.spiritStoneReserve = max(0, sect.spiritStoneReserve - recruits / 2)
        sect.reputation = GameMath.clamp(sect.reputation + Double.random(in: 1...4), lower: 0, upper: 100)

        return HistoryEvent(
            year: world.year,
            title: "\(sect.name) 招收弟子",
            detail: "\(sect.name) 山门大开，新收弟子 \(recruits) 人，声势渐盛。",
            category: .sect,
            importance: 1
        )
    }

    private static func spiritVeinRevives(for sect: Sect, world: WorldState) -> HistoryEvent {
        let stones = Int(Double.random(in: 260...980) * BalanceConfig.current.spiritStoneYieldMultiplier)
        sect.spiritStoneReserve += stones
        sect.prosperity = GameMath.clamp(sect.prosperity + Double.random(in: 5...12), lower: 0, upper: 100)
        sect.reputation = GameMath.clamp(sect.reputation + Double.random(in: 2...7), lower: 0, upper: 100)
        world.aura = GameMath.clamp(world.aura + Double.random(in: 1...4), lower: 1, upper: 100)

        return HistoryEvent(
            year: world.year,
            title: "\(sect.name) 灵脉复苏",
            detail: "\(sect.name) 后山灵脉复苏，宗门得灵石 \(stones) 枚，附近灵机随之回涨。",
            category: .sect,
            importance: 2
        )
    }

    private static func sectWar(for sect: Sect, world: WorldState) -> HistoryEvent {
        let loss = Int(Double.random(in: 18...160) * BalanceConfig.current.factionExpansionMultiplier)
        let reserveLoss = Int(Double.random(in: 120...720) * BalanceConfig.current.spiritStoneYieldMultiplier)
        sect.disciplesCount = max(0, sect.disciplesCount - loss)
        sect.spiritStoneReserve = max(0, sect.spiritStoneReserve - reserveLoss)
        sect.reputation = GameMath.clamp(sect.reputation + Double.random(in: -5...6), lower: 0, upper: 100)
        sect.prosperity = GameMath.clamp(sect.prosperity - Double.random(in: 2...9), lower: 0, upper: 100)
        world.demonicThreat = GameMath.clamp(world.demonicThreat + Double.random(in: 1...5), lower: 0, upper: 100)

        return HistoryEvent(
            year: world.year,
            title: "\(sect.name) 卷入宗门战争",
            detail: "\(sect.name) 与敌对势力鏖战，折损弟子 \(loss) 人，山门气数震荡。",
            category: .sect,
            importance: 2
        )
    }

    private static func sectDeclines(for sect: Sect, world: WorldState) -> HistoryEvent {
        let leaving = min(sect.disciplesCount, Int.random(in: 8...70))
        sect.disciplesCount -= leaving
        sect.prosperity = GameMath.clamp(sect.prosperity - Double.random(in: 3...8), lower: 0, upper: 100)
        sect.reputation = GameMath.clamp(sect.reputation - Double.random(in: 2...7), lower: 0, upper: 100)

        return HistoryEvent(
            year: world.year,
            title: "\(sect.name) 宗门衰败",
            detail: "\(sect.name) 库藏空虚，弟子离山 \(leaving) 人，旧日楼阁渐生荒草。",
            category: .sect,
            importance: 2
        )
    }

    private static func sectCompetition(for sect: Sect, world: WorldState) -> HistoryEvent {
        let fame = Double.random(in: 2...8)
        sect.reputation = GameMath.clamp(sect.reputation + fame, lower: 0, upper: 100)
        sect.prosperity = GameMath.clamp(sect.prosperity + fame / 2, lower: 0, upper: 100)

        return HistoryEvent(
            year: world.year,
            title: "\(sect.name) 举行宗门大比",
            detail: "\(sect.name) 诸峰弟子斗法论道，一批年轻修士开始崭露头角。",
            category: .sect,
            importance: 1
        )
    }
}
