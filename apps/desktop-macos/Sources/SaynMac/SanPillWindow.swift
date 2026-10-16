import AppKit
import SwiftUI

final class SanPillWindow: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
    
    init(contentView: NSView) {
        // Canvas width 440 x 100 so shadows feather out naturally with zero clipping
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 100),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.isFloatingPanel = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.contentView = contentView
        self.alphaValue = 0.0
        
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
            ctx.duration = 0.12
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.animator().alphaValue = 0.0
        }, completionHandler: {
            self.orderOut(nil)
            completion?()
        })
    }
}

struct SanPillView: View {
    @ObservedObject var waveformEngine: AudioWaveformEngine
    @Binding var transcriptText: String
    var onCancel: () -> Void
    var onConfirm: (String) -> Void
    
    @State private var isHoveredClose: Bool = false
    @State private var dotPulse: Bool = false
    
    // Official SAYN Colors
    private let deepMaroon = Color(hex: "6F1025")
    private let roseMaroon = Color(hex: "A83249")
    private let warmCream = Color(hex: "F5EBDD")
    private let nearBlack = Color(hex: "100709")
    private let mutedCream = Color(hex: "D6C7B2")
    
    var body: some View {
        ZStack {
            // Pill Capsule
            HStack(spacing: 10) {
                // 1. SAYN Brand Icon
                SanLogoBadge()
                
                // 2. Interactive Mode Chips: [ Dictate | Prompt | Translate | Code ]
                HStack(spacing: 4) {
                    ModeChip(
                        title: "Dictate",
                        isSelected: waveformEngine.currentMode == .dictate,
                        activeColor: deepMaroon,
                        roseColor: roseMaroon,
                        creamColor: warmCream
                    ) {
                        waveformEngine.setMode(.dictate)
                    }
                    
                    ModeChip(
                        title: "Prompt",
                        isSelected: waveformEngine.currentMode == .prompt,
                        activeColor: deepMaroon,
                        roseColor: roseMaroon,
                        creamColor: warmCream
                    ) {
                        waveformEngine.setMode(.prompt)
                    }
                    
                    ModeChip(
                        title: "Translate",
                        isSelected: waveformEngine.currentMode == .translate,
                        activeColor: deepMaroon,
                        roseColor: roseMaroon,
                        creamColor: warmCream
                    ) {
                        waveformEngine.setMode(.translate)
                    }
                    
                    ModeChip(
                        title: "Code",
                        isSelected: waveformEngine.currentMode == .code,
                        activeColor: deepMaroon,
                        roseColor: roseMaroon,
                        creamColor: warmCream
                    ) {
                        waveformEngine.setMode(.code)
                    }
                }
                
                Divider()
                    .frame(height: 18)
                    .background(roseMaroon.opacity(0.35))
                
                // 3. Center Activity: Soundwave during speaking OR Processing Status
                if waveformEngine.isProcessing {
                    HStack(spacing: 7) {
                        ZStack {
                            Circle()
                                .fill(roseMaroon.opacity(dotPulse ? 0.45 : 0.2))
                                .frame(width: 12, height: 12)
                                .scaleEffect(dotPulse ? 1.25 : 0.85)
                            Circle()
                                .fill(roseMaroon)
                                .frame(width: 6, height: 6)
                        }
                        .onAppear {
                            withAnimation(Animation.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                                dotPulse = true
                            }
                        }
                        
                        Text(waveformEngine.currentMode.statusTitle)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(warmCream)
                            .tracking(0.15)
                    }
                    .transition(.opacity)
                } else {
                    // Audio Equalizer Waveform Bars in Soft Rose-Maroon and Warm Cream
                    HStack(spacing: 2.5) {
                        ForEach(0..<8, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(index % 2 == 0 ? roseMaroon : warmCream)
                                .frame(width: 2.5, height: CGFloat(max(4, waveformEngine.audioLevels[index] * 20)))
                                .animation(.easeOut(duration: 0.08), value: waveformEngine.audioLevels[index])
                        }
                    }
                    .frame(width: 36, height: 22)
                    .transition(.opacity)
                }
                
                Spacer(minLength: 2)
                
                // 4. Minimal Dismiss Button [ ✕ ]
                Button(action: onCancel) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(isHoveredClose ? 0.16 : 0.07))
                            .frame(width: 22, height: 22)
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(isHoveredClose ? warmCream : mutedCream)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.12)) {
                        isHoveredClose = hovering
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(width: 388, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .fill(nearBlack.opacity(0.96))
                    .overlay(
                        RoundedRectangle(cornerRadius: 25, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    stops: [
                                        .init(color: roseMaroon.opacity(0.55), location: 0.0),
                                        .init(color: deepMaroon.opacity(0.35), location: 0.5),
                                        .init(color: Color.black.opacity(0.8), location: 1.0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1.2
                            )
                    )
                    .shadow(color: Color.black.opacity(0.75), radius: 20, x: 0, y: 10)
                    .shadow(color: deepMaroon.opacity(0.4), radius: 12, x: 0, y: 3)
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: waveformEngine.isProcessing)
    }
}

// Mode Chip Component
struct ModeChip: View {
    let title: String
    let isSelected: Bool
    let activeColor: Color
    let roseColor: Color
    let creamColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .rounded))
                .foregroundColor(isSelected ? creamColor : creamColor.opacity(0.65))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected ? activeColor : Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(isSelected ? roseColor : Color.clear, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// SAYN Logo Badge Component in Deep Maroon & Warm Cream
struct SanLogoBadge: View {
    var body: some View {
        if let image = loadLogoImage() {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 26, height: 26)
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(Color(hex: "A83249").opacity(0.5), lineWidth: 1)
                )
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "8F1835"), Color(hex: "6F1025")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 26, height: 26)
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .stroke(Color(hex: "F5EBDD").opacity(0.3), lineWidth: 1)
                    )
                
                // Soundwave bars in warm cream
                HStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(hex: "F5EBDD"))
                        .frame(width: 2, height: 10)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(hex: "F5EBDD"))
                        .frame(width: 2, height: 16)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(hex: "F5EBDD"))
                        .frame(width: 2, height: 12)
                }
            }
        }
    }
    
    private func loadLogoImage() -> NSImage? {
        let paths = [
            Bundle.main.path(forResource: "logo", ofType: "png"),
            "/Applications/SAYN.app/Contents/Resources/logo.png",
            "/Applications/San.app/Contents/Resources/logo.png",
            "/Users/apple/Desktop/SAYN/apps/desktop-macos/Resources/logo.png"
        ]
        for p in paths.compactMap({ $0 }) {
            if FileManager.default.fileExists(atPath: p), let img = NSImage(contentsOfFile: p) {
                return img
            }
        }
        return nil
    }
}

// SwiftUI Color Hex Initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
