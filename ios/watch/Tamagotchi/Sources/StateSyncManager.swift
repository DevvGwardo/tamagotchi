import Foundation
import Combine
import WatchKit
import WatchConnectivity

// MARK: - Watch State Sync Manager

/// Manages bidirectional sync between the watch app and the iOS companion via WatchConnectivity,
/// with a local JSON file as an offline cache.
@MainActor
class StateSyncManager: NSObject, ObservableObject {
    static let shared = StateSyncManager()

    // MARK: - Published State

    @Published var petState: PetState = .default
    @Published var syncStatus: SyncStatus = .offline

    // MARK: - Private Properties

    private let cacheFilePath: String
    private var wcSession: WCSession?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    override init() {
        let home = NSHomeDirectory()
        self.cacheFilePath = "\(home)/.hermes/workspace/hermes-state.json"
        super.init()

        loadLocalCache()
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

    // MARK: - Sending State to iOS

    private func sendStateToPhone() {
        guard let session = wcSession, session.activationState == .activated else {
            syncStatus = .offline
            return
        }

        do {
            let dict = try petState.toSyncDictionary(source: "watchos")

            if session.isReachable {
                syncStatus = .syncing
                session.sendMessage(dict, replyHandler: { [weak self] _ in
                    Task { @MainActor in self?.syncStatus = .synced(Date()) }
                }, errorHandler: { [weak self] _ in
                    // Fallback to application context
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

    func requestSyncFromPhone() {
        guard let session = wcSession, session.isReachable else { return }
        session.sendMessage(["messageType": "requestSync"], replyHandler: { [weak self] reply in
            Task { @MainActor in
                self?.handleIncoming(reply)
            }
        }, errorHandler: nil)
    }

    // MARK: - Incoming State

    func handleIncoming(_ dict: [String: Any]) {
        guard let remote = try? PetState.fromSyncDictionary(dict) else { return }

        if remote.lastUpdated > petState.lastUpdated {
            petState = remote
            saveLocalCache()
            syncStatus = .synced(Date())
            WKInterfaceDevice.current().play(.click)
        }
    }

    // MARK: - Pet Interactions

    func feed() async {
        guard !petState.isSleeping else {
            WKInterfaceDevice.current().play(.failure)
            return
        }
        petState.hunger = min(100, petState.hunger + 20)
        petState.lastFed = Date()
        petState.mood = "happy"
        petState.lastUpdated = Date()
        saveLocalCache()
        sendStateToPhone()
        WKInterfaceDevice.current().play(.success)
    }

    func play() async {
        guard !petState.isSleeping else {
            WKInterfaceDevice.current().play(.failure)
            return
        }
        petState.happiness = min(100, petState.happiness + 15)
        petState.energy = max(0, petState.energy - 10)
        petState.lastPlayed = Date()
        petState.xp += 5
        petState.lastUpdated = Date()
        saveLocalCache()
        sendStateToPhone()
        WKInterfaceDevice.current().play(.success)
    }

    func pet() async {
        petState.happiness = min(100, petState.happiness + 10)
        petState.lastPet = Date()
        petState.mood = "happy"
        petState.lastUpdated = Date()
        saveLocalCache()
        sendStateToPhone()
        WKInterfaceDevice.current().play(.click)
    }

    func toggleSleep() async {
        petState.isSleeping.toggle()
        petState.lastCheckTime = Date()
        petState.lastUpdated = Date()
        saveLocalCache()
        sendStateToPhone()
        WKInterfaceDevice.current().play(.click)
    }

    // MARK: - Local Cache

    private func saveLocalCache() {
        let fileURL = URL(fileURLWithPath: cacheFilePath)
        let directory = fileURL.deletingLastPathComponent()
        do {
            if !FileManager.default.fileExists(atPath: directory.path) {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            }
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(petState)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            print("[StateSyncManager] Failed to save cache: \(error)")
        }
    }

    private func loadLocalCache() {
        let fileURL = URL(fileURLWithPath: cacheFilePath)
        guard FileManager.default.fileExists(atPath: cacheFilePath) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            petState = try decoder.decode(PetState.self, from: data)
        } catch {
            print("[StateSyncManager] Failed to load cache: \(error)")
        }
    }

    // MARK: - Public Save (for external state mutations)

    func saveState() async {
        petState.lastUpdated = Date()
        saveLocalCache()
        sendStateToPhone()
    }

    // MARK: - Manual Refresh

    func forceRefresh() {
        requestSyncFromPhone()
    }
}

// MARK: - WCSessionDelegate

extension StateSyncManager: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            if activationState == .activated {
                self.syncStatus = .synced(Date())
                self.requestSyncFromPhone()
            } else {
                self.syncStatus = .offline
            }
        }
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
            self.handleIncoming(message)
            if let reply = try? self.petState.toSyncDictionary(source: "watchos") {
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
