import Foundation
import SwiftData

@Model
final class KarmaRecord {
    var source: String
    var target: String
    var reason: String
    var karmaValue: Int
    var year: Int
    var isResolved: Bool

    init(source: String, target: String, reason: String, karmaValue: Int, year: Int, isResolved: Bool = false) {
        self.source = source
        self.target = target
        self.reason = reason
        self.karmaValue = karmaValue
        self.year = year
        self.isResolved = isResolved
    }

    var relationshipText: String {
        if karmaValue > 0 { return "恩情" }
        if karmaValue < 0 { return "仇怨" }
        return "因缘"
    }
}
