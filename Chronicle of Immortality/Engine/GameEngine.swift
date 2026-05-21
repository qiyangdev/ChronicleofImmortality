import Foundation

enum GameEngine {
    static func cultivate(cultivator: Cultivator, world: WorldState, years: Int) -> [GameEvent] {
        guard cultivator.isAlive else {
            return [
                GameEvent(
                    year: world.year,
                    title: "长生路绝",
                    detail: "\(cultivator.name) 已身死道消，只余旧事载入山门残卷。",
                    importance: 2
                )
            ]
        }

        var events: [GameEvent] = []
        let cultivationYears = max(years, 1)

        for _ in 0..<cultivationYears {
            worldTick(world)
            if let deathEvent = advanceAge(for: cultivator, in: world) {
                events.append(deathEvent)
            }
            guard cultivator.isAlive else { break }

            let yearlyQi = qiGain(for: cultivator, in: world)
            cultivator.qi = min(cultivator.qi + yearlyQi, cultivator.maxQi * 1.25)

            if Int.random(in: 1...100) <= 42 {
                let stones = max(1, Int((Double.random(in: 1...5) * cultivator.realm.multiplier).rounded()))
                cultivator.spiritStone += stones
            }

            if let event = randomEvent(cultivator: cultivator, world: world) {
                events.append(event)
            }

            if cultivator.qi >= cultivator.maxQi {
                let breakthroughEvent = tryBreakthrough(cultivator: cultivator, world: world)
                events.append(breakthroughEvent)
            }
        }

        if events.isEmpty {
            events.append(
                GameEvent(
                    year: world.year,
                    title: "闭关修炼",
                    detail: "\(cultivator.name) 静坐洞府 \(cultivationYears) 年，吐纳天地灵机，修为渐有寸进。"
                )
            )
        }

        return events
    }

    static func travel(cultivator: Cultivator, world: WorldState) -> [GameEvent] {
        guard cultivator.isAlive else {
            return [
                GameEvent(
                    year: world.year,
                    title: "尘缘已断",
                    detail: "\(cultivator.name) 已无法再入红尘历练。",
                    importance: 2
                )
            ]
        }

        worldTick(world)
        if let deathEvent = advanceAge(for: cultivator, in: world) {
            return [deathEvent]
        }

        var events: [GameEvent] = []
        let baseQi = qiGain(for: cultivator, in: world) * Double.random(in: 0.35...0.75)
        cultivator.qi = min(cultivator.qi + baseQi, cultivator.maxQi * 1.2)

        let stones = Int.random(in: 3...18)
        cultivator.spiritStone += stones
        events.append(
            GameEvent(
                year: world.year,
                title: "外出历练",
                detail: "\(cultivator.name) 行过坊市与荒山，得灵石 \(stones) 枚，也见识了人间修真百态。"
            )
        )

        if let event = randomEvent(cultivator: cultivator, world: world, forced: true) {
            events.append(event)
        }

        if cultivator.qi >= cultivator.maxQi {
            events.append(tryBreakthrough(cultivator: cultivator, world: world))
        }

        return events
    }

