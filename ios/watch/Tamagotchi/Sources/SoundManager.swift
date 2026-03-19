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
        case "eating":
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
    func playAction(_ action: WatchPetAction) {
        switch action {
        case .feed:
            WKInterfaceDevice.current().play(.click)
        case .play:
            WKInterfaceDevice.current().play(.success)
        case .sleep:
            WKInterfaceDevice.current().play(.directionDown)
        case .pet:
            WKInterfaceDevice.current().play(.success)
        }
    }
}

// MARK: - Pet State Machine

/// Manages automatic animation state transitions
class PetStateMachine: ObservableObject {
    @Published var currentState: PetState = .idle
    @Published var previousState: PetState = .idle
    @Published var transitionProgress: Double = 1.0
    
    enum PetState: String, CaseIterable {
        case idle, happy, eating, sleeping, sad, dead
        
        var animation: SpriteAnimation {
            switch self {
            case .idle: return .idle
            case .happy: return .happy
            case .eating: return .eating
            case .sleeping: return .sleeping
            case .sad: return .sad
            case .dead: return .dead
            }
        }
    }
    
    private var transitionTimer: Timer?
    
    /// Transition to a new state with optional blending
    func transition(to newState: PetState, blendDuration: TimeInterval = 0.3) {
        guard newState != currentState else { return }
        
        previousState = currentState
        currentState = newState
        transitionProgress = 0.0
        
        // Animate transition progress
        let startTime = Date()
        transitionTimer?.invalidate()
        transitionTimer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            let elapsed = Date().timeIntervalSince(startTime)
            self.transitionProgress = min(1.0, elapsed / blendDuration)
            
            if self.transitionProgress >= 1.0 {
                timer.invalidate()
            }
        }
    }
    
    /// Get current animation with blend factor
    func currentAnimation() -> (from: SpriteAnimation, to: SpriteAnimation, blend: Double) {
        return (previousState.animation, currentState.animation, transitionProgress)
    }
    
    /// Auto-transition based on pet stats
    func updateFromStats(hunger: Double, happiness: Double, energy: Double, health: Double) {
        if health <= 0 {
            transition(to: .dead)
            return
        }
        
        if energy < 10 {
            transition(to: .sleeping)
            return
        }
        
        let avg = (hunger + happiness + health) / 3
        
        if avg >= 75 {
            transition(to: .happy)
        } else if avg >= 40 {
            transition(to: .idle)
        } else {
            transition(to: .sad)
        }
    }
}

// MARK: - Blended Sprite View

/// Displays two animations blended together during transitions
struct BlendedSpriteView: View {
    @StateObject private var stateMachine = PetStateMachine()
    let mood: String
    let triggerBounce: Bool
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Previous state (fading out)
            if stateMachine.transitionProgress < 1.0 {
                spriteView(for: stateMachine.previousState)
                    .opacity(1.0 - stateMachine.transitionProgress)
            }
            
            // Current state (fading in)
            spriteView(for: stateMachine.currentState)
                .opacity(stateMachine.transitionProgress)
        }
        .onAppear {
            updateStateFromMood()
        }
        .onChange(of: mood) { _ in
            updateStateFromMood()
        }
    }
    
    private func updateStateFromMood() {
        let newState: PetStateMachine.PetState
        switch mood {
        case "dead": newState = .dead
        case "sleeping": newState = .sleeping
        case "eating": newState = .eating
        case "sad", "miserable": newState = .sad
        case "happy", "ecstatic": newState = .happy
        default: newState = .idle
        }
        stateMachine.transition(to: newState)
    }
    
    private func spriteView(for state: PetStateMachine.PetState) -> some View {
        // Reuse existing sprite view
        CanvasSpriteView(mood: state.rawValue, size: size)
    }
}
