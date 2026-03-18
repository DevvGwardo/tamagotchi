import SwiftUI
import WatchKit

@main
struct TamagotchiWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchContentView()
        }
    }
}

struct WatchContentView: View {
    @State private var pet = WatchPetState.initial
    @State private var animating = false
    @State private var feedback = ""
    @State private var showingDeath = false

    var body: some View {
        if showingDeath {
            DeathView(onRevive: revive)
        } else {
            mainView
        }
    }

    private var mainView: some View {
        VStack(spacing: 6) {
            // Character
            WatchPetCharacter(mood: pet.mood, animating: animating)

            // Name + Mood
            Text(pet.name)
                .font(.caption2.bold())
            Text(moodEmoji)
                .font(.title2)

            // Stats (compact)
            HStack(spacing: 4) {
                MiniBar(label: "🍖", value: pet.hunger)
                MiniBar(label: "😊", value: pet.happiness)
                MiniBar(label: "⚡", value: pet.energy)
            }
            .padding(.horizontal, 2)

            // Actions
            HStack(spacing: 6) {
                ForEach(WatchPetAction.allCases) { action in
                    Button(action: { performAction(action) }) {
                        Text(action.emoji)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                }
            }

            if !feedback.isEmpty {
                Text(feedback)
                    .font(.caption2)
                    .foregroundColor(.yellow)
            }
        }
        .padding(4)
        .onAppear { loadPet() }
    }

    private var moodEmoji: String {
        switch pet.mood {
        case "ecstatic":  return "🤩"
        case "happy":     return "😊"
        case "content":   return "🙂"
        case "neutral":   return "😐"
        case "sad":       return "😢"
        case "miserable": return "😭"
        case "sleeping":  return "😴"
        case "eating":    return "😋"
        default:         return "😐"
        }
    }

    private func performAction(_ action: WatchPetAction) {
        let delta = action.delta
        withAnimation(.easeInOut(duration: 0.3)) {
            pet.hunger    = min(100, max(0, pet.hunger    + delta.hunger))
            pet.happiness = min(100, max(0, pet.happiness + delta.happiness))
            pet.energy    = min(100, max(0, pet.energy    + delta.energy))
            pet.xp        = pet.xp + delta.xp
            pet.mood      = deriveMood()
            animating = true
        }
        feedback = "\(action.emoji)!"
        WKInterfaceDevice.current().play(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            feedback = ""; animating = false
        }
        checkCritical()
        savePet()
    }

    private func deriveMood() -> String {
        if pet.energy < 10 { return "sleeping" }
        let avg = (pet.hunger + pet.happiness + pet.health) / 3
        if avg >= 90 { return "ecstatic" }
        if avg >= 75 { return "happy" }
        if avg >= 60 { return "content" }
        if avg >= 40 { return "neutral" }
        if avg >= 20 { return "sad" }
        return "miserable"
    }

    private func checkCritical() {
        if pet.hunger <= 0 || pet.health <= 0 {
            showingDeath = true
            let deaths = UserDefaults.standard.integer(forKey: "clawbert_deaths")
            UserDefaults.standard.set(deaths + 1, forKey: "clawbert_deaths")
        }
    }

    private func revive() {
        pet = WatchPetState.initial
        showingDeath = false
        savePet()
    }

    private func savePet() {
        if let data = try? JSONEncoder().encode(pet) {
            UserDefaults.standard.set(data, forKey: "clawbert_watch")
        }
    }

    private func loadPet() {
        if let data = UserDefaults.standard.data(forKey: "clawbert_watch"),
           let saved = try? JSONDecoder().decode(WatchPetState.self, from: data) {
            pet = saved
            checkCritical()
        }
    }
}

// ── Watch Pet State ──────────────────────────────────────────────────────────

struct WatchPetState: Codable {
    var name: String
    var hunger: Double
    var happiness: Double
    var energy: Double
    var xp: Double
    var health: Double
    var mood: String

    static let initial = WatchPetState(
        name: "Clawbert",
        hunger: 80,
        happiness: 80,
        energy: 100,
        xp: 0,
        health: 100,
        mood: "happy"
    )
}

enum WatchPetAction: String, CaseIterable, Identifiable {
    case feed = "Feed"
    case play = "Play"
    case sleep = "Sleep"
    case pet = "Pet"
    var id: String { rawValue }
    var emoji: String {
        switch self {
        case .feed:  return "🍖"
        case .play:  return "🎾"
        case .sleep: return "💤"
        case .pet:   return "🤚"
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

// ── Mini Stat Bar ─────────────────────────────────────────────────────────────

struct MiniBar: View {
    let label: String
    let value: Double
    private var color: Color {
        if value < 20 { return .red }
        if value < 40 { return .orange }
        return .green
    }
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10))
            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 2).fill(Color.gray.opacity(0.3))
                    RoundedRectangle(cornerRadius: 2).fill(color)
                        .frame(height: geo.size.height * CGFloat(value / 100))
                }
            }
            .frame(width: 24, height: 30)
        }
    }
}

// ── Watch Pet Character ───────────────────────────────────────────────────────

struct WatchPetCharacter: View {
    let mood: String
    let animating: Bool
    private var sprite: String {
        switch mood {
        case "ecstatic":  return "🤩"
        case "happy":     return "😺"
        case "content":  return "😸"
        case "neutral":   return "😼"
        case "sad":       return "😿"
        case "miserable":return "🙀"
        case "sleeping": return "😴"
        case "eating":   return "😻"
        default:         return "🐱"
        }
    }
    var body: some View {
        Text(sprite)
            .font(.system(size: animating ? 38 : 34))
            .animation(.spring(response: 0.3), value: animating)
    }
}

// ── Death View ───────────────────────────────────────────────────────────────

struct DeathView: View {
    let onRevive: () -> Void
    var body: some View {
        VStack(spacing: 12) {
            Text("💀")
                .font(.system(size: 50))
            Text("Clawbert has\npassed away...")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Button("Revive") { onRevive() }
                .buttonStyle(.borderedProminent)
                .tint(.red)
        }
        .padding()
    }
}

#Preview {
    WatchContentView()
}
