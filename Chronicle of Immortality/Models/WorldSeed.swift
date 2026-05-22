import Foundation
import SwiftData

@Model
final class WorldSeed {
    var seed: Int
    var initialAura: Double
    var demonicRate: Double
    var fortuneBias: Double
    var factionDistribution: String
    var resourceDensity: Double

    init(
        seed: Int,
        initialAura: Double,
        demonicRate: Double,
        fortuneBias: Double,
        factionDistribution: String,
        resourceDensity: Double
    ) {
        self.seed = seed
        self.initialAura = initialAura
        self.demonicRate = demonicRate
        self.fortuneBias = fortuneBias
        self.factionDistribution = factionDistribution
        self.resourceDensity = resourceDensity
    }

    var worldTendencyText: String {
        if demonicRate > 70 { return "魔道极盛" }
        if initialAura > 72 && fortuneBias > 60 { return "黄金大世" }
        if initialAura < 34 { return "末法寒世" }
        if factionDistribution.contains("妖族") { return "妖族横行" }
        return "诸宗并立"
    }
}
