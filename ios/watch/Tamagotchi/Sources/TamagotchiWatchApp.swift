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
            AgentCompanionView()
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

// MARK: - Agent Companion View Model

@MainActor
class AgentCompanionViewModel: ObservableObject {
    @Published var agentState: AgentState = .idle
    @Published var lastResponse: String?
    @Published var messages: [ChatMessage] = []
    @Published var errorMessage: String?

    private let chatService = WatchChatService.shared

    func sendMessage(_ text: String) async {
        let userMessage = ChatMessage(role: "user", content: text)
        messages.append(userMessage)
        errorMessage = nil

        // Sending state — triggers bounce + click
        agentState = .sending
        agentState.playHaptic()

        // Brief delay for bounce animation, then thinking
        try? await Task.sleep(nanoseconds: 400_000_000)
        agentState = .thinking

        do {
            let response = try await chatService.sendMessage(text, history: messages)
            let assistantMessage = ChatMessage(role: "assistant", content: response)
            messages.append(assistantMessage)
            lastResponse = response

            // Responding state — happy animation + hearts + success haptic
            agentState = .responding
            agentState.playHaptic()

            // Return to idle after 3 seconds
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            agentState = .idle
        } catch {
            errorMessage = error.localizedDescription
            agentState = .error
            agentState.playHaptic()
        }
    }

    func retry() async {
        guard let lastUserMessage = messages.last(where: { $0.role == "user" }) else { return }
        // Remove the failed user message to re-send
        if let lastIndex = messages.lastIndex(where: { $0.id == lastUserMessage.id }) {
            messages.remove(at: lastIndex)
        }
        await sendMessage(lastUserMessage.content)
    }

    func disconnect() {
        UserDefaults.standard.removeObject(forKey: "agent_endpoint")
        UserDefaults.standard.removeObject(forKey: "agent_token")
    }
}

// MARK: - Agent Companion View

struct AgentCompanionView: View {
    @StateObject private var viewModel = AgentCompanionViewModel()
    @State private var showingInput = false
    @State private var inputText = ""
    @State private var particleTrigger: ParticleTrigger?

    private let spriteSize: CGFloat = 160

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Animated sprite with particle overlay
                ZStack {
                    SmartSpriteView(
                        mood: viewModel.agentState.mood,
                        triggerBounce: viewModel.agentState.shouldBounce,
                        size: spriteSize
                    )

                    ParticleOverlay(trigger: particleTrigger)
                }
                .frame(height: spriteSize)

                // Last response text
                if let response = viewModel.lastResponse {
                    Text(response)
                        .font(.caption2)
                        .foregroundColor(.white)
                        .lineLimit(4)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                // Status indicator
                statusView

                // Error + retry
                if viewModel.agentState == .error {
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                    Button("Retry") {
                        Task { await viewModel.retry() }
                    }
                    .font(.caption2)
                    .foregroundColor(.orange)
                }

                // Ask button
                if viewModel.agentState != .thinking && viewModel.agentState != .sending {
                    Button {
                        showingInput = true
                    } label: {
                        Label("Ask Clawbert", systemImage: "mic.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)

                    // Quick suggestions
                    VStack(spacing: 4) {
                        quickReplyButton("What's on my TODO?")
                        quickReplyButton("Tell me something")
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .sheet(isPresented: $showingInput) {
            VStack {
                TextField("Ask Clawbert...", text: $inputText)
                Button("Send") {
                    let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else { return }
                    inputText = ""
                    showingInput = false
                    Task { await viewModel.sendMessage(text) }
                }
                .buttonStyle(.borderedProminent)
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .onChange(of: viewModel.agentState) { newState in
            particleTrigger = newState.particleTrigger
        }
    }

    private var statusView: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            Text(statusText)
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
    }

    private var statusColor: Color {
        switch viewModel.agentState {
        case .idle:       return .green
        case .sending, .thinking: return .orange
        case .responding: return .green
        case .error:      return .red
        }
    }

    private var statusText: String {
        switch viewModel.agentState {
        case .idle:       return "Connected"
        case .sending:    return "Sending..."
        case .thinking:   return "Thinking..."
        case .responding: return "Responding"
        case .error:      return "Error"
        }
    }

    private func quickReplyButton(_ text: String) -> some View {
        Button {
            Task { await viewModel.sendMessage(text) }
        } label: {
            Text(text)
                .font(.caption2)
                .foregroundColor(.blue)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AgentCompanionView()
}
