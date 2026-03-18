import SwiftUI

@main
struct Tamagotchi_iOSApp: App {
    var body: some Scene {
        WindowGroup {
            iOSCompanionView()
        }
    }
}

struct iOSCompanionView: View {
    @State private var pet = PetState.initial
    @State private var history: [HistoryEntry] = []
    @State private var actionMessage = ""
    @State private var animating = false
    @State private var isEditingName = false
    @State private var nameInput = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Character
                    PetCharacterView(mood: pet.mood, animating: animating)
                        .frame(height: 120)

                    // Name
                    HStack(spacing: 6) {
                        if isEditingName {
                            TextField("Name", text: $nameInput)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 140)
                                .onSubmit { saveName() }
                            Button("Save") { saveName() }
                                .buttonStyle(.borderedProminent)
                        } else {
                            Text(pet.name)
                                .font(.title2.bold())
                            Button { nameInput = pet.name; isEditingName = true } label: {
                                Image(systemName: "pencil").font(.caption)
                            }
                        }
                    }

                    Text(pet.mood.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Stats
                    VStack(spacing: 10) {
                        StatBarRow(label: "🍖 Hunger",    value: pet.hunger,    color: statColor(pet.hunger))
                        StatBarRow(label: "😊 Happiness", value: pet.happiness, color: statColor(pet.happiness))
                        StatBarRow(label: "⚡ Energy",    value: pet.energy,    color: statColor(pet.energy))
                        StatBarRow(label: "❤️ Health",   value: pet.health,    color: statColor(pet.health))
                        HStack {
                            Text("💡 XP: \(Int(pet.xp))")
                            Spacer()
                            Text("☠️ Deaths: \(deathCount)")
                                .foregroundColor(.secondary)
                        }
                        .font(.caption)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)

                    // Action Buttons
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                        ForEach(PetAction.allCases) { action in
                            ActionButton(action: action) { performAction(action) }
                        }
                    }

                    // Feedback
                    if !actionMessage.isEmpty {
                        Text(actionMessage)
                            .font(.subheadline.bold())
                            .foregroundColor(.orange)
                            .padding(.vertical, 4)
                    }

                    // History
                    if !history.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Recent Activity")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                            ForEach(history.prefix(5)) { entry in
                                HStack {
                                    Text(entry.emoji)
                                    Text(entry.message)
                                        .font(.caption)
                                    Spacer()
                                    Text(entry.time, style: .time)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("🐾 Tamagotchi")
            .onAppear { loadPet() }
        }
    }

    private func statColor(_ v: Double) -> Color {
        if v < 20 { return .red }
        if v < 40 { return .orange }
        return .green
    }

    private func saveName() {
        guard !nameInput.isEmpty else { return }
        pet.name = nameInput
        isEditingName = false
        savePet()
    }

    private func performAction(_ action: PetAction) {
        let delta = action.delta
        withAnimation(.spring(response: 0.3)) {
            pet.hunger    = min(100, max(0, pet.hunger    + delta.hunger))
            pet.happiness = min(100, max(0, pet.happiness + delta.happiness))
            pet.energy    = min(100, max(0, pet.energy    + delta.energy))
            pet.xp        = pet.xp + delta.xp
            pet.mood      = deriveMood(pet)
            animating = true
        }
        actionMessage = "\(action.emoji) \(action.rawValue)!"
        let entry = HistoryEntry(emoji: action.emoji, message: "\(action.rawValue) \(pet.name)", time: Date())
        history.insert(entry, at: 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            actionMessage = ""; animating = false
        }
        savePet()
    }

    private func deriveMood(_ s: PetState) -> String {
        if s.energy < 10 { return "sleeping" }
        let avg = (s.hunger + s.happiness + s.health) / 3
        if avg >= 90 { return "ecstatic" }
        if avg >= 75 { return "happy" }
        if avg >= 60 { return "content" }
        if avg >= 40 { return "neutral" }
        if avg >= 20 { return "sad" }
        return "miserable"
    }

    private var deathCount: Int {
        UserDefaults.standard.integer(forKey: "clawbert_deaths")
    }

    private func savePet() {
        if let data = try? JSONEncoder().encode(pet) {
            UserDefaults.standard.set(data, forKey: "clawbert_pet")
        }
    }

    private func loadPet() {
        if let data = UserDefaults.standard.data(forKey: "clawbert_pet"),
           let saved = try? JSONDecoder().decode(PetState.self, from: data) {
            pet = saved
        }
    }
}

struct StatBarRow: View {
    let label: String
    let value: Double
    let color: Color
    var body: some View {
        HStack(spacing: 8) {
            Text(label).font(.caption).frame(width: 90, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.2))
                    RoundedRectangle(cornerRadius: 4).fill(color)
                        .frame(width: geo.size.width * CGFloat(value / 100))
                }
            }
            .frame(height: 8)
            Text("\(Int(value))").font(.caption).foregroundColor(.secondary).frame(width: 28, alignment: .trailing)
        }
    }
}

struct ActionButton: View {
    let action: PetAction
    let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(action.emoji).font(.title2)
                Text(action.rawValue).font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.accentColor.opacity(0.15))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct PetCharacterView: View {
    let mood: String
    let animating: Bool
    private var sprites: (main: String, accent: String) {
        switch mood {
        case "ecstatic":  return ("🤩", "✨")
        case "happy":     return ("😺", "💛")
        case "content":   return ("😸", "🌿")
        case "neutral":   return ("😼", "⚪")
        case "sad":       return ("😿", "💧")
        case "miserable": return ("🙀", "💔")
        case "sleeping":  return ("😴", "🌙")
        case "eating":    return ("😻", "🍽️")
        default:          return ("🐱", "⚪")
        }
    }
    var body: some View {
        VStack {
            Text(sprites.main)
                .font(.system(size: 64))
                .scaleEffect(animating ? 1.2 : 1.0)
                .animation(.spring(response: 0.3), value: animating)
            Text(sprites.accent).font(.title3)
        }
    }
}

struct HistoryEntry: Identifiable {
    let id = UUID()
    let emoji: String
    let message: String
    let time: Date
}

#Preview {
    iOSCompanionView()
}
