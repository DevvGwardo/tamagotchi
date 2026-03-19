import SwiftUI
import WatchKit

// MARK: - Sound Manager

/// Manages haptic and sound feedback synced to animations
class SoundManager {
    static let shared = SoundManager()

    private init() {}

    /// Play sound/haptic for a specific animation frame
    func play(for animation: String, frame: Int) {
        switch animation {
        case "bounce":
            if frame == 2 {
                WKInterfaceDevice.current().play(.click)
            }
        case "happy":
            if frame % 2 == 0 {
                WKInterfaceDevice.current().play(.success)
            }
        case "eating", "thinking":
            WKInterfaceDevice.current().play(.click)
        case "sad":
            if frame == 0 {
                WKInterfaceDevice.current().play(.directionDown)
            }
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
