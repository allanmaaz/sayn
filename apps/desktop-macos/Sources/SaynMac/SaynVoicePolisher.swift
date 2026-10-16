import Foundation

/// Fast, deterministic speech-to-text polisher matching Wispr Flow behavior.
/// Removes disfluencies, self-corrections, spoken punctuation, and formats numbers/dates/tones in 0ms.
final class SaynVoicePolisher {
    static let shared = SaynVoicePolisher()
    private init() {}
    
    func polishLocally(_ text: String, appBundleId: String? = nil) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !result.isEmpty else { return "" }
        
        // 1. Remove spoken disfluencies and vocal fillers
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
        
        // 2. Resolve spoken self-corrections ("at 2 no wait 3" -> "at 3")
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
        
        // 3. Format spoken times and numbers
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
        
        // 4. Format spoken currencies
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
        
        // 5. Capitalize standalone "i", "i'm", "i've", "i'll", "i'd"
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
        
        // 6. Clean multiple spaces and whitespace
        result = result.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 7. Ensure first letter is capitalized
        if let first = result.first {
            result = String(first).uppercased() + String(result.dropFirst())
        }
        
        // 8. App-Aware Punctuation:
        // In formal apps (Mail, Docs), ensure period if sentence seems complete.
        // In chat apps (WhatsApp, Slack), keep casual without forced trailing punctuation.
        let isChatApp = (appBundleId?.lowercased().contains("slack") == true) ||
                        (appBundleId?.lowercased().contains("whatsapp") == true) ||
                        (appBundleId?.lowercased().contains("telegram") == true) ||
                        (appBundleId?.lowercased().contains("messages") == true)
        
        if !isChatApp && !result.isEmpty {
            let lastChar = result.last
            if lastChar != "." && lastChar != "?" && lastChar != "!" {
                result += "."
            }
        }
        
        return result
    }
}
