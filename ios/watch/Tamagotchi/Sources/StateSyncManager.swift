import Foundation
import Combine
import WatchKit

// MARK: - State Sync Manager

/// Manages bidirectional sync between the watch app and OpenClaw state file
@MainActor
class StateSyncManager: ObservableObject {
    static let shared = StateSyncManager()
    
    // MARK: - Published State
    
    @Published var petState: PetState = .default
    @Published var syncStatus: SyncStatus = .offline
    
    // MARK: - Private Properties
    
    private let stateFilePath: String
    private var fileMonitor: DispatchSourceFileSystemObject?
    private var lastWriteTime: Date = .distantPast
    private let writeDebounceInterval: TimeInterval = 0.5
    private var cancellables = Set<AnyCancellable>()
    private var syncTimer: Timer?
    
    // MARK: - Initialization
    
    init() {
        // Path to the OpenClaw state file
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path
        self.stateFilePath = "\(homeDirectory)/.openclaw/workspace/clawbert-state.json"
        
        // Load initial state
        loadState()
        
        // Start file watching
        startFileWatching()
        
        // Start periodic sync timer (every 30 seconds)
        startSyncTimer()
    }
    
    deinit {
        stopFileWatching()
        syncTimer?.invalidate()
    }
    
    // MARK: - State Loading
    
    func loadState() {
        syncStatus = .syncing
        
        do {
            let data = try readStateFile()
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let loadedState = try decoder.decode(PetState.self, from: data)
            
            petState = loadedState
            syncStatus = .synced(Date())
            
            // Play haptic on successful sync
            WKInterfaceDevice.current().play(.click)
            
        } catch {
            print("Failed to load state: \(error)")
            syncStatus = .error("Load failed: \(error.localizedDescription)")
            
            // Keep default state as fallback
            petState = .default
        }
    }
    
    // MARK: - State Saving
    
    func saveState() async {
        // Debounce writes
        let now = Date()
        guard now.timeIntervalSince(lastWriteTime) > writeDebounceInterval else {
            return
        }
        lastWriteTime = now
        
        syncStatus = .syncing
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(petState)
            
            try writeStateFile(data: data)
            
            syncStatus = .synced(Date())
            
        } catch {
            print("Failed to save state: \(error)")
            syncStatus = .error("Save failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Pet Interactions
    
    func feed() async {
        guard !petState.isSleeping else {
            // Can't feed while sleeping
            WKInterfaceDevice.current().play(.failure)
            return
        }
        
        petState.hunger = min(100, petState.hunger + 20)
        petState.lastFed = Date()
        petState.mood = "happy"
        
        await saveState()
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
        
        // XP gain
        petState.xp += 5
        
        await saveState()
        WKInterfaceDevice.current().play(.success)
    }
    
    func pet() async {
        petState.happiness = min(100, petState.happiness + 10)
        petState.lastPet = Date()
        petState.mood = "happy"
        
        await saveState()
        WKInterfaceDevice.current().play(.click)
    }
    
    func toggleSleep() async {
        petState.isSleeping.toggle()
        petState.lastCheckTime = Date()
        
        await saveState()
        WKInterfaceDevice.current().play(.click)
    }
    
    // MARK: - File I/O
    
    private func readStateFile() throws -> Data {
        let fileURL = URL(fileURLWithPath: stateFilePath)
        
        guard FileManager.default.fileExists(atPath: stateFilePath) else {
            // Create default state file if it doesn't exist
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let defaultData = try encoder.encode(PetState.default)
            try defaultData.write(to: fileURL)
            return defaultData
        }
        
        return try Data(contentsOf: fileURL)
    }
    
    private func writeStateFile(data: Data) throws {
        let fileURL = URL(fileURLWithPath: stateFilePath)
        try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUnlessOpen])
    }
    
    // MARK: - File Watching
    
    private func startFileWatching() {
        stopFileWatching()
        
        let fileDescriptor = open(stateFilePath, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            print("Failed to open file for monitoring")
            return
        }
        
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: .write,
            queue: DispatchQueue.global(qos: .utility)
        )
        
        source.setEventHandler { [weak self] in
            // File changed externally, reload after short delay to avoid race conditions
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self?.loadState()
            }
        }
        
        source.setCancelHandler {
            close(fileDescriptor)
        }
        
        source.resume()
        fileMonitor = source
    }
    
    private func stopFileWatching() {
        fileMonitor?.cancel()
        fileMonitor = nil
    }
    
    // MARK: - Periodic Sync
    
    private func startSyncTimer() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.loadState()
            }
        }
    }
    
    // MARK: - Manual Refresh
    
    func forceRefresh() {
        loadState()
    }
}
