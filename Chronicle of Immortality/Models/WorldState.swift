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

    init(
        year: Int = 1,
        aura: Double = 58,
        fortune: Double = 52,
        demonicThreat: Double = 18,
        sectReputation: Double = 24,
        currentEra: String = "开山纪"
    ) {
        self.year = year
        self.aura = aura
        self.fortune = fortune
        self.demonicThreat = demonicThreat
        self.sectReputation = sectReputation
        self.currentEra = currentEra
    }
}
