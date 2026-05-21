import SwiftUI

struct MetricProgressView: View {
    let title: String
    let value: Double
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            LabeledContent(title, value: value.percentText)
            ProgressView(value: value, total: 100)
                .tint(tint)
        }
    }
}
