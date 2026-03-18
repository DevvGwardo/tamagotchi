import Foundation

/// Shared PetState — mirrors shared/types.ts
struct PetState: Codable, Equatable {
    var id: String
    var name: String
    var hunger: Double
    var happiness: Double
    var energy: Double
    var xp: Double
    var health: Double
    var mood: String
    var skin: String
    var lastUpdated: TimeInterval

    static let initial = PetState(
        id: UUID().uuidString,
        name: "Clawbert",
        hunger: 80,
        happiness: 80,
        energy: 100,
        xp: 0,
        health: 100,
        mood: "happy",
        skin: "default",
        lastUpdated: Date().timeIntervalSince1970
    )

    var moodEmoji: String {
        switch mood {
        case "ecstatic": return "🤩"
        case "happy":    return "😊"
        case "content":  return "🙂"
        case "neutral":  return "😐"
        case "sad":      return "😢"
        case "miserable":return "😭"
        case "sleeping": return "😴"
        case "eating":   return "😋"
        default:         return "😐"
        }
    }

    var barColor: String {
        if hunger < 20 || happiness < 20 || health < 20 { return "red" }
        if hunger < 40 || happiness < 40 { return "orange" }
        return "green"
    }
}

/// Stat bar data for display
struct StatBar: Identifiable {
    let id = UUID()
    let label: String
    let icon: String
    let value: Double  // 0–100
}

/// Action that can be performed on the pet
enum PetAction: String, CaseIterable, Identifiable {
    case feed  = "Feed"
    case play  = "Play"
    case sleep = "Sleep"
    case pet   = "Pet"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .feed:  return "🍖"
        case .play:  return "🎾"
        case .sleep: return "💤"
        case .pet:   return "🤚"
        }
    }

    var energyCost: Double {
        switch self {
        case .feed:  return 0
        case .play:  return -10
        case .sleep: return 0
        case .pet:   return 0
        }
    }

    var delta: (hunger: Double, happiness: Double, energy: Double, xp: Double) {
        switch self {
        case .feed:  return (30,  5,  0, 5)
        case .play:  return (0,  25, -10, 10)
        case .sleep: return (-5,  0, 50, 5)
        case .pet:   return (0,  10,  0, 2)
        }
    }
}
