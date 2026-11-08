import Foundation

// MARK: - iOS-specific UI types
// PetState itself is defined in Shared/PetState.swift

/// Stat bar data for display
struct StatBar: Identifiable {
    let id = UUID()
    let label: String
    let icon: String
    let value: Double  // 0-100
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
