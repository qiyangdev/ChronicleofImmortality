import Foundation
import SwiftData

@Model
final class SaveMetadata {
    var saveVersion: Int
    var createdAt: Date
    var lastPlayedAt: Date
    var worldAge: Int
    var seed: Int

    init(saveVersion: Int, createdAt: Date = .now, lastPlayedAt: Date = .now, worldAge: Int, seed: Int) {
        self.saveVersion = saveVersion
        self.createdAt = createdAt
        self.lastPlayedAt = lastPlayedAt
        self.worldAge = worldAge
        self.seed = seed
    }
}
