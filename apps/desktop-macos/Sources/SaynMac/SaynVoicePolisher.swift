import Foundation

/// Fast, deterministic speech-to-text polisher for SAYN voice flow.
/// Handles voice commands, disfluencies, self-corrections, snippet macros, and per-app formatting.
final class SaynVoicePolisher {
    static let shared = SaynVoicePolisher()
    
    private let snippetsFileURL: URL = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".sayn/snippets.json")
    }()
    
    private let fallbackSnippetsFileURL: URL = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".san/snippets.json")
    }()
    
    private let vocabularyFileURL: URL = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".sayn/vocabulary.json")
    }()
    
    private let fallbackVocabularyFileURL: URL = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".san/vocabulary.json")
    }()
    
    private init() {
        ensureDefaultConfigFiles()
    }
    
    private func ensureDefaultConfigFiles() {
        let saynDir = snippetsFileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: saynDir, withIntermediateDirectories: true)
        
        // 1. Initialize default snippets if not present
        if !FileManager.default.fileExists(atPath: snippetsFileURL.path) && !FileManager.default.fileExists(atPath: fallbackSnippetsFileURL.path) {
            let defaultSnippets: [String: Any] = [
                "snippets": [
                    [
                        "trigger": "insert standup",
                        "template": "Daily Standup:\n- Yesterday: \n- Today: \n- Blockers: None"
                    ],
                    [
                        "trigger": "insert meeting notes",
                        "template": "Meeting Notes\nDate: {date}\nAttendees: \n\nAgenda:\n- \n\nKey Decisions:\n- \n\nAction Items:\n- [ ] "
                    ],
                    [
                        "trigger": "insert signature",
                        "template": "Best regards,\nSent with SAYN AI Voice"
                    ],
                    [
                        "trigger": "insert bug report",
                        "template": "Bug Report:\n- Description: \n- Steps to Reproduce:\n  1. \n- Expected Result: \n- Actual Result: "
                    ]
                ]
            ]
            if let data = try? JSONSerialization.data(withJSONObject: defaultSnippets, options: [.prettyPrinted]) {
                try? data.write(to: snippetsFileURL)
            }
        }
        
        // 2. Initialize default custom vocabulary if not present
        if !FileManager.default.fileExists(atPath: vocabularyFileURL.path) && !FileManager.default.fileExists(atPath: fallbackVocabularyFileURL.path) {
            let defaultVocab: [String: Any] = [
                "terms": [
                    "SAYN", "Groq", "LPU", "Whisper", "Flutter", "SwiftUI",
                    "PostgreSQL", "Next.js", "TypeScript", "Tailwind", "Kubernetes",
                    "Docker", "GraphQL", "GitHub", "API", "JSON", "SDK", "OAuth"
                ]
            ]
            if let data = try? JSONSerialization.data(withJSONObject: defaultVocab, options: [.prettyPrinted]) {
                try? data.write(to: vocabularyFileURL)
            }
        }
    }
    
    // Load custom vocabulary terms as a comma-separated prompt for Whisper biasing
    func loadVocabularyPrompt() -> String {
        for url in [vocabularyFileURL, fallbackVocabularyFileURL] {
            if let data = try? Data(contentsOf: url),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let terms = json["terms"] as? [String], !terms.isEmpty {
                return terms.joined(separator: ", ")
            }
        }
        return "SAYN, Groq, Whisper, SwiftUI, Flutter, TypeScript, API"
    }
    
    // Check if spoken text matches a registered snippet template
    func expandSnippet(from rawText: String) -> String? {
        for url in [snippetsFileURL, fallbackSnippetsFileURL] {
            if let data = try? Data(contentsOf: url),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let snippets = json["snippets"] as? [[String: String]] {
                let cleaned = rawText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                for snippet in snippets {
                    if let trigger = snippet["trigger"]?.lowercased(),
                       let template = snippet["template"] {
                        if cleaned == trigger || cleaned.contains(trigger) {
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateStyle = .medium
                            let dateStr = dateFormatter.string(from: Date())
                            return template.replacingOccurrences(of: "{date}", with: dateStr)
                        }
                    }
                }
            }
        }
        return nil
    }
    
    func polishLocally(_ text: String, appBundleId: String? = nil) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !result.isEmpty else { return "" }
        
        // Check for instant snippet expansion
        if let snippet = expandSnippet(from: result) {
            return snippet
        }
        
        // 1. Hands-Free Voice Formatting Commands
        let scratchPatterns = [
            "(?i).*?\\b(?:scratch that|delete that|cancel that)\\b\\s*",
            "(?i).*?\\b(?:scratch last sentence|delete last sentence)\\b\\s*"
        ]
        for pattern in scratchPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(location: 0, length: result.utf16.count)
                result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "")
            }
        }
        
        // Spoken linebreaks & formatting
        let formattingCommands: [(String, String)] = [
            ("(?i)\\b(?:new paragraph|next paragraph)\\b", "\n\n"),
            ("(?i)\\b(?:new line|next line)\\b", "\n"),
            ("(?i)\\b(?:bullet point|bullet)\\b", "\n• "),
            ("(?i)\\bsemi-?colon\\b", ";"),
            ("(?i)\\bcolon\\b", ":")
        ]
        for (pattern, template) in formattingCommands {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(location: 0, length: result.utf16.count)
                result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: template)
            }
        }
        
        // 2. Remove spoken disfluencies and vocal fillers
        let fillerPatterns = [
            "\\b(?i)um+,?\\b",
            "\\b(?i)uh+,?\\b",
            "\\b(?i)er+,?\\b",
            "\\b(?i)ah+,?\\b",
            "\\b(?i)umm+,?\\b",
            "\\b(?i)uhh+,?\\b",
            "\\b(?i)you know,?\\b",
            "\\b(?i)so basically,?\\b",
            "\\b(?i)basically,?\\b",
            "\\b(?i)literally,?\\b",
            "\\b(?i)kind of,?\\b",
            "\\b(?i)sort of,?\\b",
            "\\b(?i)i mean,?\\b"
        ]
        
        for pattern in fillerPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(location: 0, length: result.utf16.count)
                result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "")
            }
        }
        
        // 3. Resolve spoken self-corrections ("at 2 no wait 3" -> "at 3")
        let selfCorrectionPatterns: [(String, String)] = [
            ("\\b(\\w+)\\s+(?:no wait|wait no|actually|sorry)\\s+(\\w+)\\b", "$2"),
            ("\\b(?:or rather|make that)\\s+(\\w+)\\b", "$1")
        ]
        
        for (pattern, template) in selfCorrectionPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(location: 0, length: result.utf16.count)
                result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: template)
            }
        }
        
        // 4. Format spoken times and numbers
        let timePatterns: [(String, String)] = [
            ("(?i)\\b(\\d+)\\s*o'?clock\\b", "$1:00"),
            ("(?i)\\b(\\d+)\\s*(am|pm)\\b", "$1:00 $2"),
            ("(?i)\\b(\\d+)\\s+(\\d{2})\\s*(am|pm)\\b", "$1:$2 $3")
        ]
        
        for (pattern, template) in timePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(location: 0, length: result.utf16.count)
                result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: template)
            }
        }
        
        // 5. Format spoken currencies
        let currencyPatterns: [(String, String)] = [
            ("(?i)\\b(\\d+)\\s*dollars?\\b", "$$$1"),
            ("(?i)\\b(\\d+)\\s*bucks?\\b", "$$$1"),
            ("(?i)\\b(\\d+)\\s*percent\\b", "$1%")
        ]
        
        for (pattern, template) in currencyPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(location: 0, length: result.utf16.count)
                result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: template)
            }
        }
        
        // 6. Capitalize standalone "i", "i'm", "i've", "i'll", "i'd"
        let pronounPatterns: [(String, String)] = [
            ("\\b(?i)i\\b", "I"),
            ("\\b(?i)i'm\\b", "I'm"),
            ("\\b(?i)i've\\b", "I've"),
            ("\\b(?i)i'll\\b", "I'll"),
            ("\\b(?i)i'd\\b", "I'd")
        ]
        
        for (pattern, template) in pronounPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(location: 0, length: result.utf16.count)
                result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: template)
            }
        }
        
        // 7. Clean whitespace
        result = result.replacingOccurrences(of: "[ \\t]+", with: " ", options: .regularExpression)
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 8. Ensure first letter is capitalized
        if let first = result.first {
            result = String(first).uppercased() + String(result.dropFirst())
        }
        
        // 9. App-Aware Punctuation
        let isChatApp = (appBundleId?.lowercased().contains("slack") == true) ||
                        (appBundleId?.lowercased().contains("whatsapp") == true) ||
                        (appBundleId?.lowercased().contains("telegram") == true) ||
                        (appBundleId?.lowercased().contains("messages") == true)
        
        if !isChatApp && !result.isEmpty && !result.contains("\n") {
            let lastChar = result.last
            if lastChar != "." && lastChar != "?" && lastChar != "!" {
                result += "."
            }
        }
        
        return result
    }
}
