import Foundation

// MARK: - Achievement

struct Achievement: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
}

// MARK: - Pet State

/// Represents Clawbert's full state, matching the OpenClaw state file
struct PetState: Codable {
    var name: String
    var hunger: Int        // 0-100, higher is better
    var happiness: Int     // 0-100
    var energy: Int        // 0-100
    var health: Int        // 0-100
    var xp: Int
    var mood: String       // neutral, happy, sad, etc.
    var lastFed: Date
    var lastPlayed: Date
    var lastPet: Date
    var isSleeping: Bool
    var createdAt: Date
    var achievements: [Achievement]
    var celebratedMilestones: [Int]
    var neglectStreak: Int
    var lastCheckTime: Date
    var perfectDayStreak: Int
    var lastSeen: Date
    var sessionStartTime: Date
    var boredomLevel: Int
    var tasksCompleted: Int
    var lastCelebration: Date
    var totalErrorsSeen: Int
    var timeTogetherMinutes: Int
    
    /// Default state for new pets
    static let `default` = PetState(
        name: "Clawbert",
        hunger: 80,
        happiness: 85,
        energy: 100,
        health: 90,
        xp: 0,
        mood: "neutral",
        lastFed: Date(),
        lastPlayed: Date(),
        lastPet: Date(),
        isSleeping: false,
        createdAt: Date(),
        achievements: [],
        celebratedMilestones: [],
        neglectStreak: 0,
        lastCheckTime: Date(),
        perfectDayStreak: 0,
        lastSeen: Date(),
        sessionStartTime: Date(),
        boredomLevel: 0,
        tasksCompleted: 0,
        lastCelebration: Date(),
        totalErrorsSeen: 0,
        timeTogetherMinutes: 0
    )
    
    /// Computed property for overall wellbeing percentage
    var wellbeing: Int {
        (hunger + happiness + energy + health) / 4
    }
    
    /// Get mood as AgentState-compatible string
    var displayMood: String {
        if isSleeping { return "sleeping" }
        if health < 30 { return "dead" }
        if happiness > 80 { return "happy" }
        if happiness < 30 || hunger < 30 { return "sad" }
        return "idle"
    }
}

// MARK: - Sync Status

enum SyncStatus: Equatable {
    case syncing
    case synced(Date)
    case offline
    case error(String)
    
    var displayText: String {
        switch self {
        case .syncing:
            return "Syncing..."
        case .synced(let date):
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short
            return "Synced \(formatter.localizedString(for: date, relativeTo: Date()))"
        case .offline:
            return "Offline"
        case .error:
            return "Sync Error"
        }
    }
    
    var color: String {
        switch self {
        case .syncing:
            return "yellow"
        case .synced:
            return "green"
        case .offline:
            return "gray"
        case .error:
            return "red"
        }
    }
}
