import SwiftData
import SwiftUI

struct NewGameView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("立传") {
                    TextField("道号或本名", text: $name)
                        .textInputAutocapitalization(.never)

                    Button {
                        createGame()
                    } label: {
                        Label("开辟长生历", systemImage: "sparkles")
                    }
                    .disabled(trimmedName.isEmpty)
                }

                Section("卷首") {
                    Text("天地初启，山门未兴。你将在漫长岁月中闭关、历练、破境，并见证修真文明的起落。")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("长生历")
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func createGame() {
        let cultivator = Cultivator(name: trimmedName)
        let world = WorldState()
        let event = GameEvent(
            year: world.year,
            title: "长生历开卷",
            detail: "\(cultivator.name) 入山求道，自此闭关修炼，问鼎长生。",
            importance: 3
        )

        modelContext.insert(cultivator)
        modelContext.insert(world)
        modelContext.insert(event)
    }
}
