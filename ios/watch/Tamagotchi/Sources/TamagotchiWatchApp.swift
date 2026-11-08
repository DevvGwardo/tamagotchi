import SwiftUI
import WatchKit

@main
struct TamagotchiWatchApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

// MARK: - Root View

struct RootView: View {
    @AppStorage("agent_endpoint") private var endpoint: String = ""
    @AppStorage("agent_token") private var token: String = ""

    var body: some View {
        if endpoint.isEmpty || token.isEmpty {
            SetupView()
        } else {
            PetCompanionView()
        }
    }
}

// MARK: - Setup View

struct SetupView: View {
    @AppStorage("agent_endpoint") private var endpoint: String = ""
    @AppStorage("agent_token") private var token: String = ""
    @State private var urlInput: String = ""
    @State private var tokenInput: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Setup Hermes")
                    .font(.headline)

                TextField("Gateway URL", text: $urlInput)
                    .textContentType(.URL)
                    .autocorrectionDisabled()

                SecureField("Token", text: $tokenInput)

                Button("Connect") {
                    let gatewayURL = urlInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    let authValue = tokenInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !gatewayURL.isEmpty, !authValue.isEmpty else { return }
                    WatchChatService.shared.configure(endpoint: gatewayURL, token: authValue)
                    endpoint = gatewayURL
                    token = authValue
                }
                .buttonStyle(.borderedProminent)
                .disabled(urlInput.isEmpty || tokenInput.isEmpty)
            }
            .padding()
        }
    }
}

// MARK: - Pet Companion View (Main Router)

struct PetCompanionView: View {
    @StateObject private var syncManager = StateSyncManager.shared
    @State private var particleTrigger: ParticleTrigger?

    private var pet: PetState { syncManager.petState }

    private var petLevel: Int {
        max(1, Int(pet.xp / 100) + 1)
    }

    var body: some View {
        Group {
            if pet.health < 10 {
                DeadStateView(syncManager: syncManager)
            } else if pet.isSleeping {
                SleepingStateView(syncManager: syncManager, particleTrigger: $particleTrigger)
            } else if pet.hunger < 20 || pet.happiness < 20 || pet.energy < 20 || pet.health < 30 {
                LowStatsView(syncManager: syncManager, particleTrigger: $particleTrigger)
            } else {
                NormalStateView(syncManager: syncManager, particleTrigger: $particleTrigger, petLevel: petLevel)
            }
        }
    }
}

// MARK: - Normal State

struct NormalStateView: View {
    @ObservedObject var syncManager: StateSyncManager
    @Binding var particleTrigger: ParticleTrigger?

    let petLevel: Int
    private let spriteSize: CGFloat = 80

    private var pet: PetState { syncManager.petState }

    var body: some View {
        VStack(spacing: 4) {
            // Name + Level badge
            HStack(spacing: 6) {
                Text(pet.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)

                Text("LV\(petLevel)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color(hex: 0xFCD34D))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(8)
            }

            // Character
            ZStack {
                SmartSpriteView(
                    mood: pet.displayMood,
                    triggerBounce: particleTrigger != nil,
                    size: spriteSize
                )
                ParticleOverlay(trigger: particleTrigger)
            }
            .frame(height: spriteSize)

            // Mood
            Text("\(moodLabel) \(pet.moodEmoji)")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.44))

            // Stat dots
            HStack(spacing: 10) {
                StatDot(value: pet.hunger, color: Color(hex: 0x22C55E))
                StatDot(value: pet.happiness, color: Color(hex: 0xF472B6))
                StatDot(value: pet.energy, color: Color(hex: 0x8B5CF6))
                StatDot(value: pet.health, color: Color(hex: 0x14B8A6))
            }
            .padding(.vertical, 4)

            // Action buttons
            HStack(spacing: 10) {
                CircleActionButton(emoji: "🍎", color: Color(hex: 0x22C55E), disabled: false) {
                    doAction { await syncManager.feed() }
                    triggerParticle(.eat)
                }
                CircleActionButton(emoji: "🎮", color: Color(hex: 0xFCD34D), disabled: pet.energy < 20) {
                    doAction { await syncManager.play() }
                    triggerParticle(.pet)
                }
                CircleActionButton(emoji: "💕", color: Color(hex: 0xF472B6), disabled: false) {
                    doAction { await syncManager.pet() }
                    triggerParticle(.pet)
                }
                CircleActionButton(emoji: "💤", color: Color(hex: 0x8B5CF6), disabled: false) {
                    doAction { await syncManager.toggleSleep() }
                }
            }
            .padding(.vertical, 4)

            // Sync indicator
            SyncDot(syncStatus: syncManager.syncStatus) {
                syncManager.forceRefresh()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .edgesIgnoringSafeArea(.bottom)
    }

    private var moodLabel: String {
        pet.mood.capitalized
    }

    private func doAction(_ action: @escaping () async -> Void) {
        Task { await action() }
    }

    private func triggerParticle(_ type: ParticleTrigger) {
        withAnimation { particleTrigger = type }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { particleTrigger = nil }
    }
}

// MARK: - Sleeping State

struct SleepingStateView: View {
    @ObservedObject var syncManager: StateSyncManager
    @Binding var particleTrigger: ParticleTrigger?

