import Foundation
import AVFoundation
import Speech
import AppKit

final class AudioWaveformEngine: NSObject, ObservableObject, AVAudioRecorderDelegate {
    private var audioRecorder: AVAudioRecorder?
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var previewAudioEngine: AVAudioEngine?
    
    private let tempAudioURL = URL(fileURLWithPath: "/tmp/san_dictation.wav")
    private var lastAppleTranscript: String = ""
    private var meterTimer: Timer?
    
    @Published var audioLevels: [Float] = [0.1, 0.2, 0.4, 0.6, 0.5, 0.3, 0.2, 0.1]
    @Published var isRecording: Bool = false
    @Published var isProcessing: Bool = false
    
    var activeStyle: String {
        get {
            return UserDefaults.standard.string(forKey: "SanActiveStyle") ?? "natural"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "SanActiveStyle")
        }
    }
    
    func startRecording(onLiveTranscript: @escaping (String) -> Void) {
        guard !isRecording else { return }
        
        lastAppleTranscript = ""
        isProcessing = false
        
        try? FileManager.default.removeItem(at: tempAudioURL)
        
        // 1. Configure rock-solid 16kHz 16-bit Mono WAV recording (Lightweight, handles 60s+ effortlessly)
        let recordSettings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: tempAudioURL, settings: recordSettings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            isRecording = true
        } catch {
            print("Audio recorder failed to start: \(error)")
        }
        
        // 2. Start live audio visualizer meter timer (runs every 45ms)
        meterTimer?.invalidate()
        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.045, repeats: true) { [weak self] _ in
            guard let self = self, self.isRecording, let recorder = self.audioRecorder else { return }
            recorder.updateMeters()
            let power = recorder.averagePower(forChannel: 0) // range: -160 dB to 0 dB
            // Map -50dB...0dB into 0.08...1.0
            let linear = max(0.0, (power + 50.0) / 50.0)
            let normalized = min(max(Float(linear), 0.08), 1.0)
            
            DispatchQueue.main.async {
                self.audioLevels = (0..<8).map { i in
                    let variance = Float.random(in: 0.75...1.25)
                    return min(normalized * variance * (0.8 + Float(i % 3) * 0.1), 1.0)
                }
            }
        }
        
        // 3. Optional live streaming speech preview (Apple Speech Framework)
        startLiveSpeechPreview(onLiveTranscript: onLiveTranscript)
    }
    
    private func startLiveSpeechPreview(onLiveTranscript: @escaping (String) -> Void) {
        SFSpeechRecognizer.requestAuthorization { _ in }
        
        previewAudioEngine = AVAudioEngine()
        guard let engine = previewAudioEngine else { return }
        
        let inputNode = engine.inputNode
        let busFormat = inputNode.outputFormat(forBus: 0)
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.recognitionRequest = request
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            if let result = result {
                let text = result.bestTranscription.formattedString
                self?.lastAppleTranscript = text
                DispatchQueue.main.async {
                    onLiveTranscript(text)
                }
            }
        }
        
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: busFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        try? engine.start()
    }
    
    func stopRecording(activeAppBundleId: String? = nil, completion: @escaping (String) -> Void) {
        guard isRecording else { return }
        
        // 1. Stop audio recorder and metering
        meterTimer?.invalidate()
        meterTimer = nil
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        
        // 2. Stop speech preview engine
        previewAudioEngine?.stop()
        previewAudioEngine?.inputNode.removeTap(onBus: 0)
        previewAudioEngine = nil
        recognitionRequest?.endAudio()
        recognitionTask?.finish()
        recognitionRequest = nil
        recognitionTask = nil
        
        DispatchQueue.main.async {
            self.audioLevels = [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1]
            self.isProcessing = true
        }
        
        // 3. High-Capacity Groq Whisper Turbo & LPU Polish (handles 60s, 2m, 5m without failing)
        let styleToUse = activeStyle
        GroqService.shared.transcribeAndPolish(audioFileURL: tempAudioURL, style: styleToUse) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessing = false
                switch result {
                case .success(let text):
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        completion(trimmed)
                    } else {
                        // Fallback to local regex polish of partial apple transcript
                        let fallback = SaynVoicePolisher.shared.polishLocally(self?.lastAppleTranscript ?? "", appBundleId: activeAppBundleId)
                        completion(fallback)
                    }
                case .failure(let err):
                    print("Groq transcription note: \(err). Falling back to local polish.")
                    let fallback = SaynVoicePolisher.shared.polishLocally(self?.lastAppleTranscript ?? "", appBundleId: activeAppBundleId)
                    completion(fallback)
                }
            }
        }
    }
}
