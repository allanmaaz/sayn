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
    
    @Published var audioLevels: [Float] = Array(repeating: 0.12, count: 13)
    @Published var isRecording: Bool = false
    @Published var isProcessing: Bool = false
    @Published var isHandsFreeLocked: Bool = false
    @Published var currentMode: SanExecutionMode = .dictate
    
    var selectedContextText: String? = nil
    var onSilenceDetected: (() -> Void)? = nil
    
    private var hasSpokenVoice: Bool = false
    private var lastSpokenTimestamp: Date? = nil
    private var hasTriggeredSilenceCommit: Bool = false
    private var smoothedLevel: Float = 0.1
    private var wavePhase: Float = 0.0
    
    @Published var activeStyle: String = "flow"
    @Published var activeAngle: String = "normal"
    
    var activeStyleBadge: String {
        let styleName: String
        switch activeStyle {
        case "flow", "fluent", "natural": styleName = "Flow"
        case "professional": styleName = "Pro"
        case "humanize": styleName = "Human"
        case "mammals": styleName = "Mammal"
        default: styleName = "Flow"
        }
        
        let angleName: String
        switch activeAngle {
        case "normal": angleName = "Norm"
        case "professional": angleName = "Pro"
        case "alternative_english": angleName = "Alt"
        default: angleName = "Norm"
        }
        
        return "\(styleName) · \(angleName)"
    }
    
    override init() {
        super.init()
        let savedRaw = UserDefaults.standard.string(forKey: "SaynCurrentMode") ?? UserDefaults.standard.string(forKey: "SanCurrentMode") ?? "dictate"
        self.currentMode = SanExecutionMode(rawValue: savedRaw) ?? .dictate
        let savedStyle = UserDefaults.standard.string(forKey: "SaynActiveStyle") ?? "flow"
        self.activeStyle = savedStyle == "natural" ? "flow" : savedStyle
        self.activeAngle = UserDefaults.standard.string(forKey: "SaynActiveAngle") ?? "normal"
    }
    
    func setStyle(_ style: String) {
        self.activeStyle = style
        UserDefaults.standard.set(style, forKey: "SaynActiveStyle")
    }
    
    func cycleNextStyle() {
        let styles = ["flow", "professional", "humanize", "mammals"]
        if let idx = styles.firstIndex(of: activeStyle) {
            let next = styles[(idx + 1) % styles.count]
            setStyle(next)
        } else {
            setStyle("flow")
        }
    }
    
    func setAngle(_ angle: String) {
        self.activeAngle = angle
        UserDefaults.standard.set(angle, forKey: "SaynActiveAngle")
    }
    
    func cycleNextAngle() {
        let angles = ["normal", "professional", "alternative_english"]
        if let idx = angles.firstIndex(of: activeAngle) {
            let next = angles[(idx + 1) % angles.count]
            setAngle(next)
        } else {
            setAngle("normal")
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
        
        // 2. Start live audio visualizer meter timer (runs every 30ms for 30+ fps fluidity)
        meterTimer?.invalidate()
        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.030, repeats: true) { [weak self] _ in
            guard let self = self, self.isRecording, let recorder = self.audioRecorder else { return }
            recorder.updateMeters()
            let avgPower = recorder.averagePower(forChannel: 0) // range: -160 dB to 0 dB
            let peakPower = recorder.peakPower(forChannel: 0)
            
            // Speech levels sit comfortably between -45 dB and -6 dB
            let combined = max(Double(avgPower), Double(peakPower) * 0.65 + Double(avgPower) * 0.35)
            let linear = max(0.0, min(1.0, (combined + 45.0) / 40.0))
            let normalized = Float(linear)
            
            // Voice Activity Tracking
            if avgPower > -45.0 {
                self.hasSpokenVoice = true
                self.lastSpokenTimestamp = Date()
            }
            
            // Fluffy, ultra-smooth responsive audio wave level
            self.smoothedLevel = self.smoothedLevel * 0.45 + normalized * 0.55
            self.wavePhase += 0.22
            let currentPhase = self.wavePhase
            let lvl = max(self.smoothedLevel, 0.08)
            
            DispatchQueue.main.async {
                self.audioLevels = (0..<13).map { i in
                    let dist = abs(Float(i) - 6.0) / 6.0
                    let bell = cos(dist * Float.pi * 0.48)
                    let harmonic = sin(currentPhase + Float(i) * 0.42) * 0.25 + 0.75
                    return min(max(lvl * Float(bell) * Float(harmonic), 0.10), 1.0)
                }
            }
        }
    }
    
    func stopRecording(activeAppBundleId: String? = nil, completion: @escaping (String) -> Void) {
        guard isRecording || isProcessing else { return }
        self.isProcessing = true
        self.isRecording = false
        
        hasTriggeredSilenceCommit = true
        hasSpokenVoice = false
        lastSpokenTimestamp = nil
        
        // 1. Stop audio recorder and metering
        meterTimer?.invalidate()
        meterTimer = nil
        let duration = audioRecorder?.currentTime ?? 0.0
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        
        DispatchQueue.main.async {
            self.audioLevels = Array(repeating: 0.12, count: 13)
            self.isProcessing = true
        }
        
        // If recording was shorter than 0.3s or audio file is too small, skip
        if duration < 0.3 {
            DispatchQueue.main.async {
                self.isProcessing = false
                completion("")
            }
            return
        }
        
        DispatchQueue.main.async {
            self.audioLevels = Array(repeating: 0.12, count: 13)
            self.isProcessing = true
        }
        
        // 3. High-Capacity Neural Polish with Mode, Style & Real-Time Vocabulary Biasing
        let styleToUse = activeStyle
        let angleToUse = activeAngle
        let modeToUse = currentMode
        let contextToUse = selectedContextText
        let cleanupLevel = SaynStore.shared.cleanupLevel
        
        GroqService.shared.transcribeAndPolish(
            audioFileURL: tempAudioURL,
            mode: modeToUse,
            style: styleToUse,
            angle: angleToUse,
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
                        let fallback = SaynVoicePolisher.shared.polishLocally(
                            self?.lastAppleTranscript ?? "",
                            appBundleId: activeAppBundleId,
                            style: styleToUse,
                            angle: angleToUse,
                            cleanupLevel: cleanupLevel
                        )
                        completion(fallback)
                    }
                case .failure(let err):
                    print("Neural voice transcription note: \(err). Falling back to local polish.")
                    let fallback = SaynVoicePolisher.shared.polishLocally(
                        self?.lastAppleTranscript ?? "",
                        appBundleId: activeAppBundleId,
                        style: styleToUse,
                        angle: angleToUse,
                        cleanupLevel: cleanupLevel
                    )
                    completion(fallback)
                }
            }
        }
    }
}
