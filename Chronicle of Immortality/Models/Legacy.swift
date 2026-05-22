import Foundation
import SwiftData

@Model
final class Legacy {
    var founder: String
    var faction: String
    var technique: String
    var createdYear: Int
    var influence: Double
    var descendants: Int

    init(founder: String, faction: String, technique: String, createdYear: Int, influence: Double, descendants: Int = 0) {
        self.founder = founder
        self.faction = faction
        self.technique = technique
        self.createdYear = createdYear
        self.influence = influence
        self.descendants = descendants
    }
}