    static func tryBreakthrough(cultivator: Cultivator, world: WorldState) -> GameEvent {
        guard cultivator.isAlive else {
            return GameEvent(year: world.year, title: "道途已止", detail: "肉身既灭，境界再无可进。", importance: 2)
        }

        guard !cultivator.hasReachedPeak else {
            cultivator.qi = cultivator.maxQi
            cultivator.title = "道祖"
            return GameEvent(
                year: world.year,
                title: "道尽于此",
                detail: "\(cultivator.name) 已立于万道之巅，天地再无更高境界。",
                importance: 3
            )
        }

        let comprehension = Double(cultivator.comprehension) / 100
        let luck = Double(cultivator.luck) / 100
        let fortune = world.fortune / 100
        let aura = world.aura / 100
        let threatPenalty = world.demonicThreat / 360
        let realmDifficulty = min(cultivator.realm.multiplier / 130, 0.36)
        let baseChance = 0.36 + comprehension * 0.22 + luck * 0.16 + fortune * 0.16 + aura * 0.08
        let successChance = clamp(baseChance - realmDifficulty - threatPenalty, lower: 0.08, upper: 0.92)

        if Double.random(in: 0...1) <= successChance {
            let previousRealmText = cultivator.realmText
            advanceRealm(for: cultivator)
            cultivator.qi = max(0, cultivator.qi - cultivator.maxQi * 0.28)
            cultivator.title = title(for: cultivator)
            world.sectReputation = clamp(world.sectReputation + Double.random(in: 2...8), lower: 0, upper: 100)
            world.fortune = clamp(world.fortune + Double.random(in: 0.5...3.0), lower: 0, upper: 100)

            return GameEvent(
                year: world.year,
                title: "闭关突破",
                detail: "\(cultivator.name) 自 \(previousRealmText) 破境而上，踏入 \(cultivator.realmText)，道号渐闻于世。",
                importance: cultivator.stage == 1 ? 3 : 2
            )
        }

        let setback = Double.random(in: 0.28...0.58)
        cultivator.qi = max(cultivator.qi * (1 - setback), 0)

        if Int.random(in: 1...100) <= 22 {
            let injuryYears = Int.random(in: 1...8)
            cultivator.lifespan = max(cultivator.age + 1, cultivator.lifespan - injuryYears)
            return GameEvent(
                year: world.year,
                title: "破境受挫",
                detail: "\(cultivator.name) 冲关时真气逆行，折损寿元 \(injuryYears) 年，只得闭目调息以稳道基。",
                importance: 2
            )
        }

        return GameEvent(
            year: world.year,
            title: "破境未成",
            detail: "\(cultivator.name) 叩问瓶颈未果，灵气散入经脉，所幸根基尚稳。"
        )
    }

    static func worldTick(_ world: WorldState) {
        world.year += 1
        world.aura = clamp(world.aura + Double.random(in: -2.2...2.4), lower: 1, upper: 100)
        world.fortune = clamp(world.fortune + Double.random(in: -2.0...2.0), lower: 1, upper: 100)
        world.demonicThreat = clamp(world.demonicThreat + Double.random(in: -1.8...2.6), lower: 0, upper: 100)
        world.sectReputation = clamp(world.sectReputation + Double.random(in: -1.2...2.0), lower: 0, upper: 100)

        if Int.random(in: 1...1000) <= 12 {
            world.currentEra = randomEra(world: world)
        }
    }

    static func randomEvent(cultivator: Cultivator, world: WorldState, forced: Bool = false) -> GameEvent? {
        let eventRoll = Int.random(in: 1...100)
        guard forced || eventRoll <= 24 else { return nil }

        let type = Int.random(in: 1...7)
        switch type {
        case 1:
            let qi = Double.random(in: 15...45) * cultivator.realm.multiplier
            cultivator.qi = min(cultivator.qi + qi, cultivator.maxQi * 1.25)
            cultivator.luck = min(cultivator.luck + Int.random(in: 1...3), 100)
            return GameEvent(
                year: world.year,
                title: "山中奇遇",
                detail: "\(cultivator.name) 于古松下得一缕先天清气，灵台澄澈，修为暗涨。"
            )
        case 2:
            let stones = Int.random(in: 18...90)
            cultivator.spiritStone += stones
            return GameEvent(
                year: world.year,
                title: "秘境开启",
                detail: "荒岭现出短暂秘境，\(cultivator.name) 采得灵草与灵石，共计 \(stones) 枚。",
                importance: 2
            )
        case 3:
            let stones = Int.random(in: 8...42)
            cultivator.spiritStone += stones
            return GameEvent(
                year: world.year,
                title: "灵石入囊",
                detail: "\(cultivator.name) 在坊市替人护法，得灵石 \(stones) 枚。"
            )
        case 4:
            let wound = Int.random(in: 1...6)
            let qiLoss = cultivator.maxQi * Double.random(in: 0.05...0.18)
            cultivator.lifespan = max(cultivator.age + 1, cultivator.lifespan - wound)
            cultivator.qi = max(cultivator.qi - qiLoss, 0)
            world.demonicThreat = clamp(world.demonicThreat + Double.random(in: 1...5), lower: 0, upper: 100)
            return GameEvent(
                year: world.year,
                title: "妖兽袭山",
                detail: "\(cultivator.name) 斩退山魈，却也伤及根本，折寿 \(wound) 年。",
                importance: 2
            )
        case 5:
            let gain = Int.random(in: 2...7)
            cultivator.comprehension = min(cultivator.comprehension + gain, 100)
            cultivator.qi = min(cultivator.qi + cultivator.maxQi * 0.22, cultivator.maxQi * 1.25)
            return GameEvent(
                year: world.year,
                title: "一朝顿悟",
                detail: "\(cultivator.name) 观雨落檐前，忽明一线天机，悟性提升 \(gain) 点。",
                importance: 2
            )
        case 6:
            let pressure = Int.random(in: 2...10)
            world.fortune = clamp(world.fortune - Double(pressure), lower: 1, upper: 100)
            world.aura = clamp(world.aura + Double.random(in: 2...7), lower: 1, upper: 100)
            return GameEvent(
                year: world.year,
                title: "天劫异象",
                detail: "远天雷云垂落，疑有大能渡劫。天地气运震荡，灵气却一时翻涌。",
                importance: 3
            )
        default:
            let gain = Int.random(in: 1...5)
            cultivator.talent = min(cultivator.talent + gain, 100)
            cultivator.spiritStone += Int.random(in: 10...55)
            return GameEvent(
                year: world.year,
                title: "古修遗迹",
                detail: "\(cultivator.name) 在山谷中发现残缺玉简，资质受古法洗练，天赋提升 \(gain) 点。",
                importance: 3
            )
        }
    }

