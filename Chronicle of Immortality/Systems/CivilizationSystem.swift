import Foundation

enum CivilizationSystem {
    static func advance(world: WorldState, factions: [Faction], legacies: [Legacy]) -> [HistoryEvent] {
        var events: [HistoryEvent] = []
        let lineagePower = min(35, legacies.reduce(0) { $0 + $1.influence } / 35)
        let factionPressure = factions.reduce(0) { $0 + ($1.alignment == .demonic ? $1.influence : 0) } / 80

        let civilizationDrift = GameMath.clamp(
            world.aura / 280 + world.fortune / 360 + lineagePower / 500 - factionPressure / 40 + Double.random(in: -0.7...1.0),
            lower: -BalanceConfig.current.maxCivilizationDriftPerYear,
            upper: BalanceConfig.current.maxCivilizationDriftPerYear
        )
        world.civilizationLevel = GameMath.clamp(world.civilizationLevel + civilizationDrift, lower: 0, upper: 100)
        world.goldenAgeProgress = GameMath.clamp(
            world.goldenAgeProgress + max(0, world.aura - 55) / 50 + max(0, world.fortune - 50) / 70 - world.calamityPressure / 140,
            lower: 0,
            upper: 100
        )
        world.calamityPressure = GameMath.clamp(
            world.calamityPressure + world.demonicThreat / 180 + max(0, 40 - world.aura) / 65 + Double.random(in: -0.7...1.3),
            lower: 0,
            upper: 100
        )

        if world.goldenAgeProgress >= 100 {
            world.goldenAgeProgress = 22
            world.aura = GameMath.clamp(world.aura + 10, lower: 1, upper: 100)
            world.fortune = GameMath.clamp(world.fortune + 8, lower: 1, upper: 100)
            events.append(
                HistoryEvent(
                    year: world.year,
                    title: "黄金大世开启",
                    detail: "天骄并起，道统复明，天下进入新的黄金大世。",
                    category: .world,
                    importance: 3
                )
            )
        }

        if world.calamityPressure >= 100 {
            world.calamityPressure = 34
            world.demonicThreat = GameMath.clamp(world.demonicThreat + 12, lower: 0, upper: 100)
            world.fortune = GameMath.clamp(world.fortune - 10, lower: 1, upper: 100)
            events.append(
                HistoryEvent(
                    year: world.year,
                    title: "天地大劫降临",
                    detail: "灵机逆乱，群魔趁势而起，诸宗被迫面对新的文明劫数。",
                    category: .calamity,
                    importance: 3
                )
            )
        }

        if world.year.isMultiple(of: 2_100) {
            events.append(
                HistoryEvent(
                    year: world.year,
                    title: "文明纪元更替",
                    detail: "长生历已过 \(world.year) 年，旧人尽去，新道统成为修真文明的骨架。",
                    category: .world,
                    importance: 3
                )
            )
        }

        return events
    }
}
