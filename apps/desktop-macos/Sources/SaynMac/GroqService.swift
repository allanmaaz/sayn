import Foundation
import AppKit

enum SanExecutionMode: String, CaseIterable {
    case dictate = "dictate"
    case prompt = "prompt"
    case translate = "translate"
    case code = "code"
    case proofread = "proofread"
    
    var displayName: String {
        switch self {
        case .dictate: return "Dictate"
        case .prompt: return "Prompt"
        case .translate: return "Translate"
        case .code: return "Code"
        case .proofread: return "Proofread"
        }
    }
    
    var statusTitle: String {
        switch self {
        case .dictate: return "SAYN Polishing..."
        case .prompt: return "SAYN Prompting..."
        case .translate: return "SAYN Translating..."
        case .code: return "SAYN Coding..."
        case .proofread: return "SAYN Proofreading..."
        }
    }
    
    var accentHex: String {
        switch self {
        case .dictate: return "6F1025"   // Deep Maroon
        case .prompt: return "A83249"    // Soft Rose-Maroon
        case .translate: return "8F1835" // Rose Maroon Tint
        case .code: return "6F1025"      // Deep Maroon
        case .proofread: return "A83249" // Soft Rose-Maroon
        }
    }
}

final class GroqService {
    static let shared = GroqService()
    
    private let userDefaultsKey = "SaynGroqApiKey"
    private let gatewayURL = "https://sayn-api-worker.allanmaazimdad.workers.dev"
    private let anonToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV0ZXZsZ2R5cXFhdnZ0bW9rd3ZvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE3NDIyMDAsImV4cCI6MjEwNzMxODIwMH0.gudEGqLAnR0lT9irIqA89eVR_Iqcg1in2M7lbFcd5vI"
    
