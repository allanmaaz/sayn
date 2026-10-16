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
    
    private let tempAudioURL = URL(fileURLWithPath: "/tmp/sayn_dictation.wav")
    private var lastAppleTranscript: String = ""
    private var meterTimer: Timer?
    
    @Published var audioLevels: [Float] = [0.1, 0.2, 0.4, 0.6, 0.5, 0.3, 0.2, 0.1]
    @Published var isRecording: Bool = false
    @Published var isProcessing: Bool = false
    @Published var currentMode: SanExecutionMode = .dictate
    
    var selectedContextText: String? = nil
    var onSilenceDetected: (() -> Void)? = nil
    
    private var hasSpokenVoice: Bool = false
    private var lastSpokenTimestamp: Date? = nil
    private var hasTriggeredSilenceCommit: Bool = false
    
    override init() {
        super.init()
        let savedRaw = UserDefaults.standard.string(forKey: "SaynCurrentMode") ?? UserDefaults.standard.string(forKey: "SanCurrentMode") ?? "dictate"
        self.currentMode = SanExecutionMode(rawValue: savedRaw) ?? .dictate
    }
    
    var activeStyle: String {
        get {
            return UserDefaults.standard.string(forKey: "SaynActiveStyle") ?? UserDefaults.standard.string(forKey: "SanActiveStyle") ?? "natural"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "SaynActiveStyle")
        }
    }
    
    func setMode(_ mode: SanExecutionMode) {
        self.currentMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: "SaynCurrentMode")
    }
    
    func cycleNextMode() {
        let all = SanExecutionMode.allCases
        if let idx = all.firstIndex(of: currentMode) {
            let next = all[(idx + 1) % all.count]
            setMode(next)
        } else {
            setMode(.dictate)
        }
    }
    
    func startRecording(onLiveTranscript: @escaping (String) -> Void) {
        guard !isRecording else { return }
        
        lastAppleTranscript = ""
        isProcessing = false
        hasSpokenVoice = false
        lastSpokenTimestamp = nil
        hasTriggeredSilenceCommit = false
        
        try? FileManager.default.removeItem(at: tempAudioURL)
        
        // 1. Configure rock-solid 16kHz 16-bit Mono WAV recording
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
            let linear = max(0.0, (power + 50.0) / 50.0)
            let normalized = min(max(Float(linear), 0.08), 1.0)
            
            // Voice Activity Detection: user speaking power above -36 dB
            if power > -36.0 {
                self.hasSpokenVoice = true
                self.lastSpokenTimestamp = Date()
            }
            
            // Auto-Commit on Silence: if user spoke and then stops speaking for >= 1.6 seconds
            if self.hasSpokenVoice && !self.hasTriggeredSilenceCommit, let lastSpoken = self.lastSpokenTimestamp {
                let silenceDuration = Date().timeIntervalSince(lastSpoken)
                if silenceDuration >= 1.6 {
                    self.hasTriggeredSilenceCommit = true
                    DispatchQueue.main.async {
                        self.onSilenceDetected?()
                    }
                }
            }
            
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
                if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    self?.hasSpokenVoice = true
                    self?.lastSpokenTimestamp = Date()
                }
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
        
        hasTriggeredSilenceCommit = true
        hasSpokenVoice = false
        lastSpokenTimestamp = nil
        
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
        
        // 3. High-Capacity Groq Whisper Turbo & LPU Polish with Mode & Vocabulary Biasing
        let styleToUse = activeStyle
        let modeToUse = currentMode
        let contextToUse = selectedContextText
        
        GroqService.shared.transcribeAndPolish(
            audioFileURL: tempAudioURL,
            mode: modeToUse,
            style: styleToUse,
            contextText: contextToUse,
            activeAppBundleId: activeAppBundleId
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessing = false
                self?.selectedContextText = nil // reset after execution
                
                switch result {
                case .success(let text):
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        completion(trimmed)
                    } else {
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
