import Foundation

// MARK: - Achievement

struct Achievement: Codable, Equatable, Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
}

// MARK: - Pet State

/// Unified pet state shared between iOS and watchOS via WatchConnectivity.
/// This is the single source of truth — both platforms use this exact struct.
struct PetState: Codable, Equatable {
    // Identity
    var id: String
    var name: String

    // Stats (0–100)
    var hunger: Double
    var happiness: Double
    var energy: Double
    var health: Double
    var xp: Double

    // Appearance & mood
    var mood: String
    var skin: String

    // Timestamps
    var lastFed: Date
    var lastPlayed: Date
    var lastPet: Date
    var lastCheckTime: Date
    var lastSeen: Date
    var lastCelebration: Date
    var lastUpdated: Date
    var createdAt: Date
    var sessionStartTime: Date

    // Behaviour
    var isSleeping: Bool
    var boredomLevel: Int
    var neglectStreak: Int
    var perfectDayStreak: Int

    // Progress
    var achievements: [Achievement]
    var celebratedMilestones: [Int]
    var tasksCompleted: Int
    var totalErrorsSeen: Int
    var timeTogetherMinutes: Int

    // MARK: - Defaults

    static let `default` = PetState(
        id: UUID().uuidString,
        name: "Hermes",
        hunger: 80,
        happiness: 85,
        energy: 100,
        health: 90,
        xp: 0,
        mood: "neutral",
        skin: "default",
        lastFed: Date(),
        lastPlayed: Date(),
        lastPet: Date(),
        lastCheckTime: Date(),
        lastSeen: Date(),
        lastCelebration: Date(),
        lastUpdated: Date(),
        createdAt: Date(),
        sessionStartTime: Date(),
        isSleeping: false,
        boredomLevel: 0,
        neglectStreak: 0,
        perfectDayStreak: 0,
        achievements: [],
        celebratedMilestones: [],
        tasksCompleted: 0,
        totalErrorsSeen: 0,
        timeTogetherMinutes: 0
    )

    /// Legacy alias used by iOS views
    static let initial = `default`

    // MARK: - Computed

    var wellbeing: Double {
        (hunger + happiness + energy + health) / 4
    }

    var displayMood: String {
        if isSleeping { return "sleeping" }
        if health < 30 { return "dead" }
        if happiness > 80 { return "happy" }
        if happiness < 30 || hunger < 30 { return "sad" }
        return "idle"
    }

    var moodEmoji: String {
        switch mood {
        case "ecstatic":  return "🤩"
        case "happy":     return "😊"
        case "content":   return "🙂"
        case "neutral":   return "😐"
        case "sad":       return "😢"
        case "miserable": return "😭"
        case "sleeping":  return "😴"
        case "eating":    return "😋"
        default:          return "😐"
        }
    }

    var barColor: String {
        if hunger < 20 || happiness < 20 || health < 20 { return "red" }
        if hunger < 40 || happiness < 40 { return "orange" }
        return "green"
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
        case .syncing:  return "yellow"
        case .synced:   return "green"
        case .offline:  return "gray"
        case .error:    return "red"
        }
    }
}

// MARK: - WatchConnectivity Serialisation Helpers

enum SyncKey {
    static let petState = "petState"
    static let lastUpdated = "lastUpdated"
    static let source = "source"
    static let messageType = "messageType"
}

enum SyncError: Error {
    case missingData
    case decodingFailed
}

extension PetState {
    /// Encode into a WCSession-safe `[String: Any]` dictionary.
    func toSyncDictionary(source: String) throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(self)
        return [
            SyncKey.petState: Array(data) as [UInt8],
            SyncKey.lastUpdated: lastUpdated.timeIntervalSince1970,
            SyncKey.source: source,
            SyncKey.messageType: "stateUpdate"
        ]
    }

    /// Decode from a WCSession `[String: Any]` dictionary.
    static func fromSyncDictionary(_ dict: [String: Any]) throws -> PetState {
        guard let bytes = dict[SyncKey.petState] as? [UInt8] else {
            throw SyncError.missingData
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(PetState.self, from: Data(bytes))
    }
}
