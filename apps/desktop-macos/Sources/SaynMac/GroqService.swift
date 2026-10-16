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
    private let configFileURL: URL = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".sayn/config.json")
    }()
    private let fallbackConfigFileURL: URL = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".san/config.json")
    }()
    
    // Universal embedded Groq key configured for zero-prompt instant access
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
            if let oldKey = UserDefaults.standard.string(forKey: "SanGroqApiKey"), !oldKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return oldKey.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            // 2. Check Environment Variable
            if let envKey = ProcessInfo.processInfo.environment["GROQ_API_KEY"], !envKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return envKey.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            // 3. Check ~/.sayn/config.json or ~/.san/config.json
            for url in [configFileURL, fallbackConfigFileURL] {
                if let data = try? Data(contentsOf: url),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let fileKey = json["groq_api_key"] as? String, !fileKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return fileKey.trimmingCharacters(in: .whitespacesAndNewlines)
                }
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
    
    // Transcribe audio with Groq Whisper Large-v3-Turbo + domain vocabulary biasing + mode execution
    func transcribeAndPolish(
        audioFileURL: URL,
        mode: SanExecutionMode = .dictate,
        style: String = "natural",
        contextText: String? = nil,
        activeAppBundleId: String? = nil,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let key = apiKey else {
            completion(.failure(NSError(domain: "GroqService", code: 401, userInfo: [NSLocalizedDescriptionKey: "No Groq API key configured."])))
            return
        }
        
        guard let audioData = try? Data(contentsOf: audioFileURL), !audioData.isEmpty else {
            completion(.failure(NSError(domain: "GroqService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Audio recording was empty or missing."])))
            return
        }
        
        // 1. Whisper Large-v3-Turbo Audio Transcription with Vocabulary Biasing
        let boundary = "Boundary-\(UUID().uuidString)"
        guard let requestUrl = URL(string: "https://api.groq.com/openai/v1/audio/transcriptions") else { return }
        
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60.0
        
        var body = Data()
        
        // Model field: whisper-large-v3-turbo
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-large-v3-turbo\r\n".data(using: .utf8)!)
        
        // Response format: json
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("json\r\n".data(using: .utf8)!)
        
        // Vocabulary Prompt Biasing (Whisper prompt parameter)
        let vocabPrompt = SaynVoicePolisher.shared.loadVocabularyPrompt()
        if !vocabPrompt.isEmpty {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(vocabPrompt)\r\n".data(using: .utf8)!)
        }
        
        // Temperature: 0.0 for deterministic transcription accuracy
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
            
            // 2. Check for Instant Snippet Expansion
            if let snippet = SaynVoicePolisher.shared.expandSnippet(from: rawText) {
                completion(.success(snippet))
                return
            }
            
            // 3. Mode-Aware Groq LPU Processing
            self?.executeMode(
                rawText: rawText,
                mode: mode,
                style: style,
                contextText: contextText,
                appBundleId: activeAppBundleId,
                apiKey: key
            ) { result in
                completion(.success(result))
            }
        }.resume()
    }
    
    /// Public direct text refinement using Groq LPU with natural human flow
    func refineText(
        text: String,
        mode: SanExecutionMode = .dictate,
        style: String = "natural",
        completion: @escaping (String) -> Void
    ) {
        guard let key = apiKey else {
            let fallback = SaynVoicePolisher.shared.polishLocally(text)
            completion(fallback)
            return
        }
        executeMode(
            rawText: text,
            mode: mode,
            style: style,
            contextText: nil,
            appBundleId: nil,
            apiKey: key,
            completion: completion
        )
    }
    
    // High-capacity LPU mode execution
    private func executeMode(
        rawText: String,
        mode: SanExecutionMode,
        style: String,
        contextText: String?,
        appBundleId: String?,
        apiKey: String,
        completion: @escaping (String) -> Void
    ) {
        guard let url = URL(string: "https://api.groq.com/openai/v1/chat/completions") else {
            completion(rawText)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 45.0
        
        let systemPrompt: String
        let userContent: String
        
        switch mode {
        case .prompt:
            // Prompt / Instruction Mode
            if let ctx = contextText, !ctx.isEmpty {
                systemPrompt = """
                You are SAYN AI Assistant in Prompt Mode.
                The user selected the following context text:
                \"\"\"
                \(ctx)
                \"\"\"
                Execute the user's spoken instruction precisely on the selected text.
                Format the result cleanly for direct typing into their application.
                Output ONLY the final result with NO conversational filler, NO quotes, NO preamble.
                """
                userContent = "Instruction: \(rawText)"
            } else {
                systemPrompt = """
                You are SAYN AI Assistant in Prompt Mode.
                The user spoke a request or prompt to generate text.
                Generate the requested content with clarity, correct structure, and natural tone.
                Output ONLY the generated text with NO conversational filler, NO quotes, NO preamble.
                """
                userContent = rawText
            }
            
        case .translate:
            // Live Translation Mode (Polyglot to English)
            systemPrompt = """
            You are SAYN Universal Translator.
            The user spoke in a foreign language (or mixed languages).
            Accurately translate the spoken words into polished, fluent, modern English.
            Remove verbal fillers and resolve any spoken self-corrections during translation.
            Output ONLY the English translation with NO explanations, NO quotes, NO notes.
            """
            userContent = rawText
            
        case .code:
            // Developer & Code Mode
            systemPrompt = """
            You are SAYN Developer Voice Assistant.
            Format the user's spoken words specifically for programming and developer tools:
            1. When function or variable names are spoken (e.g., 'get user profile by id'), format in camelCase (`getUserProfileById`) or snake_case as fitting.
            2. When git commits are spoken ('fix header alignment'), format as conventional commit (`fix(ui): header alignment`).
            3. When terminal commands or code blocks are spoken, wrap appropriately with backticks.
            4. Preserve precise developer syntax and remove spoken fillers.
            5. Output ONLY the formatted code or technical text with NO preamble.
            """
            userContent = rawText
            
        case .proofread:
            // Grammar & Proofread Mode
            let textToProof = (contextText != nil && !contextText!.isEmpty) ? contextText! : rawText
            systemPrompt = """
            You are SAYN Proofreader & Grammar Polisher.
            Fix all spelling errors, grammatical mistakes, awkward phrasing, and punctuation.
            Elevate sentence flow while preserving the author's original meaning and voice.
            Output ONLY the corrected, polished text with NO explanations, NO markdown backticks, NO quotes.
            """
            userContent = (contextText != nil && !contextText!.isEmpty)
                ? "Text to fix:\n\(textToProof)\n\nAdditional instructions: \(rawText)"
                : textToProof
            
        case .dictate:
            // Dictation Mode with Per-App Adaptation & Style
            var appDirective = ""
            if let bundle = appBundleId?.lowercased() {
                if bundle.contains("slack") || bundle.contains("discord") || bundle.contains("whatsapp") || bundle.contains("telegram") || bundle.contains("messages") {
                    appDirective = "App Context: Quick Chat (\(bundle)). Keep sentences punchy, conversational, and natural for instant messaging."
                } else if bundle.contains("mail") || bundle.contains("outlook") {
                    appDirective = "App Context: Email Client (\(bundle)). Format with professional executive clarity, polite tone, and clean paragraph breaks."
                } else if bundle.contains("vscode") || bundle.contains("cursor") || bundle.contains("xcode") || bundle.contains("terminal") {
                    appDirective = "App Context: Code Editor (\(bundle)). Use technical precision, clean markdown formatting, and exact terminology."
                } else if bundle.contains("notion") || bundle.contains("notes") || bundle.contains("obsidian") {
                    appDirective = "App Context: Notes & Docs (\(bundle)). Format with clean bullet points and hierarchical structure where appropriate."
                }
            }
            
            var styleInstruction = "Preserve the user's authentic conversational speaking voice naturally. Clean up stutters, filler words (um, uh, like), and self-corrections. Keep punctuation light, natural, and human — avoid excessive commas or choppy full stops."
            if style.lowercased() == "fluent" {
                styleInstruction = "Polish the grammar, sentence transitions, and phrasing for seamless fluency while keeping the original intent. Keep punctuation light and natural without excessive commas, full stops, or underscores."
            } else if style.lowercased() == "professional" {
                styleInstruction = "Format the text with professional clarity, articulate phrasing, and clean sentence flow without robotic or heavy punctuation."
            }
            
            systemPrompt = """
            You are SAYN, an ultra-fast speech polishing assistant.
            The user spoke the following text. Your job is to format it for immediate direct typing into active applications:
            1. Remove verbal fillers (um, uh, ah, er, you know).
            2. Resolve spoken self-corrections (e.g. 'tomorrow at two no wait three' -> 'tomorrow at 3:00').
            3. Natural Human Punctuation: Keep punctuation light and conversational. Do NOT overuse commas, full stops, or underscores. Never break up natural flowing speech into choppy, robotic mini-sentences.
            4. Honor voice commands: 'new line' -> newline, 'new paragraph' -> paragraph break, 'bullet point' -> '• '.
            5. Style directive: \(styleInstruction)
            6. \(appDirective)
            7. Output ONLY the final polished text with NO commentary, NO explanations, NO quotes, NO underscores.
            """
            userContent = rawText
        }
        
        let payload: [String: Any] = [
            "model": "qwen/qwen3.8-27b",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userContent]
            ],
            "temperature": (mode == .code || mode == .proofread) ? 0.1 : 0.2,
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
                let localPolished = SaynVoicePolisher.shared.polishLocally(rawText, appBundleId: appBundleId)
                completion(localPolished)
                return
            }
            
            let polished = content.trimmingCharacters(in: .whitespacesAndNewlines)
            completion(polished.isEmpty ? rawText : polished)
        }.resume()
    }
}