    private let spriteSize: CGFloat = 80
    private var pet: PetState { syncManager.petState }

    var body: some View {
        VStack(spacing: 2) {
            Text(pet.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            Spacer()

            // Zzz text
            Text("z  z  z")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: 0x8B5CF6).opacity(0.5))
                .tracking(6)

            // Character
            ZStack {
                SmartSpriteView(
                    mood: "sleeping",
                    triggerBounce: false,
                    size: spriteSize
                )
                ParticleOverlay(trigger: particleTrigger)
            }
            .frame(height: spriteSize)

            Text("Sleeping...")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: 0x8B5CF6).opacity(0.5))

            Spacer()

            // Wake Up button
            Button {
                Task {
                    await syncManager.toggleSleep()
                }
            } label: {
                Text("Wake Up")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: 0x1A1A1A))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(hex: 0xFCD34D))
                    .cornerRadius(20)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
    }
}

// MARK: - Low Stats State

struct LowStatsView: View {
    @ObservedObject var syncManager: StateSyncManager
    @Binding var particleTrigger: ParticleTrigger?

    private let spriteSize: CGFloat = 56
    private var pet: PetState { syncManager.petState }

    /// The most critical stat determines the primary action
    private var primaryAction: (label: String, color: Color, action: () async -> Void, particle: ParticleTrigger) {
        let stats: [(Double, String, Color, () async -> Void, ParticleTrigger)] = [
            (pet.hunger,    "Feed",  Color(hex: 0x22C55E), { await syncManager.feed() },        .eat),
            (pet.happiness, "Play",  Color(hex: 0xFCD34D), { await syncManager.play() },        .pet),
            (pet.energy,    "Sleep", Color(hex: 0x8B5CF6), { await syncManager.toggleSleep() }, .sleep),
        ]
        let worst = stats.min(by: { $0.0 < $1.0 })!
        return (worst.1, worst.2, worst.3, worst.4)
    }

    var body: some View {
        VStack(spacing: 3) {
            // Header with SOS badge
            HStack(spacing: 6) {
                Text(pet.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)

                Text("SOS")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color(hex: 0xFF6B6B))
                    .cornerRadius(10)
            }

            // Character with glow
            ZStack {
                Circle()
                    .fill(Color(hex: 0x1A0A0A))
                    .frame(width: 64, height: 64)
                    .shadow(color: Color(hex: 0xFF6B6B).opacity(0.2), radius: 20, x: 0, y: 0)

                SmartSpriteView(
                    mood: pet.displayMood,
                    triggerBounce: particleTrigger != nil,
                    size: spriteSize
                )
                ParticleOverlay(trigger: particleTrigger)
            }
            .frame(height: 64)

            Text("Needs attention!")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: 0xFF9F0A))

            // Stat indicators with labels
            HStack(spacing: 8) {
                LabeledStatDot(label: "🍎", value: pet.hunger, critical: 20)
                LabeledStatDot(label: "😊", value: pet.happiness, critical: 20)
                LabeledStatDot(label: "⚡", value: pet.energy, critical: 20)
                LabeledStatDot(label: "❤️", value: pet.health, critical: 30)
            }
            .padding(.vertical, 2)

            // All action buttons — same as normal view for full control
            HStack(spacing: 10) {
                CircleActionButton(emoji: "🍎", color: Color(hex: 0x22C55E), disabled: false) {
                    Task { await syncManager.feed() }
                    triggerParticle(.eat)
                }
                CircleActionButton(emoji: "🎮", color: Color(hex: 0xFCD34D), disabled: pet.energy < 10) {
                    Task { await syncManager.play() }
                    triggerParticle(.pet)
                }
                CircleActionButton(emoji: "💕", color: Color(hex: 0xF472B6), disabled: false) {
                    Task { await syncManager.pet() }
                    triggerParticle(.pet)
                }
                CircleActionButton(emoji: "💤", color: Color(hex: 0x8B5CF6), disabled: false) {
                    Task { await syncManager.toggleSleep() }
                }
            }
            .padding(.vertical, 2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .edgesIgnoringSafeArea(.bottom)
    }

    private func triggerParticle(_ type: ParticleTrigger) {
        withAnimation { particleTrigger = type }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { particleTrigger = nil }
    }
}