    private let configFileURL: URL = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".sayn/config.json")
    }()
    private let fallbackConfigFileURL: URL = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".san/config.json")
    }()
    
    private init() {}
    
    var customApiKey: String? {
        get {
            // Check UserDefaults
            if let key = UserDefaults.standard.string(forKey: userDefaultsKey),
               !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return key.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            // Check environment variable
            if let envKey = ProcessInfo.processInfo.environment["GROQ_API_KEY"],
               !envKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return envKey.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            // Check ~/.sayn/config.json
            for url in [configFileURL, fallbackConfigFileURL] {
                if let data = try? Data(contentsOf: url),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let fileKey = json["groq_api_key"] as? String,
                   !fileKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                   !fileKey.hasPrefix("gsk_NnUeimFE") { // Skip known revoked key
                    return fileKey.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            return nil
        }
        set {
            if let val = newValue?.trimmingCharacters(in: .whitespacesAndNewlines), !val.isEmpty {
                UserDefaults.standard.set(val, forKey: userDefaultsKey)
                saveToConfigFile(key: val)
            } else {
                UserDefaults.standard.removeObject(forKey: userDefaultsKey)
            }
        }
    }
    
    private func saveToConfigFile(key: String) {
        let dir = configFileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let dict: [String: Any] = ["groq_api_key": key]
        if let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted]) {
            try? data.write(to: configFileURL)
        }
    }
    
    /// Multi-tier speech transcription and AI polishing:
    /// 1. Tries user's custom Groq key if configured
    /// 2. Primary Tier: SAYN Cloud Gateway (Google Gemini 3.5 Flash Lite multimodal STT)
    /// 3. Offline Tier: Local deterministic voice polisher
    func transcribeAndPolish(
        audioFileURL: URL,
        mode: SanExecutionMode = .dictate,
        style: String = "natural",
        contextText: String? = nil,
        activeAppBundleId: String? = nil,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let audioData = try? Data(contentsOf: audioFileURL), !audioData.isEmpty else {
            completion(.failure(NSError(domain: "GroqService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Audio recording was empty or missing."])))
            return
        }
        
        // Tier 1: If user supplied a valid custom Groq key
        if let groqKey = customApiKey, !groqKey.isEmpty {
            transcribeWithGroq(audioData: audioData, filename: audioFileURL.lastPathComponent, apiKey: groqKey) { [weak self] result in
                switch result {
                case .success(let rawText):
                    self?.processTranscript(
                        rawText: rawText,
                        mode: mode,
                        style: style,
                        contextText: contextText,
                        appBundleId: activeAppBundleId,
                        completion: completion
                    )
                case .failure:
                    // Fall back to SAYN Cloud Gateway
                    self?.transcribeWithGateway(audioData: audioData) { gwResult in
                        switch gwResult {
                        case .success(let rawText):
                            self?.processTranscript(
                                rawText: rawText,
                                mode: mode,
                                style: style,
                                contextText: contextText,
                                appBundleId: activeAppBundleId,
                                completion: completion
                            )
                        case .failure(let err):
                            completion(.failure(err))
                        }
                    }
                }
            }
            return
        }
        
        // Tier 2: Primary Cloud Gateway (Google Gemini Multimodal STT)
        transcribeWithGateway(audioData: audioData) { [weak self] gwResult in
            switch gwResult {
            case .success(let rawText):
                self?.processTranscript(
                    rawText: rawText,
                    mode: mode,
                    style: style,
                    contextText: contextText,
                    appBundleId: activeAppBundleId,
                    completion: completion
                )
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
    
    // MARK: - SAYN Cloudflare Gateway Transcribe
    private func transcribeWithGateway(audioData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "\(gatewayURL)/api/v1/ai/transcribe") else {
            completion(.failure(NSError(domain: "GroqService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid gateway URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(anonToken)", forHTTPHeaderField: "Authorization")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 25.0
        
        let base64 = audioData.base64EncodedString()
        let payload: [String: Any] = ["audioBase64": base64]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        let session = URLSession(configuration: .ephemeral)
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                completion(.failure(NSError(domain: "GroqService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response from Cloud Gateway"])))
                return
            }
            
            if let transcript = json["transcript"] as? String {
                let clean = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                let hallucinations: Set<String> = [
                    "00:00", "0:00", "You", "You.", "you", "Thank you.", "Thank you",
                    ".", "..", "...", "MBC", "Subtitles by", "Amara.org", "Thank you for watching.",
                    "thanks for watching"
                ]
                if hallucinations.contains(clean) || clean.allSatisfy({ $0.isPunctuation || $0.isWhitespace }) {
                    completion(.success(""))
                    return
                }
                completion(.success(clean))
                return
            }
            
            completion(.failure(NSError(domain: "GroqService", code: 422, userInfo: [NSLocalizedDescriptionKey: "No transcript in response"])))
        }.resume()
    }
    
    // MARK: - Direct Groq Whisper API (when custom key provided)
    private func transcribeWithGroq(audioData: Data, filename: String, apiKey: String, completion: @escaping (Result<String, Error>) -> Void) {
        let boundary = "Boundary-\(UUID().uuidString)"
        guard let url = URL(string: "https://api.groq.com/openai/v1/audio/transcriptions") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20.0
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-large-v3-turbo\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("json\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let session = URLSession(configuration: .ephemeral)
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let text = json["text"] as? String else {
                completion(.failure(NSError(domain: "GroqService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to parse Groq response"])))
                return
            }
            completion(.success(text.trimmingCharacters(in: .whitespacesAndNewlines)))
        }.resume()
    }
    
    // MARK: - Post-Transcription Processing
    private func processTranscript(
        rawText: String,
        mode: SanExecutionMode,
        style: String,
        contextText: String?,
        appBundleId: String?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let clean = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {
            completion(.success(""))
            return
        }
        
        // 1. Snippet Expansion Check
        if let snippet = SaynVoicePolisher.shared.expandSnippet(from: clean) {
            completion(.success(snippet))
            return
        }
        
        // 2. Direct Dictate Mode: Fast Local Natural Polish (Sub-5ms, Zero Excessive Punctuation)
        if mode == .dictate && style == "natural" {
            let polished = SaynVoicePolisher.shared.polishLocally(clean, appBundleId: appBundleId)
            completion(.success(polished))
            return
        }
        
        // 3. Cloud Polish for Complex Modes (Prompt, Translate, Code, Proofread)
        refineViaGateway(text: clean, mode: mode, style: style, contextText: contextText) { result in
            let finalOutput = result.isEmpty ? SaynVoicePolisher.shared.polishLocally(clean, appBundleId: appBundleId) : result
            completion(.success(finalOutput))
        }
    }
    
    // MARK: - Cloud Gateway Refine
    func refineText(
        text: String,
        mode: SanExecutionMode = .dictate,
        style: String = "natural",
        completion: @escaping (String) -> Void
    ) {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {
            completion("")
            return
        }
        
        refineViaGateway(text: clean, mode: mode, style: style, contextText: nil) { result in
            if !result.isEmpty {
                completion(result)
            } else {
                let local = SaynVoicePolisher.shared.polishLocally(clean)
                completion(local)
            }
        }
    }
    
    private func refineViaGateway(
        text: String,
        mode: SanExecutionMode,
        style: String,
        contextText: String?,
        completion: @escaping (String) -> Void
    ) {
        guard let url = URL(string: "\(gatewayURL)/api/v1/ai/refine") else {
            completion("")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(anonToken)", forHTTPHeaderField: "Authorization")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 18.0
        
        let apiMode: String
        switch mode {
        case .prompt: apiMode = "custom"
        case .translate: apiMode = "translate"
        case .code: apiMode = "standard"
        case .proofread: apiMode = "grammar"
        case .dictate: apiMode = style == "professional" ? "professional" : (style == "fluent" ? "fluent" : "standard")
        }
        
        var payload: [String: Any] = [
            "text": text,
            "mode": apiMode,
            "tone": style == "professional" ? "professional" : "neutral"
        ]
        if let ctx = contextText, !ctx.isEmpty {
            payload["customInstruction"] = "Context: \(ctx)"
        }
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        let session = URLSession(configuration: .ephemeral)
        session.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let refined = json["refinedText"] as? String else {
                completion("")
                return
            }
            completion(refined.trimmingCharacters(in: .whitespacesAndNewlines))
        }.resume()
    }
}
