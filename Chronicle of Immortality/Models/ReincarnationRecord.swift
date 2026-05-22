import Foundation
import SwiftData

@Model
final class ReincarnationRecord {
    var previousName: String
    var currentName: String
    var previousRealm: Realm
    var inheritance: String
    var karmaCarryOver: Int
    var year: Int

    init(previousName: String, currentName: String, previousRealm: Realm, inheritance: String, karmaCarryOver: Int, year: Int) {
        self.previousName = previousName
        self.currentName = currentName
        self.previousRealm = previousRealm
        self.inheritance = inheritance
        self.karmaCarryOver = karmaCarryOver
        self.year = year
    }
}
