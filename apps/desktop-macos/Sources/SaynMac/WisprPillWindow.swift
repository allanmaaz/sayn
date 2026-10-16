import AppKit
import SwiftUI

final class WisprPillWindow: NSPanel {
    init(contentView: NSView) {
        // Generous canvas (340x100) so SwiftUI shadows feather out naturally with ZERO clipping
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 100),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.isFloatingPanel = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.backgroundColor = .clear
        self.isOpaque = false
        // Disable OS window shadow so macOS does not draw an ugly rectangular bounding box
        self.hasShadow = false
        self.contentView = contentView
        self.alphaValue = 0.0
        
        // Ensure it starts completely hidden
        self.orderOut(nil)
        centerOnScreen()
    }
    
    func centerOnScreen() {
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let x = screenRect.midX - (frame.width / 2)
            let y = screenRect.minY + 28 // Floating right above the Dock
            setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
    
    func showAnimated() {
        centerOnScreen()
        self.alphaValue = 0.0
        self.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.16
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().alphaValue = 1.0
        }
    }
    
    func hideAnimated(completion: (() -> Void)? = nil) {
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.14
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.animator().alphaValue = 0.0
        }, completionHandler: {
            self.orderOut(nil)
            completion?()
        })
    }
}

struct WisprPillView: View {
    @ObservedObject var waveformEngine: AudioWaveformEngine
    @Binding var transcriptText: String
    var onCancel: () -> Void
    var onConfirm: (String) -> Void
    
    @State private var isHoveredClose: Bool = false
    @State private var dotPulse: Bool = false
    
    // Volt neon green matching SAYN brand identity
    private let neonGreen = Color(hex: "CBFE00")
    
    var body: some View {
        ZStack {
            // Pill Capsule
            HStack(spacing: 12) {
                // 1. SAYN App Icon Badge
                SaynLogoBadge()
                
                // 2. Center Content: Soundwave during speaking OR "SAYN Polishing..."
                if waveformEngine.isProcessing {
                    HStack(spacing: 8) {
                        // High-res neon pulsating dot
                        ZStack {
                            Circle()
                                .fill(neonGreen.opacity(dotPulse ? 0.35 : 0.15))
                                .frame(width: 13, height: 13)
                                .scaleEffect(dotPulse ? 1.2 : 0.85)
                            Circle()
                                .fill(neonGreen)
                                .frame(width: 6, height: 6)
                        }
                        .onAppear {
                            withAnimation(Animation.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                                dotPulse = true
                            }
                        }
                        
                        Text("SAYN Polishing...")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(neonGreen)
                            .tracking(0.2)
                    }
                    .transition(.opacity)
                } else {
                    // Audio Equalizer Waveform Bars (in neon volt green) - Clean, silent, zero text while speaking!
                    HStack(spacing: 3) {
                        ForEach(0..<8, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(neonGreen)
                                .frame(width: 3, height: CGFloat(max(4, waveformEngine.audioLevels[index] * 22)))
                                .animation(.easeOut(duration: 0.08), value: waveformEngine.audioLevels[index])
                        }
                    }
                    .frame(width: 45, height: 24)
                    .transition(.opacity)
                }
                
                Spacer(minLength: 4)
                
                // 3. Apple-style Minimal Dismiss Button [ ✕ ]
                Button(action: onCancel) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(isHoveredClose ? 0.16 : 0.08))
                            .frame(width: 24, height: 24)
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color.white.opacity(isHoveredClose ? 1.0 : 0.65))
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.12)) {
                        isHoveredClose = hovering
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(width: 272, height: 50)
            .background(
                // Liquid Obsidian Dark Glass Capsule
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .fill(Color(hex: "0D0D12").opacity(0.96))
                    .overlay(
                        // Top Specular Rim Light
                        RoundedRectangle(cornerRadius: 25, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    stops: [
                                        .init(color: Color.white.opacity(0.22), location: 0.0),
                                        .init(color: Color.white.opacity(0.06), location: 0.4),
                                        .init(color: Color.white.opacity(0.02), location: 1.0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )
                    // Unclipped feather-soft drop shadows
                    .shadow(color: Color.black.opacity(0.65), radius: 18, x: 0, y: 8)
                    .shadow(color: neonGreen.opacity(0.12), radius: 8, x: 0, y: 2)
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: waveformEngine.isProcessing)
    }
}

// SAYN Logo Badge Component
struct SaynLogoBadge: View {
    var body: some View {
        if let image = loadLogoImage() {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(hex: "18181F"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color(hex: "CBFE00").opacity(0.4), lineWidth: 1)
                    )
                Text("S")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(Color(hex: "CBFE00"))
            }
            .frame(width: 28, height: 28)
        }
    }
    
    private func loadLogoImage() -> NSImage? {
        let possiblePaths = [
            Bundle.main.path(forResource: "logo", ofType: "png"),
            "/Applications/SAYN.app/Contents/Resources/logo.png",
            "/Users/apple/Desktop/SAYN/apps/desktop-macos/Resources/logo.png"
        ]
        
        for path in possiblePaths.compactMap({ $0 }) {
            if FileManager.default.fileExists(atPath: path),
               let image = NSImage(contentsOfFile: path) {
                return image
            }
        }
        return nil
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
