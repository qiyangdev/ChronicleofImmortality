import Foundation

enum GameMath {
    static func clamp(_ value: Double, lower: Double, upper: Double) -> Double {
        min(max(value, lower), upper)
    }

    static func chance(_ percent: Double) -> Bool {
        Double.random(in: 0...100) <= percent
    }
}
