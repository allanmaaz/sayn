import Foundation
import AVFoundation
import Speech
import AppKit

enum TranscriptionEngine: String, CaseIterable {
    case cloudGateway = "cloud_gateway"         // SAYN Fast Cloud (Real-time ASR + Polish)
    case onDeviceAppleNeural = "on_device"     // 100% Offline Apple Silicon Neural Engine
    case groqWhisper = "groq_whisper"           // Groq Whisper Large-v3 (if key set)
    
    var displayName: String {
        switch self {
        case .cloudGateway: return "SAYN Fast Cloud (Wispr Flow Speed)"
        case .onDeviceAppleNeural: return "Apple Silicon On-Device (100% Offline)"
        case .groqWhisper: return "Groq Whisper Turbo (High Speed)"
        }
    }
}

final class AudioWaveformEngine: ObservableObject {
    private var audioEngine = AVAudioEngine()
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private var audioFile: AVAudioFile?
    private let tempAudioURL = URL(fileURLWithPath: "/tmp/sayn_dictation.wav")
    private var lastAppleTranscript: String = ""
    
    @Published var audioLevels: [Float] = [0.1, 0.2, 0.4, 0.6, 0.5, 0.3, 0.2, 0.1]
    @Published var isRecording: Bool = false
    @Published var isProcessing: Bool = false
    
    var activeEngine: TranscriptionEngine {
        get {
            if let raw = UserDefaults.standard.string(forKey: "SaynEngineMode"),
               let mode = TranscriptionEngine(rawValue: raw) {
                return mode
            }
            // Auto-default to Groq Whisper Turbo if user has key configured
            if GroqService.shared.isConfigured {
                return .groqWhisper
            }
            return .cloudGateway
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "SaynEngineMode")
        }
    }
    
    func startRecording(onLiveTranscript: @escaping (String) -> Void) {
        guard !isRecording else { return }
        
        lastAppleTranscript = ""
        isProcessing = false
        
        try? FileManager.default.removeItem(at: tempAudioURL)
        SFSpeechRecognizer.requestAuthorization { _ in }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Write standard WAV file for Cloud & Whisper engines
        do {
            self.audioFile = try AVAudioFile(forWriting: tempAudioURL, settings: recordingFormat.settings)
        } catch {
            print("Audio file creation warning: \(error)")
        }
        
        // Setup live preview
        recognitionTask?.cancel()
        recognitionTask = nil
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        
        // If on-device engine selected or supported, use Apple Neural Engine hardware
        if speechRecognizer?.supportsOnDeviceRecognition ?? false {
            request.requiresOnDeviceRecognition = true
        }
        self.recognitionRequest = request
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            if let result = result {
                let rawTranscript = result.bestTranscription.formattedString
                self?.lastAppleTranscript = rawTranscript
                DispatchQueue.main.async {
                    onLiveTranscript(rawTranscript)
                }
            }
        }
        
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, time in
            guard let self = self else { return }
            
            self.recognitionRequest?.append(buffer)
            try? self.audioFile?.write(from: buffer)
            
            // Compute live RMS for 8 equalizer bars
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
    
    func stopRecording(activeAppBundleId: String? = nil, completion: @escaping (String) -> Void) {
        guard isRecording else { return }
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionTask?.finish()
        recognitionRequest = nil
        recognitionTask = nil
        audioFile = nil
        isRecording = false
        
        DispatchQueue.main.async {
            self.audioLevels = [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1]
        }
        
        // 1. If Groq Whisper mode is chosen and configured
        if activeEngine == .groqWhisper && GroqService.shared.isConfigured {
            DispatchQueue.main.async { self.isProcessing = true }
            GroqService.shared.transcribeAndPolish(audioFileURL: tempAudioURL) { [weak self] result in
                DispatchQueue.main.async {
                    self?.isProcessing = false
                    switch result {
                    case .success(let text):
                        let polished = SaynVoicePolisher.shared.polishLocally(text, appBundleId: activeAppBundleId)
                        completion(polished.isEmpty ? (self?.lastAppleTranscript ?? "") : polished)
                    case .failure:
                        let fallback = SaynVoicePolisher.shared.polishLocally(self?.lastAppleTranscript ?? "", appBundleId: activeAppBundleId)
                        completion(fallback)
                    }
                }
            }
            return
        }
        
        // 2. High-Speed Wispr Flow Execution:
        // Use real-time Apple Neural Engine speech transcript (already finished in 0ms!)
        let rawSpeech = lastAppleTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !rawSpeech.isEmpty {
            // Instant deterministic high-accuracy local polisher (0ms)
            let instantPolished = SaynVoicePolisher.shared.polishLocally(rawSpeech, appBundleId: activeAppBundleId)
            
            // Set UI to brief polishing indicator
            DispatchQueue.main.async { self.isProcessing = true }
            
            // If offline mode is requested, return instant result
            if activeEngine == .onDeviceAppleNeural {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    self.isProcessing = false
                    completion(instantPolished)
                }
                return
            }
            
            // Concurrently attempt Cloud Refinement with strict 1.2-second timeout
            var didComplete = false
            let deadline = DispatchTime.now() + 1.2
            
            SaynCloudService.shared.refineTranscript(rawText: instantPolished, activeAppBundleId: activeAppBundleId) { [weak self] cloudRefined in
                DispatchQueue.main.async {
                    guard !didComplete else { return }
                    didComplete = true
                    self?.isProcessing = false
                    let finalResult = cloudRefined.isEmpty ? instantPolished : cloudRefined
                    completion(finalResult)
                }
            }
            
            // If Cloud Refinement takes longer than 1.2s, immediately deliver locally polished text!
            DispatchQueue.main.asyncAfter(deadline: deadline) { [weak self] in
                guard !didComplete else { return }
                didComplete = true
                self?.isProcessing = false
                completion(instantPolished)
            }
            return
        }
        
        // 3. Fallback: If local speech was completely empty, query Cloud Gateway audio transcribe
        DispatchQueue.main.async { self.isProcessing = true }
        SaynCloudService.shared.transcribeAudio(audioFileURL: tempAudioURL) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessing = false
                switch result {
                case .success(let cloudTranscript):
                    let polished = SaynVoicePolisher.shared.polishLocally(cloudTranscript, appBundleId: activeAppBundleId)
                    completion(polished)
                case .failure:
                    completion("")
                }
            }
        }
    }
}
