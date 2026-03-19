import Foundation

// MARK: - Chat Message

struct ChatMessage: Codable, Identifiable {
    let id: UUID
    let role: String
    let content: String
    let date: Date

    init(role: String, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.date = Date()
    }
}

// MARK: - Watch Chat Service

/// HTTP client for OpenClaw Gateway chat completions
actor WatchChatService {
    static let shared = WatchChatService()

    private let maxHistoryCount = 20
    private let sessionDelegate = InsecureChatURLSessionDelegate()
    private let urlSession: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 60
        urlSession = URLSession(configuration: config, delegate: sessionDelegate, delegateQueue: nil)
    }

    // MARK: - Configuration

    var isConfigured: Bool {
        endpoint != nil && token != nil
    }

    var endpoint: String? {
        get { UserDefaults.standard.string(forKey: "agent_endpoint") }
    }

    var token: String? {
        get { UserDefaults.standard.string(forKey: "agent_token") }
    }

    nonisolated func configure(endpoint: String, token: String) {
        UserDefaults.standard.set(endpoint, forKey: "agent_endpoint")
        UserDefaults.standard.set(token, forKey: "agent_token")
    }

    // MARK: - Chat Completion

    func sendMessage(_ text: String, history: [ChatMessage]) async throws -> String {
        guard let endpoint = endpoint, let token = token else {
            throw ChatError.notConfigured
        }

        let urlString = endpoint.hasSuffix("/")
            ? "\(endpoint)v1/chat/completions"
            : "\(endpoint)/v1/chat/completions"

        guard let url = URL(string: urlString) else {
            throw ChatError.invalidURL
        }

        // Build messages array from history (last N) + new message
        var messages: [[String: String]] = []

        // System message
        messages.append([
            "role": "system",
            "content": "You are Clawbert, a friendly AI cat assistant on the user's Apple Watch. Keep responses very short (1-2 sentences) since this is a small screen."
        ])

        // Recent history
        let recentHistory = history.suffix(maxHistoryCount)
        for msg in recentHistory {
            messages.append(["role": msg.role, "content": msg.content])
        }

        // New user message
        messages.append(["role": "user", "content": text])

        let body: [String: Any] = [
            "messages": messages,
            "stream": false
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw ChatError.httpError(httpResponse.statusCode)
        }

        // Parse OpenAI-compatible response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw ChatError.parseError
        }

        return content
    }
}

// MARK: - Chat Errors

enum ChatError: LocalizedError {
    case notConfigured
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case parseError

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Not configured"
        case .invalidURL: return "Invalid gateway URL"
        case .invalidResponse: return "Invalid response"
        case .httpError(let code): return "HTTP \(code)"
        case .parseError: return "Could not parse response"
        }
    }
}

// MARK: - URLSession Delegate for Self-Signed Certificates

final class InsecureChatURLSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
