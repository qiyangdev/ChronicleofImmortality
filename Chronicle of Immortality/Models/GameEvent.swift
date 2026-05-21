import Foundation
import SwiftData

@Model
final class GameEvent {
    var year: Int
    var title: String
    var detail: String
    var importance: Int
    var createdAt: Date

    init(year: Int, title: String, detail: String, importance: Int = 1, createdAt: Date = .now) {
        self.year = year
        self.title = title
        self.detail = detail
        self.importance = importance
        self.createdAt = createdAt
    }
}
