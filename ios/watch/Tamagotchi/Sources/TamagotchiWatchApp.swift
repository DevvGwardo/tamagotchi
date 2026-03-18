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

// ── Main View ────────────────────────────────────────────────────────────────

struct WatchContentView: View {
    @State private var pet = WatchPetState.initial
    @State private var animating = false
    @State private var feedback = ""
    @State private var isDead = false
    @State private var isEditingName = false
    @State private var nameInput = ""
    @State private var history: [WatchHistoryEntry] = []
    @State private var decayingTick = false

    private let decayInterval: TimeInterval = 30

    var body: some View {
        if isDead {
            DeathView(deaths: deathCount, onRevive: revive)
        } else {
            mainView
        }
    }

    // ── Main View ─────────────────────────────────────────────────────────

    private var mainView: some View {
        VStack(spacing: 4) {
            // Row 1: Name (tap to rename) + Death counter
            HStack {
                if isEditingName {
                    TextField("", text: $nameInput)
                        .font(.caption2)
                        .frame(width: 72, height: 14)
                        .padding(2)
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(4)
                        .foregroundColor(.white)
                        .onSubmit { commitRename() }
                } else {
                    Button(action: { startRename() }) {
                        Text(pet.name)
                            .font(.caption2.bold())
                            .foregroundColor(.yellow)
                    }
                    .buttonStyle(.plain)
                }
                if deathCount > 0 {
                    Text("☠\(deathCount)")
                        .font(.caption2)
                        .foregroundColor(.red.opacity(0.7))
                }
            }

            // Row 2: Pet character
            WatchPetCharacter(mood: pet.mood, animating: animating)
                .onTapGesture { animating = true; WKInterfaceDevice.current().play(.click)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { animating = false } }

            // Row 3: Critical warning
            if isCritical {
                Text("⚠ CRITICAL")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.red)
                    .opacity(critBlink ? 1 : 0.3)
            } else {
                Text(moodEmoji)
                    .font(.title3)
            }

            // Row 4: Stat bars
            HStack(spacing: 4) {
                MiniBar(label: "🍖", value: pet.hunger,    tick: decayingTick)
                MiniBar(label: "😊", value: pet.happiness, tick: decayingTick)
                MiniBar(label: "⚡", value: pet.energy,    tick: false)
                HealthBar(value: pet.health)
            }
            .padding(.horizontal, 2)

            // Row 5: Actions
            HStack(spacing: 6) {
                ForEach(WatchPetAction.allCases) { action in
                    Button(action: { performAction(action) }) {
                        Text(action.emoji)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Row 6: Feedback or history hint
            if !feedback.isEmpty {
                Text(feedback)
                    .font(.caption2)
                    .foregroundColor(.yellow)
            } else if !history.isEmpty {
                // Compact history — last entry only
                HStack(spacing: 2) {
                    Text(history[0].emoji)
                        .font(.caption2)
                    Text(history[0].label)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            // Row 7: XP
            Text("XP \(Int(pet.xp))")
                .font(.system(size: 9))
                .foregroundColor(.orange)
        }
        .padding(4)
        .onAppear { loadPet(); startDecay() }
    }

    // ── Computed ─────────────────────────────────────────────────────────

    private var moodEmoji: String {
        switch pet.mood {
        case "ecstatic":  return "🤩"
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

    private var isCritical: Bool {
        pet.hunger < 20 || pet.health < 20
    }

    @State private var critBlink = false
    private func startCritBlink() {
        Timer.scheduledTimer(withTimeInterval: 0.7, repeats: true) { _ in
            critBlink.toggle()
        }
    }

    private var deathCount: Int {
        UserDefaults.standard.integer(forKey: "clawbert_deaths")
    }

    // ── Actions ─────────────────────────────────────────────────────────

    private func performAction(_ action: WatchPetAction) {
        let delta = action.delta
        withAnimation(.easeInOut(duration: 0.3)) {
            pet.hunger    = clamp(pet.hunger    + delta.hunger)
            pet.happiness = clamp(pet.happiness + delta.happiness)
            pet.energy    = clamp(pet.energy    + delta.energy)
            pet.xp        = pet.xp + delta.xp
            pet.mood      = deriveMood()
            animating = true
        }

        // Health recovery when stats are good
        if pet.hunger > 50 && pet.happiness > 50 && pet.health < 100 {
            pet.health = clamp(pet.health + 1)
        }

        let entry = WatchHistoryEntry(emoji: action.emoji, label: action.rawValue, time: Date())
        history.insert(entry, at: 0)
        if history.count > 3 { history = Array(history.prefix(3)) }

        feedback = "\(action.emoji)!"
        WKInterfaceDevice.current().play(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            feedback = ""; animating = false
        }

        if pet.health <= 0 || pet.hunger <= 0 { triggerDeath() }
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

    private func triggerDeath() {
        isDead = true
        let deaths = UserDefaults.standard.integer(forKey: "clawbert_deaths")
        UserDefaults.standard.set(deaths + 1, forKey: "clawbert_deaths")
    }

    private func revive() {
        pet = WatchPetState.initial
        history = []
        isDead = false
        savePet()
    }

    private func startRename() {
        nameInput = pet.name
        isEditingName = true
    }

    private func commitRename() {
        if !nameInput.isEmpty {
            pet.name = nameInput
        }
        isEditingName = false
        savePet()
    }

    private func clamp(_ v: Double) -> Double {
        Swift.max(0, Swift.min(100, v))
    }

    // ── Decay Timer ───────────────────────────────────────────────────────

    private func startDecay() {
        // Initial delay to let app settle
        DispatchQueue.main.asyncAfter(deadline: .now() + decayInterval) {
            applyDecay()
            // Then repeat every decayInterval
            Timer.scheduledTimer(withTimeInterval: decayInterval, repeats: true) { _ in
                applyDecay()
            }
        }
    }

    private func applyDecay() {
        guard !isDead else { return }
        decayingTick = true
        pet.hunger    = clamp(pet.hunger - 1)
        pet.happiness = clamp(pet.happiness - 0.5)
        pet.mood      = deriveMood()
        if pet.hunger <= 0 || pet.health <= 0 { triggerDeath() }
        savePet()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            decayingTick = false
        }
    }

    // ── Persistence ─────────────────────────────────────────────────────

    private func savePet() {
        if let data = try? JSONEncoder().encode(pet) {
            UserDefaults.standard.set(data, forKey: "clawbert_watch")
        }
        if let histData = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(histData, forKey: "clawbert_history")
        }
    }

    private func loadPet() {
        if let data = UserDefaults.standard.data(forKey: "clawbert_watch"),
           let saved = try? JSONDecoder().decode(WatchPetState.self, from: data) {
            pet = saved
            if pet.health <= 0 || pet.hunger <= 0 {
                isDead = true
            }
        }
        if let histData = UserDefaults.standard.data(forKey: "clawbert_history"),
           let saved = try? JSONDecoder().decode([WatchHistoryEntry].self, from: histData) {
            history = saved
        }
    }
}

// ── Pet State ────────────────────────────────────────────────────────────────

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

// ── History Entry ───────────────────────────────────────────────────────────

struct WatchHistoryEntry: Codable, Identifiable {
    var id = UUID()
    let emoji: String
    let label: String
    let time: Date
}

// ── Pet Actions ─────────────────────────────────────────────────────────────

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

// ── Stat Bars ───────────────────────────────────────────────────────────────

struct MiniBar: View {
    let label: String
    let value: Double
    let tick: Bool
    @State private var tickFlash = false

    private var color: Color {
        if value < 20 { return .red }
        if value < 40 { return .orange }
        return Color(red: 0.4, green: 0.73, blue: 0.4)
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
            .frame(width: 22, height: 28)
            // Decay tick indicator
            if tick {
                Circle()
                    .fill(Color.red)
                    .frame(width: 3, height: 3)
            }
        }
    }
}

struct HealthBar: View {
    let value: Double
    private var color: Color {
        if value < 20 { return .red }
        if value < 40 { return .orange }
        return .red  // health is always red-ish
    }
    var body: some View {
        VStack(spacing: 2) {
            Text("❤️")
                .font(.system(size: 10))
            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 2).fill(Color.gray.opacity(0.3))
                    RoundedRectangle(cornerRadius: 2).fill(color)
                        .frame(height: geo.size.height * CGFloat(value / 100))
                }
            }
            .frame(width: 22, height: 28)
        }
    }
}

// ── Pet Character ──────────────────────────────────────────────────────────

struct WatchPetCharacter: View {
    let mood: String
    let animating: Bool
    private var sprite: String {
        switch mood {
        case "ecstatic":  return "🤩"
        case "happy":    return "😺"
        case "content":  return "😸"
        case "neutral":  return "😼"
        case "sad":      return "😿"
        case "miserable":return "🙀"
        case "sleeping": return "😴"
        case "eating":   return "😻"
        default:         return "🐱"
        }
    }
    var body: some View {
        Text(sprite)
            .font(.system(size: animating ? 40 : 34))
            .animation(.spring(response: 0.3), value: animating)
    }
}

// ── Death View ─────────────────────────────────────────────────────────────

struct DeathView: View {
    let deaths: Int
    let onRevive: () -> Void
    var body: some View {
        VStack(spacing: 8) {
            Text("💀")
                .font(.system(size: 44))
            if deaths > 0 {
                Text("☠ \(deaths) death\(deaths == 1 ? "" : "s")")
                    .font(.system(size: 9))
                    .foregroundColor(.red.opacity(0.7))
            }
            Text("Clawbert\nhas passed...")
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Button(action: onRevive) {
                Label("Revive", systemImage: "arrow.clockwise")
                    .font(.caption2.bold())
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .padding(4)
    }
}

#Preview {
    WatchContentView()
}
