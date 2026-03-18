import SwiftUI

struct ContentView: View {
    @State private var pet = PetState.initial
    @State private var showingAction = false
    @State private var actionMessage = ""
    @State private var animating = false

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // ── Character Display ──
                PetCharacterView(mood: pet.mood, animating: animating)
                    .frame(height: 80)

                // ── Name & Mood ──
                Text(pet.name)
                    .font(.caption2)
                    .fontWeight(.bold)
                Text(pet.moodEmoji)
                    .font(.title2)

                // ── Stat Bars ──
                StatBarRow(label: "🍖", value: pet.hunger, color: hungerColor)
                StatBarRow(label: "😊", value: pet.happiness, color: happinessColor)
                StatBarRow(label: "⚡", value: pet.energy, color: energyColor)
                StatBarRow(label: "❤️", value: pet.health, color: healthColor)

                // ── XP ──
                Text("XP: \(Int(pet.xp))")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                // ── Action Buttons ──
                HStack(spacing: 6) {
                    ForEach(PetAction.allCases) { action in
                        ActionButton(action: action) {
                            performAction(action)
                        }
                    }
                }
                .padding(.top, 4)

                // ── Action Feedback ──
                if !actionMessage.isEmpty {
                    Text(actionMessage)
                        .font(.caption2)
                        .foregroundColor(.yellow)
                        .transition(.opacity)
                }
            }
            .padding(6)
        }
    }

    // MARK: - Colors

    private func statColor(_ value: Double) -> Color {
        if value < 20 { return .red }
        if value < 40 { return .orange }
        return .green
    }

    private var hungerColor: Color    { statColor(pet.hunger) }
    private var happinessColor: Color  { statColor(pet.happiness) }
    private var energyColor: Color    { statColor(pet.energy) }
    private var healthColor: Color     { statColor(pet.health) }

    // MARK: - Actions

    private func performAction(_ action: PetAction) {
        let delta = action.delta

        withAnimation(.easeInOut(duration: 0.3)) {
            pet.hunger    = min(100, max(0, pet.hunger    + delta.hunger))
            pet.happiness = min(100, max(0, pet.happiness + delta.happiness))
            pet.energy    = min(100, max(0, pet.energy    + delta.energy))
            pet.xp        = pet.xp + delta.xp
            animating = true
        }

        actionMessage = "\(action.emoji) \(action.rawValue)!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            actionMessage = ""
            animating = false
        }

        // Update mood
        updateMood()
    }

    private func updateMood() {
        let avg = (pet.hunger + pet.happiness + pet.health) / 3
        if pet.energy < 10 {
            pet.mood = "sleeping"
        } else if avg >= 90 {
            pet.mood = "ecstatic"
        } else if avg >= 75 {
            pet.mood = "happy"
        } else if avg >= 60 {
            pet.mood = "content"
        } else if avg >= 40 {
            pet.mood = "neutral"
        } else if avg >= 20 {
            pet.mood = "sad"
        } else {
            pet.mood = "miserable"
        }
    }
}

// MARK: - Pet Character View

struct PetCharacterView: View {
    let mood: String
    let animating: Bool

    private var body: [String] {
        switch mood {
        case "ecstatic": return ["🤩", "🥳", "✨"]
        case "happy":    return ["😊", "😄", "😸"]
        case "content":  return ["🙂", "😌", "🐱"]
        case "neutral":  return ["😐", "😑", "🐾"]
        case "sad":      return ["😢", "🥺", "😿"]
        case "miserable":return ["😭", "😖", "💔"]
        case "sleeping": return ["😴", "💤", "🌙"]
        case "eating":   return ["😋", "🍽️", "😻"]
        default:         return ["😐", "🐾", "⚪"]
        }
    }

    var body: some View {
        VStack {
            Text(body[0])
                .font(.system(size: animating ? 52 : 48))
                .animation(.spring(response: 0.3), value: animating)
            if animating {
                Text(body[2])
                    .font(.caption)
                    .transition(.scale)
            }
        }
    }
}

// MARK: - Stat Bar Row

struct StatBarRow: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption2)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.3))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(value / 100))
                }
            }
            .frame(height: 6)
            Text("\(Int(value))")
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 24, alignment: .trailing)
        }
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let action: PetAction
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(action.emoji)
                .font(.title3)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}
