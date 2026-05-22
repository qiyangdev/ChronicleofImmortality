import Foundation

struct BalanceConfig {
    nonisolated static let current = BalanceConfig()

    let cultivationMultiplier: Double = 0.58
    let spiritStoneYieldMultiplier: Double = 0.82
    let breakthroughChanceMultiplier: Double = 0.62
    let npcGrowthMultiplier: Double = 0.42
    let factionExpansionMultiplier: Double = 0.55
    let worldAuraChangeMultiplier: Double = 0.62
    let techniqueEffectMultiplier: Double = 0.85
    let lifespanMultiplier: Double = 1.0
    let explorationRewardMultiplier: Double = 0.68

    let batchYieldInterval: Int = 25
    let maxHistoryEventsPerBatch: Int = 80
    let maxGameEventsPerBatch: Int = 24
    let maxVisibleTimelineEntries: Int = 240
    let majorEventMinimumImportance: Int = 3
    let lowValueEventFoldSize: Int = 12
    let eventCooldownYears: Int = 35
    let maxFactionInfluenceChangePerYear: Double = 3.2
    let maxCivilizationDriftPerYear: Double = 1.6
    let maxNPCRealmForAmbientGrowth: Realm = .tribulation

    let seclusionOpportunityThreshold: Double = 0.68
    let seclusionQiMultiplier: Double = 1.12
    let seclusionHeartDemonBaseRisk: Double = 0.35
    let seclusionForcedExitBaseRisk: Double = 0.18
    let forcedExitSeverePenaltyChance: Double = 18

    let oldAgeDeclineStartRatio: Double = 0.68
    let playerOldAgeQiPenaltyMax: Double = 0.62
    let playerOldAgeBreakthroughPenaltyMax: Double = 0.3
    let npcOldAgeQiPenaltyMax: Double = 0.72
    let npcOldAgeBreakthroughPenaltyMax: Double = 36
    let desperateBreakthroughDeathChance: Double = 22
    let lifespanWarningRatio: Double = 0.12

    let minorBreakthroughBaseChance: Double = 0.2
    let majorBreakthroughBaseChance: Double = 0.11
    let majorRealmBreakthroughPenalty: Double = 0.18
    let stageBreakthroughPenaltyMax: Double = 0.24
    let highRealmStagePenaltyMultiplier: Double = 0.12
    let breakthroughOverflowBonusMax: Double = 0.1
    let randomCultivationEventChance: Double = 8
    let randomQiEventMultiplier: Double = 0.34

    let techniqueDiscoveryMultiplier: Double = 0.55
    let highRarityTechniqueDiscoveryPenalty: Double = 0.42
    let movementTechniqueRiskReduction: Double = 0.16
    let regionSealBypassRiskPenalty: Double = 18

    let daoFoundationQiMultiplierMax: Double = 0.28
    let daoFoundationBreakthroughMultiplierMax: Double = 0.18
    let daoFoundationRecoveryPerQuietYear: Double = 0.16
    let daoFoundationFailureLoss: Double = 4
    let daoFoundationForcedExitLoss: Double = 14
    let demonicTechniqueDaoLossChance: Double = 5

    let caveLeaseCost: Int = 80
    let caveLeaseYears: Int = 12
    let caveAuraBonus: Double = 18
    let protectorCost: Int = 120
    let protectorYears: Int = 10
    let protectorRiskReduction: Double = 0.45
    let fragmentCost: Int = 90
    let sectDonationCost: Int = 150

    let npcPopulationTarget: Int = 42
    let npcPopulationHardCap: Int = 76
    let npcBirthBaseChance: Double = 16
    let npcGoldenAgeTalentBonus: Int = 12
    let regionStateChance: Double = 2.4
    let regionStateDurationRange: ClosedRange<Int> = 12...80
    let techniqueMasteryGain: Double = 4
}
