//
//  Chronicle_of_ImmortalityApp.swift
//  Chronicle of Immortality
//
//  Created by wangqiyang on 2026/5/21.
//

import SwiftUI
import SwiftData

@main
struct Chronicle_of_ImmortalityApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [
            Cultivator.self,
            WorldState.self,
            GameEvent.self,
            HistoryEvent.self,
            NPC.self,
            Sect.self,
            Region.self,
            Technique.self,
            TechniqueKnowledge.self,
            KarmaRecord.self,
            Faction.self,
            Legacy.self,
            ReincarnationRecord.self,
            WorldSeed.self,
            SaveMetadata.self
        ])
    }
}
