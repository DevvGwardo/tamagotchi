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
                Text("Setup Clawbert")
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

// MARK: - Sync Indicator View

struct SyncIndicatorView: View {
    @ObservedObject var syncManager: StateSyncManager
    
    var body: some View {
        HStack(spacing: 4) {
            // Status dot
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            
            // Status text
            Text(syncManager.syncStatus.displayText)
                .font(.system(size: 10))
                .foregroundColor(.gray)
            
            // Refresh button
            Button {
                syncManager.forceRefresh()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 10))
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var statusColor: Color {
        switch syncManager.syncStatus {
        case .syncing:
            return .yellow
        case .synced:
            return .green
        case .offline:
            return .gray
        case .error:
            return .red
        }
    }
}

// MARK: - Stat Bar View

struct StatBarView: View {
    let label: String
    let value: Int
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
                .frame(width: 16)
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white)
                .frame(width: 50, alignment: .leading)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)
                    
                    // Fill
                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor)
                        .frame(width: max(0, geometry.size.width * CGFloat(value) / 100), height: 8)
                        .animation(.easeInOut(duration: 0.3), value: value)
                }
            }
            .frame(height: 8)
            
            Text("\(value)")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(color)
                .frame(width: 22, alignment: .trailing)
        }
    }
    
    private var barColor: Color {
        if value > 70 { return color }
        if value > 30 { return .orange }
        return .red
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    let disabled: Bool
    
    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.system(size: 10, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(color.opacity(disabled ? 0.3 : 0.6))
            .foregroundColor(disabled ? .gray : .white)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}

// MARK: - Pet Companion View

struct PetCompanionView: View {
    @StateObject private var syncManager = StateSyncManager.shared
    @State private var particleTrigger: ParticleTrigger?
    
    private let spriteSize: CGFloat = 100
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Sync indicator at top
                SyncIndicatorView(syncManager: syncManager)
                
                // Pet name and XP
                HStack {
                    Text(syncManager.petState.name)
                        .font(.headline)
                    Spacer()
                    Text("XP: \(syncManager.petState.xp)")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
                
                // Animated sprite with particle overlay
                ZStack {
                    SmartSpriteView(
                        mood: syncManager.petState.displayMood,
                        triggerBounce: particleTrigger != nil,
                        size: spriteSize
                    )
                    
                    ParticleOverlay(trigger: particleTrigger)
                }
                .frame(height: spriteSize)
                
                // Stats
                VStack(spacing: 6) {
                    StatBarView(
                        label: "Hunger",
                        value: syncManager.petState.hunger,
                        color: .green,
                        icon: "fork.knife"
                    )
                    StatBarView(
                        label: "Happy",
                        value: syncManager.petState.happiness,
                        color: .pink,
                        icon: "heart.fill"
                    )
                    StatBarView(
                        label: "Energy",
                        value: syncManager.petState.energy,
                        color: .blue,
                        icon: "bolt.fill"
                    )
                    StatBarView(
                        label: "Health",
                        value: syncManager.petState.health,
                        color: .red,
                        icon: "staroflife.fill"
                    )
                }
                
                // Action buttons
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ActionButton(
                        title: "Feed",
                        icon: "cart.fill",
                        color: .green,
                        action: { 
                            Task {
                                await syncManager.feed()
                                withAnimation {
                                    particleTrigger = .eat
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    particleTrigger = nil
                                }
                            }
                        },
                        disabled: syncManager.petState.isSleeping
                    )
                    
                    ActionButton(
                        title: "Play",
                        icon: "gamecontroller.fill",
                        color: .orange,
                        action: { 
                            Task {
                                await syncManager.play()
                                withAnimation {
                                    particleTrigger = .pet
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    particleTrigger = nil
                                }
                            }
                        },
                        disabled: syncManager.petState.isSleeping || syncManager.petState.energy < 20
                    )
                    
                    ActionButton(
                        title: "Pet",
                        icon: "hand.tap.fill",
                        color: .pink,
                        action: { 
                            Task {
                                await syncManager.pet()
                                withAnimation {
                                    particleTrigger = .pet
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    particleTrigger = nil
                                }
                            }
                        },
                        disabled: false
                    )
                    
                    ActionButton(
                        title: syncManager.petState.isSleeping ? "Wake" : "Sleep",
                        icon: syncManager.petState.isSleeping ? "sun.max.fill" : "moon.fill",
                        color: .purple,
                        action: { 
                            Task {
                                await syncManager.toggleSleep()
                                if syncManager.petState.isSleeping {
                                    withAnimation {
                                        particleTrigger = .sleep
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                        particleTrigger = nil
                                    }
                                }
                            }
                        },
                        disabled: false
                    )
                }
                
                // Mood indicator
                HStack(spacing: 4) {
                    Text("Mood:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(syncManager.petState.mood.capitalized)
                        .font(.caption)
                        .foregroundColor(.white)
                }
                
                // Achievements count
                if !syncManager.petState.achievements.isEmpty {
                    HStack(spacing: 4) {
                        Text("🏆")
                            .font(.caption)
                        Text("\(syncManager.petState.achievements.count) achievements")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
        }
        .onAppear {
            // Initial load
            syncManager.forceRefresh()
        }
    }
}

// MARK: - Preview

#Preview {
    PetCompanionView()
}
