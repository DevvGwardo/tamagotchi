import SwiftUI
import WatchKit

// MARK: - Sound Manager

/// Manages haptic and sound feedback synced to animations
class SoundManager {
    static let shared = SoundManager()

    private init() {}

    /// Play sound/haptic for a specific animation frame.
    /// Only fires on the first cycle of looping animations to avoid endless noise.
    private var loopingAnimationPlayed: String?

    func play(for animation: String, frame: Int) {
        // Skip haptics on looping animations after first cycle
        let looping = ["happy", "sad", "idle", "sleeping", "thinking"]
        if looping.contains(animation) {
            if frame == 0 {
                if loopingAnimationPlayed == animation { return }
                loopingAnimationPlayed = animation
            } else if loopingAnimationPlayed == animation {
                return
            }
        } else {
            loopingAnimationPlayed = nil
        }

        switch animation {
        case "bounce":
            if frame == 2 {
                WKInterfaceDevice.current().play(.click)
            }
        case "happy":
            WKInterfaceDevice.current().play(.success)
        case "eating":
            WKInterfaceDevice.current().play(.click)
        case "sad":
            WKInterfaceDevice.current().play(.directionDown)
        case "dead":
            WKInterfaceDevice.current().play(.failure)
        default:
            break
        }
    }

    /// Play action-specific feedback
    func playAction(_ action: String) {
        switch action {
        case "send":
            WKInterfaceDevice.current().play(.click)
        case "response":
            WKInterfaceDevice.current().play(.success)
        case "error":
            WKInterfaceDevice.current().play(.failure)
        default:
            break
        }
    }
}
