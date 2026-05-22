import Foundation
import SwiftData

@Model
final class WorldState {
    var year: Int
    var aura: Double
    var fortune: Double
    var demonicThreat: Double
    var sectReputation: Double
    var currentEra: String
    var civilizationLevel: Double
    var goldenAgeProgress: Double
    var calamityPressure: Double
    var ascensionCount: Int
    var reincarnationCount: Int

    init(
        year: Int = 1,
        aura: Double = 58,
        fortune: Double = 52,
        demonicThreat: Double = 18,
        sectReputation: Double = 24,
        currentEra: String = "开山纪",
        civilizationLevel: Double = 34,
        goldenAgeProgress: Double = 12,
        calamityPressure: Double = 8,
        ascensionCount: Int = 0,
        reincarnationCount: Int = 0
    ) {
        self.year = year
        self.aura = aura
        self.fortune = fortune
        self.demonicThreat = demonicThreat
        self.sectReputation = sectReputation
        self.currentEra = currentEra
        self.civilizationLevel = civilizationLevel
        self.goldenAgeProgress = goldenAgeProgress
        self.calamityPressure = calamityPressure
        self.ascensionCount = ascensionCount
        self.reincarnationCount = reincarnationCount
    }
}