// MARK: - Dead State

struct DeadStateView: View {
    @ObservedObject var syncManager: StateSyncManager

    private var pet: PetState { syncManager.petState }

    var body: some View {
        VStack(spacing: 4) {
            // Name + RIP badge
            HStack(spacing: 6) {
                Text(pet.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: 0x4A4A5A))

                HStack(spacing: 3) {
                    Circle()
                        .fill(Color(hex: 0xFF453A))
                        .frame(width: 5, height: 5)
                    Text("RIP")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(Color(hex: 0xFF453A))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(hex: 0xFF453A).opacity(0.13))
                .cornerRadius(8)
            }

            // Skull with glow
            ZStack {
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: 0xFF453A).opacity(0.19),
                                Color(hex: 0xFF453A).opacity(0.06),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 45
                        )
                    )
                    .frame(width: 90, height: 90)

                Text("💀")
                    .font(.system(size: 60))
            }
            .frame(height: 78)

            Text("Game Over")
                .font(.system(size: 15, weight: .heavy))
                .foregroundColor(Color(hex: 0xFF453A))

            Text("\(pet.name) has passed away...")
                .font(.system(size: 9))
                .foregroundColor(Color(hex: 0x4A4A5A))

            // Action buttons
            VStack(spacing: 6) {
                Button {
                    Task {
                        syncManager.petState.health = 50
                        syncManager.petState.hunger = 50
                        syncManager.petState.happiness = 50
                        syncManager.petState.energy = 50
                        syncManager.petState.lastUpdated = Date()
                        await syncManager.saveState()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14))
                        Text("Revive")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 36)
                    .background(Color(hex: 0x8B5CF6))
                    .cornerRadius(20)
                }
                .buttonStyle(.plain)

                Button {
                    Task {
                        syncManager.petState = .default
                        await syncManager.saveState()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 12))
                        Text("New Pet")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(Color(hex: 0x14B8A6))
                    .frame(maxWidth: .infinity, minHeight: 30)
                    .background(Color(hex: 0x1C1C1E))
                    .cornerRadius(16)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - Reusable Components

/// Colored dot that represents a stat — brighter = higher value
struct StatDot: View {
    let value: Double
    let color: Color

    var body: some View {
        Circle()
            .fill(color)
            .opacity(max(0.3, value / 100))
            .frame(width: 8, height: 8)
    }
}

/// Stat dot with emoji label and value — used in SOS view to show which stats are low
struct LabeledStatDot: View {
    let label: String
    let value: Double
    let critical: Double

    private var isCritical: Bool { value < critical }

    var body: some View {
        VStack(spacing: 1) {
            Text(label)
                .font(.system(size: 10))
            Text("\(Int(value))")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(isCritical ? Color(hex: 0xFF453A) : Color(hex: 0xFF9F0A))
        }
    }
}

/// Circular emoji action button matching the Pencil design
struct CircleActionButton: View {
    let emoji: String
    let color: Color
    let disabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(emoji)
                .font(.system(size: 15))
                .frame(width: 32, height: 32)
                .background(color.opacity(disabled ? 0.1 : 0.13))
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.4 : 1)
    }
}

/// Minimal sync status dot
struct SyncDot: View {
    let syncStatus: SyncStatus
    let onRefresh: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(dotColor)
                .frame(width: 4, height: 4)
            Text(syncStatus.displayText)
                .font(.system(size: 8))
                .foregroundColor(.gray.opacity(0.6))
        }
        .onTapGesture { onRefresh() }
    }

    private var dotColor: Color {
        switch syncStatus {
        case .syncing: return .yellow
        case .synced:  return .green
        case .offline: return .gray
        case .error:   return .red
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

// MARK: - Preview

#Preview {
    PetCompanionView()
}
