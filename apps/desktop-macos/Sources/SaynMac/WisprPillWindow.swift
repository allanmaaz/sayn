import AppKit
import SwiftUI

final class WisprPillWindow: NSPanel {
    init(contentView: NSView) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 60),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.isFloatingPanel = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
        self.contentView = contentView
        
        centerOnScreen()
    }
    
    func centerOnScreen() {
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let x = screenRect.midX - (frame.width / 2)
            let y = screenRect.minY + 60 // Float comfortably above dock/bottom edge
            setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
}

struct WisprPillView: View {
    @ObservedObject var waveformEngine: AudioWaveformEngine
    @Binding var transcriptText: String
    var onCancel: () -> Void
    var onConfirm: (String) -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            // 1. Cancel / Dismiss Circle [ ✕ ]
            Button(action: onCancel) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "1C1C22").opacity(0.85))
                        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                    Text("✕")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: "E5E5EA"))
                }
                .frame(width: 44, height: 44)
            }
            .buttonStyle(PlainButtonStyle())
            
            // 2. Center Capsule with Wavy Equalizer & Live Speech
            HStack(spacing: 10) {
                // The "Wavy Thing" - 8 Live Audio Equalizer Bars
                HStack(spacing: 3) {
                    ForEach(0..<8, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: "5DE4FF")) // Voice cyan
                            .frame(width: 3.5, height: CGFloat(max(6, waveformEngine.audioLevels[index] * 28)))
                            .animation(.easeOut(duration: 0.1), value: waveformEngine.audioLevels[index])
                    }
                }
                .frame(width: 45, height: 32)
                
                // Live Transcript Text
                Text(transcriptText.isEmpty ? "Say anything... Wispr capturing speech" : transcriptText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .frame(width: 260, height: 46)
            .background(
                RoundedRectangle(cornerRadius: 23)
                    .fill(Color(hex: "18181D").opacity(0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: 23)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
            )
            
            // 3. Confirm Circle [ ✓ ]
            Button(action: { onConfirm(transcriptText) }) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "7E57C2")) // Wispr vibrant purple
                        .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                    Text("✓")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 44, height: 44)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(8)
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
