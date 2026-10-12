import Foundation
import AVFoundation

final class AudioWaveformEngine: ObservableObject {
    private var audioEngine = AVAudioEngine()
    @Published var audioLevels: [Float] = [0.1, 0.2, 0.4, 0.6, 0.5, 0.3, 0.2, 0.1]
    @Published var isRecording: Bool = false
    
    private var audioBuffer: [Data] = []
    
    func startRecording() {
        guard !isRecording else { return }
        
        let audioSession = AVCaptureDevice.default(for: .audio)
        if audioSession == nil {
            print("No audio capture device found")
            return
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, time in
            guard let self = self else { return }
            
            // Calculate RMS audio power
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
        isRecording = false
        
        DispatchQueue.main.async {
            self.audioLevels = [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1]
        }
    }
}
