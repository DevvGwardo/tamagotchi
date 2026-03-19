import SwiftUI
import WatchKit

@main
struct TamagotchiWatchApp: App {
    var body: some Scene {
        WindowGroup {
            MinimalCharacterView()
        }
    }
}

// MARK: - Minimal Character View (Just the sprite)

struct MinimalCharacterView: View {
    @State private var pet = WatchPetState.initial
    @State private var isDead = false
    @State private var decayingTick = false
    
    private let decayInterval: TimeInterval = 30
    
    var body: some View {
        ZStack {
            if isDead {
                // Dead state - static dead sprite
                SmartSpriteView(mood: "dead", triggerBounce: false, size: 60)
                    .onTapGesture { revive() }
            } else {
                // Live character - full screen sprite
                SmartSpriteView(mood: pet.mood, triggerBounce: false, size: 60)
                    .onTapGesture { 
                        // Cycle through moods on tap for demo
                        cycleMood()
                        WKInterfaceDevice.current().play(.click)
                    }
            }
        }
        .onAppear { 
            loadPet()
            startDecay()
        }
    }
    
    // MARK: - Mood Cycling (for interaction)
    
    private func cycleMood() {
        let moods = ["idle", "happy", "eating", "sleeping", "sad"]
        if let currentIndex = moods.firstIndex(of: pet.mood),
           currentIndex + 1 < moods.count {
            pet.mood = moods[currentIndex + 1]
        } else {
            pet.mood = "idle"
        }
        pet.lastUpdated = Date().timeIntervalSince1970
        savePet()
    }
    
    // MARK: - Stat Decay
    
    private func startDecay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + decayInterval) {
            applyDecay()
            Timer.scheduledTimer(withTimeInterval: decayInterval, repeats: true) { _ in
                applyDecay()
            }
        }
    }
    
    private func applyDecay() {
        guard !isDead else { return }
        decayingTick = true
        pet.hunger = clamp(pet.hunger - 1)
        pet.happiness = clamp(pet.happiness - 0.5)
        updateMoodFromStats()
        if pet.hunger <= 0 || pet.health <= 0 { isDead = true }
        savePet()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { decayingTick = false }
    }
    
    private func updateMoodFromStats() {
        if pet.energy < 10 { pet.mood = "sleeping"; return }
        let avg = (pet.hunger + pet.happiness + pet.health) / 3
        if avg >= 75 { pet.mood = "happy" }
        else if avg >= 40 { pet.mood = "idle" }
        else { pet.mood = "sad" }
    }
    
    private func revive() {
        pet = WatchPetState.initial
        isDead = false
        savePet()
    }
    
    private func clamp(_ v: Double) -> Double { max(0, min(100, v)) }
    
    // MARK: - Persistence
    
    private func savePet() {
        if let data = try? JSONEncoder().encode(pet) {
            UserDefaults.standard.set(data, forKey: "clawbert_watch")
        }
    }
    
    private func loadPet() {
        if let data = UserDefaults.standard.data(forKey: "clawbert_watch"),
           let saved = try? JSONDecoder().decode(WatchPetState.self, from: data) {
            pet = saved
            isDead = (pet.health <= 0 || pet.hunger <= 0)
        }
    }
}

// MARK: - Simplified Pet State

struct WatchPetState: Codable {
    var name: String
    var hunger: Double
    var happiness: Double
    var energy: Double
    var health: Double
    var mood: String
    var lastUpdated: TimeInterval
    
    static let initial = WatchPetState(
        name: "Clawbert",
        hunger: 80,
        happiness: 80,
        energy: 100,
        health: 100,
        mood: "idle",
        lastUpdated: Date().timeIntervalSince1970
    )
}

#Preview {
    MinimalCharacterView()
}
