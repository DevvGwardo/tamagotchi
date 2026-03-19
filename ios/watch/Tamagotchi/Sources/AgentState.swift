import SwiftUI
import WatchKit

// MARK: - Agent State

/// Maps agent lifecycle to sprite animations, particles, and haptics
enum AgentState: String, CaseIterable {
    case idle
    case sending
    case thinking
    case responding
    case error

    /// Mood string for SmartSpriteView animation selection
    var mood: String {
        switch self {
        case .idle:       return "idle"
        case .sending:    return "idle"      // bounce handles the visual
        case .thinking:   return "thinking"
        case .responding: return "happy"
        case .error:      return "sad"
        }
    }

    /// Whether to trigger bounce animation
    var shouldBounce: Bool {
        self == .sending
    }

    /// Particle effect for this state
    var particleTrigger: ParticleTrigger? {
        switch self {
        case .responding: return .pet  // hearts
        default:          return nil
        }
    }

    /// Haptic feedback for state transitions
    var haptic: WKHapticType? {
        switch self {
        case .sending:    return .click
        case .responding: return .success
        case .error:      return .failure
        default:          return nil
        }
    }

    /// Play the haptic associated with this state
    func playHaptic() {
        if let haptic = haptic {
            WKInterfaceDevice.current().play(haptic)
        }
    }
}
