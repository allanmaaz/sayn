import AppKit
import SwiftUI

/// Window Controller for the Ephemeral System-Wide Voice HUD
/// Supports both:
/// 1. Micro-Pill (Recording State): 96x30 minimal black capsule with dancing pure-white waveform bars docked right above the MacBook bezel
/// 2. Fallback HUD Card: 380x170 floating sheet with "Select a textbox first, then dictate", clean transcript, and [ Copy ] button
final class SanPillWindow: NSPanel {
    override var canBecomeKey: Bool {
        // Allow becoming key when showing the interactive Fallback Card (with Copy button)
        return isInteractiveCard
    }
    override var canBecomeMain: Bool { false }
    
    var isInteractiveCard: Bool = false
    
    init(contentView: NSView) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 220),
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
        centerAtBottomBezel()
    }
    
    func centerAtBottomBezel(forCard: Bool = false) {
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let x = screenRect.midX - (frame.width / 2)
            // Docked right above the MacBook bottom bezel
            let y = forCard ? (screenRect.minY + 36) : (screenRect.minY + 12)
            setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
    
    func showAnimated(isCard: Bool = false) {
        self.isInteractiveCard = isCard
        centerAtBottomBezel(forCard: isCard)
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
            self.isInteractiveCard = false
            completion?()
        })
    }
}

/// Dynamic View switching between Micro-Capsule and Fallback HUD Card
struct SanPillView: View {
    @ObservedObject var waveformEngine: AudioWaveformEngine
    @Binding var transcriptText: String
    @Binding var isFallbackCard: Bool
    var onCancel: () -> Void
    var onConfirm: (String) -> Void
    var onCopyText: ((String) -> Void)?
    
    @State private var isCopied: Bool = false
    @State private var isHoveredClose: Bool = false
    @State private var isHoveredCopy: Bool = false
    
    var body: some View {
        ZStack {
            if isFallbackCard {
                fallbackHUDCard
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .scale(scale: 0.95).combined(with: .opacity)
                    ))
            } else {
                microRecordingCapsule
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.9).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: isFallbackCard)
    }
    
    // MARK: - 1. Micro Recording Capsule (Wispr Flow State)
    /// Minimalist 96x30 black capsule with dancing pure-white waveform bars
    private var microRecordingCapsule: some View {
        HStack(spacing: 3) {
            // 9 Dynamic Pure-White Equalizer Bars reacting in real-time
            ForEach(0..<9, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color.white)
                    .frame(
                        width: 2.4,
                        height: CGFloat(max(4, waveformEngine.audioLevels[min(index, waveformEngine.audioLevels.count - 1)] * 18))
                    )
                    .animation(.easeOut(duration: 0.08), value: waveformEngine.audioLevels[min(index, waveformEngine.audioLevels.count - 1)])
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 7)
        .frame(width: 96, height: 30)
        .background(
            Capsule()
                .fill(Color(red: 10/255, green: 10/255, blue: 12/255).opacity(0.96))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.14), lineWidth: 0.8)
                )
                .shadow(color: Color.black.opacity(0.6), radius: 14, x: 0, y: 6)
        )
    }
    
    // MARK: - 2. Fallback HUD Card (When No Textbox Focused)
    /// Floating 380x170 dark card with header, clean transcript, and [ Copy ] button
    private var fallbackHUDCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header Bar: Audio Icon + Context Hint + Circular Dismiss [X]
            HStack(spacing: 8) {
                // Waveform real vector icon
                Image(systemName: "waveform")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Muted context hint
                Text("Select a textbox first, then dictate")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.55))
                
                Spacer()
                
                // Circular Dismiss Button
                Button(action: onCancel) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(isHoveredClose ? 0.22 : 0.12))
                            .frame(width: 24, height: 24)
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .onHover { h in isHoveredClose = h }
            }
            
            // Transcribed Speech Text
            ScrollView(.vertical, showsIndicators: false) {
                Text(transcriptText.isEmpty ? "What's up? What's going on?" : transcriptText)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 242/255, green: 242/255, blue: 247/255))
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxHeight: 70)
            
            // Footer: [ Copy ] Button
            HStack {
                Spacer()
                
                Button(action: {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(transcriptText, forType: .string)
                    onCopyText?(transcriptText)
                    
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isCopied = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        withAnimation {
                            isCopied = false
                        }
                    }
                }) {
                    HStack(spacing: 6) {
                        if isCopied {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                            Text("Copied!")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        } else {
                            Text("Copy")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isCopied ? Color.green.opacity(0.8) : Color(red: 70/255, green: 70/255, blue: 74/255).opacity(isHoveredCopy ? 0.95 : 0.8))
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .onHover { h in isHoveredCopy = h }
            }
        }
        .padding(18)
        .frame(width: 380, height: 170)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(red: 12/255, green: 13/255, blue: 15/255).opacity(0.97))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.75), radius: 24, x: 0, y: 12)
        )
    }
}