    private static func advanceAge(for cultivator: Cultivator, in world: WorldState) -> GameEvent? {
        cultivator.age += 1
        if cultivator.age >= cultivator.lifespan {
            cultivator.isAlive = false
            return GameEvent(
                year: world.year,
                title: "寿元耗尽",
                detail: "\(cultivator.name) 未能再破生死玄关，于 \(cultivator.age) 岁坐化洞府。",
                importance: 3
            )
        }
        return nil
    }

    private static func advanceRealm(for cultivator: Cultivator) {
        if cultivator.stage < 9 {
            cultivator.stage += 1
        } else if let nextRealm = cultivator.realm.next {
            cultivator.realm = nextRealm
            cultivator.stage = 1
        }
        cultivator.refreshCultivationLimit()
    }

    private static func qiGain(for cultivator: Cultivator, in world: WorldState) -> Double {
        let talentFactor = Double(cultivator.talent) / 70
        let comprehensionFactor = Double(cultivator.comprehension) / 95
        let auraFactor = max(world.aura, 1) / 50
        let physiqueFactor = Double(cultivator.physique) / 120
        let realmFactor = max(0.8, 2.4 - cultivator.realm.multiplier / 96)
        return (8 + talentFactor * 10 + comprehensionFactor * 6 + physiqueFactor * 5) * auraFactor * realmFactor
    }

    private static func title(for cultivator: Cultivator) -> String {
        switch cultivator.realm {
        case .mortal: "凡俗"
        case .qiRefining: "入道散修"
        case .foundation: "筑基修士"
        case .goldenCore: "金丹真人"
        case .nascentSoul: "元婴老祖"
        case .spiritSevering: "化神尊者"
        case .voidRefining: "炼虚大修"
        case .integration: "合体真君"
        case .mahayana: "大乘圣君"
        case .tribulation: "渡劫天尊"
        case .trueImmortal: "真仙"
        case .mysteriousImmortal: "玄仙上人"
        case .goldenImmortal: "金仙"
        case .taiyiGoldenImmortal: "太乙金仙"
        case .greatLuoGoldenImmortal: "大罗金仙"
        case .daoAncestor: "道祖"
        }
    }

    private static func randomEra(world: WorldState) -> String {
        if world.demonicThreat > 72 {
            return ["魔潮纪", "血月纪", "妖祸纪"].randomElement() ?? "魔潮纪"
        }

        if world.aura > 76 && world.fortune > 62 {
            return ["灵气复苏纪", "万宗竞秀纪", "仙苗纪"].randomElement() ?? "灵气复苏纪"
        }

        if world.fortune < 28 {
            return ["末法余晖纪", "天衰纪", "寒山纪"].randomElement() ?? "末法余晖纪"
        }

        return ["开山纪", "群峰纪", "游仙纪", "宗门纪"].randomElement() ?? "开山纪"
    }

    private static func clamp(_ value: Double, lower: Double, upper: Double) -> Double {
        min(max(value, lower), upper)
    }
}
