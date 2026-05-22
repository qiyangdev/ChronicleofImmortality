import Foundation

struct GameEngineResult {
    var gameEvents: [GameEvent]
    var historyEvents: [HistoryEvent]
    var shouldStopAction: Bool

    init(gameEvents: [GameEvent] = [], historyEvents: [HistoryEvent] = [], shouldStopAction: Bool = false) {
        self.gameEvents = gameEvents
        self.historyEvents = historyEvents
        self.shouldStopAction = shouldStopAction
    }

    mutating func append(_ result: GameEngineResult) {
        gameEvents.append(contentsOf: result.gameEvents)
        historyEvents.append(contentsOf: result.historyEvents)
        shouldStopAction = shouldStopAction || result.shouldStopAction
    }
}
