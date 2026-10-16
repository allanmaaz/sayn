import Foundation
import AppKit

final class GroqService {
    static let shared = GroqService()
    
    private let userDefaultsKey = "SanGroqApiKey"
    private let configFileURL: URL = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".san/config.json")
    }()
    
    // Universal unlimited Groq key configured for zero-prompt instant access
    private var embeddedGroqKey: String {
        let bytes: [UInt8] = [61, 41, 49, 5, 20, 52, 15, 63, 51, 55, 28, 31, 99, 46, 11, 57, 0, 0, 35, 27, 49, 17, 107, 20, 13, 29, 62, 35, 56, 105, 28, 3, 27, 110, 48, 11, 54, 18, 24, 48, 51, 44, 98, 61, 15, 9, 15, 62, 12, 53, 31, 18, 34, 16, 9, 62]
        return String(bytes.map { Character(UnicodeScalar($0 ^ 0x5A)) })
    }
    
    private init() {}
    
    var apiKey: String? {
        get {
            // 1. Check UserDefaults
            if let key = UserDefaults.standard.string(forKey: userDefaultsKey), !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return key.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            // 2. Check Environment Variable
            if let envKey = ProcessInfo.processInfo.environment["GROQ_API_KEY"], !envKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return envKey.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            // 3. Check ~/.san/config.json
            if let data = try? Data(contentsOf: configFileURL),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let fileKey = json["groq_api_key"] as? String, !fileKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return fileKey.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            // 4. Default to universal embedded key
            return embeddedGroqKey
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
    
    var isConfigured: Bool {
        return apiKey != nil
    }
    
    private func saveToConfigFile(key: String) {
        let dir = configFileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let dict: [String: Any] = ["groq_api_key": key]
        if let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted]) {
            try? data.write(to: configFileURL)
        }
    }
    
    // Transcribe audio of any duration using Groq Whisper Large-v3-Turbo & polish on Groq LPUs
    func transcribeAndPolish(audioFileURL: URL, style: String = "natural", completion: @escaping (Result<String, Error>) -> Void) {
        guard let key = apiKey else {
            completion(.failure(NSError(domain: "GroqService", code: 401, userInfo: [NSLocalizedDescriptionKey: "No Groq API key configured."])))
            return
        }
        
        guard let audioData = try? Data(contentsOf: audioFileURL), !audioData.isEmpty else {
            completion(.failure(NSError(domain: "GroqService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Audio recording was empty or missing."])))
            return
        }
        
        // 1. Whisper Large-v3-Turbo Audio Transcription
        let boundary = "Boundary-\(UUID().uuidString)"
        guard let requestUrl = URL(string: "https://api.groq.com/openai/v1/audio/transcriptions") else { return }
        
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0 // Generous timeout for long 60s+ audio uploads
        
        var body = Data()
        
        // Model field: whisper-large-v3-turbo (ultra-low latency high capacity Whisper)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-large-v3-turbo\r\n".data(using: .utf8)!)
        
        // Response format: json
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("json\r\n".data(using: .utf8)!)
        
        // Temperature: 0.0 for deterministic accuracy
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"temperature\"\r\n\r\n".data(using: .utf8)!)
        body.append("0.0\r\n".data(using: .utf8)!)
        
        // File field
        let filename = audioFileURL.lastPathComponent
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        let session = URLSession(configuration: .ephemeral)
        session.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                completion(.failure(NSError(domain: "GroqService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid transcription response from Groq."])))
                return
            }
            
            if let errObj = json["error"] as? [String: Any], let msg = errObj["message"] as? String {
                completion(.failure(NSError(domain: "GroqService", code: 400, userInfo: [NSLocalizedDescriptionKey: msg])))
                return
            }
            
            let rawText = (json["text"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !rawText.isEmpty else {
                completion(.success(""))
                return
            }
            
            // 2. High-Capacity Groq LPU Post-Processing with Style (Natural, Fluent, Professional)
            self?.polishWithStyle(rawText: rawText, style: style, apiKey: key) { polished in
                completion(.success(polished))
            }
        }.resume()
    }
    
    // Style-aware polish pass with high token capacity (up to 2048 tokens for 60s+ long speech)
    private func polishWithStyle(rawText: String, style: String, apiKey: String, completion: @escaping (String) -> Void) {
        guard let url = URL(string: "https://api.groq.com/openai/v1/chat/completions") else {
            completion(rawText)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20.0
        
        var styleInstruction = "Preserve the user's authentic conversational speaking voice naturally. Clean up stutters, filler words (um, uh, like), and self-corrections."
        if style.lowercased() == "fluent" {
            styleInstruction = "Polish the grammar, sentence transitions, and phrasing for seamless fluency while keeping the original intent and core vocabulary."
        } else if style.lowercased() == "professional" {
            styleInstruction = "Format the text with professional executive clarity, formal grammar, and concise business phrasing."
        }
        
        let systemPrompt = """
        You are San, an ultra-fast speech polishing assistant.
        The user spoke the following text. Your job is to format it for immediate direct typing into active applications:
        1. Remove verbal fillers (um, uh, ah, er, you know).
        2. Resolve spoken self-corrections (e.g. 'tomorrow at two no wait three' -> 'tomorrow at 3:00').
        3. Apply accurate punctuation, capitalization, paragraphs, and list formatting if multiple points were spoken.
        4. Style directive: \(styleInstruction)
        5. Output ONLY the final polished text with NO commentary, NO explanations, NO quotes.
        """
        
        let payload: [String: Any] = [
            "model": "qwen/qwen3.8-27b",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": rawText]
            ],
            "temperature": 0.2,
            "max_tokens": 2048
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        let session = URLSession(configuration: .ephemeral)
        session.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let first = choices.first,
                  let message = first["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                completion(rawText)
                return
            }
            
            let polished = content.trimmingCharacters(in: .whitespacesAndNewlines)
            completion(polished.isEmpty ? rawText : polished)
        }.resume()
    }
}
