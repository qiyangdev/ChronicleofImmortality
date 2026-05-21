import Foundation

extension Double {
    var wholeNumberText: String {
        formatted(.number.precision(.fractionLength(0)))
    }

    var percentText: String {
        formatted(.number.precision(.fractionLength(0))) + "%"
    }
}
