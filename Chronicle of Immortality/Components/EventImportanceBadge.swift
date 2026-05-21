import SwiftUI

struct EventImportanceBadge: View {
    let importance: Int

    var body: some View {
        Text(label)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12), in: Capsule())
    }

    private var label: String {
        switch importance {
        case 3: "史诗"
        case 2: "重要"
        default: "普通"
        }
    }

    private var color: Color {
        switch importance {
        case 3: .purple
        case 2: .orange
        default: .secondary
        }
    }
}
