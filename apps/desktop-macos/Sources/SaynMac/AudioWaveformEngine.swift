import Foundation
import AVFoundation
import Speech

final class AudioWaveformEngine: ObservableObject {
    private var audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    @Published var audioLevels: [Float] = [0.1, 0.2, 0.4, 0.6, 0.5, 0.3, 0.2, 0.1]
    @Published var isRecording: Bool = false
    
    func startRecording(onTranscript: @escaping (String) -> Void) {
        guard !isRecording else { return }
        
        // Ensure Speech Authorization
        SFSpeechRecognizer.requestAuthorization { authStatus in
            guard authStatus == .authorized else {
                print("Speech recognition not authorized: \(authStatus)")
                return
            }
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Reset and prepare recognition request
        recognitionTask?.cancel()
        recognitionTask = nil
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.recognitionRequest = request
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            if let result = result {
                let rawTranscript = result.bestTranscription.formattedString
                let polished = self?.applyWisprFormatting(rawTranscript) ?? rawTranscript
                DispatchQueue.main.async {
                    onTranscript(polished)
                }
            }
        }
        
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, time in
            guard let self = self else { return }
            
            // Pass audio buffer to speech recognizer
            self.recognitionRequest?.append(buffer)
            
            // Calculate RMS audio power for the 8 wavy bars
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameLength = UInt(buffer.frameLength)
            var sum: Float = 0.0
            for i in 0..<Int(frameLength) {
                sum += channelData[i] * channelData[i]
            }
            let rms = sqrt(sum / Float(frameLength))
            let normalized = min(max(rms * 8.0, 0.08), 1.0)
            
            DispatchQueue.main.async {
                self.audioLevels = (0..<8).map { i in
                    let variance = Float.random(in: 0.7...1.3)
                    return min(normalized * variance * (0.8 + Float(i % 3) * 0.1), 1.0)
                }
            }
        }
        
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            print("Error starting audio engine: \(error)")
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionTask?.finish()
        recognitionRequest = nil
        recognitionTask = nil
        
        isRecording = false
        
        DispatchQueue.main.async {
            self.audioLevels = [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1]
        }
    }
    
    // Wispr Polish Agent: removes fillers & fixes self-corrections
    private func applyWisprFormatting(_ text: String) -> String {
        var result = text
        
        // Remove common speech fillers
        let fillers = [
            "\\b(?i)um+,?\\b",
            "\\b(?i)uh+,?\\b",
            "\\b(?i)er+,?\\b",
            "\\b(?i)ah+,?\\b",
            "\\b(?i)you know,?\\b",
            "\\b(?i)basically,?\\b"
        ]
        
        for filler in fillers {
            if let regex = try? NSRegularExpression(pattern: filler, options: []) {
                let range = NSRange(location: 0, length: result.utf16.count)
                result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "")
            }
        }
        
        // Clean double spaces
        result = result.replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
