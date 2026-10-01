import Foundation
import Combine
import WatchConnectivity

// MARK: - iOS State Sync Manager

/// Manages bidirectional sync between the iOS companion app and the watch via WatchConnectivity.
/// Persists state locally in UserDefaults and syncs changes to/from the paired Apple Watch.
@MainActor
class iOSStateSyncManager: NSObject, ObservableObject {
    static let shared = iOSStateSyncManager()

    // MARK: - Published State

    @Published var petState: PetState = .default
    @Published var syncStatus: SyncStatus = .offline

    // MARK: - Private

    private let userDefaultsKey = "hermes_pet_v2"
    private var wcSession: WCSession?

    // MARK: - Initialisation

    override init() {
        super.init()
        loadFromUserDefaults()
        activateSession()
    }

    // MARK: - WCSession

    private func activateSession() {
        guard WCSession.isSupported() else {
            syncStatus = .offline
            return
        }
        let session = WCSession.default
        session.delegate = self
        session.activate()
        wcSession = session
    }

    // MARK: - Sending State to Watch

    func sendStateToWatch() {
        guard let session = wcSession, session.activationState == .activated else { return }

        do {
            let dict = try petState.toSyncDictionary(source: "ios")

            if session.isReachable {
                syncStatus = .syncing
                session.sendMessage(dict, replyHandler: { [weak self] _ in
                    Task { @MainActor in self?.syncStatus = .synced(Date()) }
                }, errorHandler: { [weak self] _ in
                    try? session.updateApplicationContext(dict)
                    Task { @MainActor in self?.syncStatus = .synced(Date()) }
                })
            } else {
                try session.updateApplicationContext(dict)
                syncStatus = .synced(Date())
            }
        } catch {
            syncStatus = .error(error.localizedDescription)
        }
    }

    // MARK: - Incoming State

    func handleIncoming(_ dict: [String: Any]) {
        // Handle sync requests from watch
        if let msgType = dict["messageType"] as? String, msgType == "requestSync" {
            // Watch is asking for our current state — reply handled in the delegate
            return
        }

        guard let remote = try? PetState.fromSyncDictionary(dict) else { return }

        if remote.lastUpdated > petState.lastUpdated {
            petState = remote
            saveToUserDefaults()
            syncStatus = .synced(Date())
        }
    }

    // MARK: - Pet Interactions

    func performAction(_ action: PetAction) {
        let delta = action.delta
        petState.hunger    = min(100, max(0, petState.hunger    + delta.hunger))
        petState.happiness = min(100, max(0, petState.happiness + delta.happiness))
        petState.energy    = min(100, max(0, petState.energy    + delta.energy))
        petState.xp       += delta.xp
        petState.lastUpdated = Date()

        switch action {
        case .feed:  petState.lastFed = Date()
        case .play:  petState.lastPlayed = Date()
        case .sleep: petState.isSleeping.toggle()
        case .pet:   petState.lastPet = Date()
        }

        saveToUserDefaults()
        sendStateToWatch()
    }

    func updateName(_ name: String) {
        petState.name = name
        petState.lastUpdated = Date()
        saveToUserDefaults()
        sendStateToWatch()
    }

    // MARK: - UserDefaults Persistence

    private func saveToUserDefaults() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(petState) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }

    private func loadFromUserDefaults() {
        // Try new key first
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            if let saved = try? decoder.decode(PetState.self, from: data) {
                petState = saved
                return
            }
        }
        // Migrate from legacy key (old iOS-only PetState format)
        if let data = UserDefaults.standard.data(forKey: "hermes_pet"),
           let legacy = try? JSONDecoder().decode(LegacyPetState.self, from: data) {
            petState = legacy.toUnified()
            saveToUserDefaults()
            UserDefaults.standard.removeObject(forKey: "hermes_pet")
        }
    }

    // MARK: - Manual Refresh

    func forceRefresh() {
        guard let session = wcSession, session.isReachable else { return }
        session.sendMessage(["messageType": "requestSync"], replyHandler: { [weak self] reply in
            Task { @MainActor in
                self?.handleIncoming(reply)
            }
        }, errorHandler: nil)
    }
}

// MARK: - WCSessionDelegate

extension iOSStateSyncManager: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            if activationState == .activated {
                self.syncStatus = .synced(Date())
            } else {
                self.syncStatus = .offline
            }
        }
    }

    // iOS-only required delegate methods
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // Re-activate for watch switching
        session.activate()
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            self.handleIncoming(message)
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        Task { @MainActor in
            // If the watch is requesting a sync, reply with our state
            if let msgType = message["messageType"] as? String, msgType == "requestSync" {
                if let reply = try? self.petState.toSyncDictionary(source: "ios") {
                    replyHandler(reply)
                } else {
                    replyHandler([:])
                }
                return
            }

            self.handleIncoming(message)
            if let reply = try? self.petState.toSyncDictionary(source: "ios") {
                replyHandler(reply)
            } else {
                replyHandler([:])
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            self.handleIncoming(applicationContext)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        Task { @MainActor in
            self.handleIncoming(userInfo)
        }
    }
}

// MARK: - Legacy Migration

/// The old iOS-only PetState format for migration purposes
private struct LegacyPetState: Codable {
    var id: String
    var name: String
    var hunger: Double
    var happiness: Double
    var energy: Double
    var xp: Double
    var health: Double
    var mood: String
    var skin: String
    var lastUpdated: TimeInterval

    func toUnified() -> PetState {
        var state = PetState.default
        state.id = id
        state.name = name
        state.hunger = hunger
        state.happiness = happiness
        state.energy = energy
        state.xp = xp
        state.health = health
        state.mood = mood
        state.skin = skin
        state.lastUpdated = Date(timeIntervalSince1970: lastUpdated)
        return state
    }
}
