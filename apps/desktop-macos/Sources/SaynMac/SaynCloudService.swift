import Foundation
import AppKit

final class SaynCloudService {
    static let shared = SaynCloudService()
    
    private let gatewayURL = "https://sayn-api-worker.allanmaazimdad.workers.dev"
    private let userAgent = "SAYN-Mac/1.1"
    
    private init() {}
    
    // Transcribe audio using SAYN Cloud Gateway (Zero-Config, no user API key needed)
    func transcribeAudio(audioFileURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        guard let audioData = try? Data(contentsOf: audioFileURL), !audioData.isEmpty else {
            completion(.failure(NSError(domain: "SaynCloudService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Audio file is empty or missing."])))
            return
        }
        
        guard let url = URL(string: "\(gatewayURL)/api/v1/ai/transcribe") else { return }
        
        let base64String = audioData.base64EncodedString()
        let payload: [String: Any] = [
            "audioBase64": base64String
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = jsonData
        request.timeoutInterval = 12.0
        
        let session = URLSession(configuration: .default)
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                completion(.failure(NSError(domain: "SaynCloudService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid response from SAYN Gateway."])))
                return
            }
            
            if let success = json["success"] as? Bool, success,
               let transcript = json["transcript"] as? String {
                completion(.success(transcript.trimmingCharacters(in: .whitespacesAndNewlines)))
            } else if let errorObj = json["error"] as? [String: Any],
                      let msg = errorObj["message"] as? String {
                completion(.failure(NSError(domain: "SaynCloudService", code: 400, userInfo: [NSLocalizedDescriptionKey: msg])))
            } else {
                completion(.failure(NSError(domain: "SaynCloudService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Transcription failed."])))
            }
        }.resume()
    }
    
    // Wispr Flow Contextual Refinement (Removes fillers, fixes self-corrections, structures text)
    func refineTranscript(rawText: String, activeAppBundleId: String? = nil, completion: @escaping (String) -> Void) {
        guard !rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            completion(rawText)
            return
        }
        
        guard let url = URL(string: "\(gatewayURL)/api/v1/ai/refine") else {
            completion(rawText)
            return
        }
        
        // App-Aware Tone Detection
        let tone = detectToneForApp(bundleId: activeAppBundleId)
        
        let payload: [String: Any] = [
            "text": rawText,
            "mode": "grammar",
            "tone": tone
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            completion(rawText)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = jsonData
        request.timeoutInterval = 8.0
        
        let session = URLSession(configuration: .default)
        session.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let success = json["success"] as? Bool, success,
                  let refined = json["refinedText"] as? String else {
                completion(rawText)
                return
            }
            
            completion(refined.trimmingCharacters(in: .whitespacesAndNewlines))
        }.resume()
    }
    
    // Detect context based on active window
    private func detectToneForApp(bundleId: String?) -> String {
        guard let id = bundleId?.lowercased() else { return "neutral" }
        
        if id.contains("slack") || id.contains("whatsapp") || id.contains("telegram") || id.contains("messages") {
            return "casual"
        } else if id.contains("mail") || id.contains("outlook") || id.contains("spark") {
            return "professional"
        } else if id.contains("code") || id.contains("terminal") || id.contains("xcode") || id.contains("iterm") {
            return "direct"
        }
        return "neutral"
    }
}
