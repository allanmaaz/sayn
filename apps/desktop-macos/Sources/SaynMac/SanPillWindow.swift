import AppKit
import SwiftUI

/// Custom Hosting View with .activeAlways tracking area to ensure hover events
/// are delivered 100% reliably even when another application (VS Code, Chrome, etc.) is active.
final class SanPillHostingView<Content: View>: NSHostingView<Content> {
    private var trackingArea: NSTrackingArea?
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseEnteredAndExited, .mouseMoved, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }
}

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
        self.acceptsMouseMovedEvents = true
        self.ignoresMouseEvents = false
        self.contentView = contentView
        self.alphaValue = 0.0
        
        self.orderOut(nil)
        centerAtBottomBezel()
    }
    
    func centerAtBottomBezel(forCard: Bool = false) {
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let x = screenRect.midX - (frame.width / 2)
            // Docked snug right above the MacBook bottom bezel
            let y = forCard ? (screenRect.minY + 14) : (screenRect.minY + 6)
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

// MARK: - Animated Progress Components
struct ProcessingSpinner: View {
    @State private var isSpinning: Bool = false
    
    var body: some View {
        Circle()
            .trim(from: 0.15, to: 0.85)
            .stroke(
                AngularGradient(
                    gradient: Gradient(colors: [
                        Color(red: 168/255, green: 50/255, blue: 73/255),
                        Color(red: 245/255, green: 235/255, blue: 221/255)
                    ]),
                    center: .center
                ),
                style: StrokeStyle(lineWidth: 2, lineCap: .round)
            )
            .rotationEffect(.degrees(isSpinning ? 360 : 0))
            .animation(.linear(duration: 0.85).repeatForever(autoreverses: false), value: isSpinning)
            .onAppear {
                isSpinning = true
            }
    }
}

struct PulsingDotsView: View {
    @State private var phase: Int = 0
    let timer = Timer.publish(every: 0.28, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color(red: 245/255, green: 235/255, blue: 221/255).opacity(phase == index ? 1.0 : 0.4))
                    .frame(width: 3.5, height: 3.5)
                    .scaleEffect(phase == index ? 1.3 : 0.85)
                    .animation(.easeInOut(duration: 0.25), value: phase)
            }
        }
        .onReceive(timer) { _ in
            phase = (phase + 1) % 3
        }
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
    @State private var isHoveredConfirm: Bool = false
    @State private var isHoveredCopy: Bool = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if isFallbackCard {
                fallbackHUDCard
                    .padding(.bottom, 6)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .scale(scale: 0.95).combined(with: .opacity)
                    ))
            } else {
                microRecordingCapsule
                    .padding(.bottom, 6)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.9).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: isFallbackCard)
    }
    
    // MARK: - 1. Micro Recording Capsule in SAYN Deep Maroon Branding
    private var microRecordingCapsule: some View {
        HStack(spacing: 8) {
            if waveformEngine.isProcessing {
                // Immediate Loading State: Appears IMMEDIATELY when completing dictation or navigating away from Fn
                HStack(spacing: 8) {
                    ProcessingSpinner()
                        .frame(width: 14, height: 14)
                    
                    Text("Polishing...")
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 245/255, green: 235/255, blue: 221/255))
                    
                    PulsingDotsView()
                }
                .padding(.horizontal, 10)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                // Cancel (✕) button with instant hover & cursor feedback
                Button(action: onCancel) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(isHoveredClose ? 0.30 : 0.12))
                            .frame(width: 22, height: 22)
                            .scaleEffect(isHoveredClose ? 1.08 : 1.0)
                        Image(systemName: "xmark")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(Color(red: 245/255, green: 235/255, blue: 221/255).opacity(isHoveredClose ? 1.0 : 0.85))
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Circle())
                .onHover { h in
                    withAnimation(.easeInOut(duration: 0.12)) {
                        isHoveredClose = h
                    }
                    if h {
                        NSCursor.pointingHand.set()
                    } else {
                        NSCursor.arrow.set()
                    }
                }
                
                // Dynamic Warm-Cream Fluffy Equalizer Wave reacting in real-time
                HStack(spacing: 2.8) {
                    ForEach(0..<min(13, waveformEngine.audioLevels.count), id: \.self) { index in
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 255/255, green: 248/255, blue: 240/255),
                                        Color(red: 245/255, green: 228/255, blue: 215/255)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(
                                width: 2.8,
                                height: CGFloat(max(4.5, CGFloat(waveformEngine.audioLevels[index]) * 20.0))
                            )
                            .shadow(color: Color(red: 255/255, green: 235/255, blue: 215/255).opacity(0.35), radius: 2, x: 0, y: 0)
                            .animation(.interactiveSpring(response: 0.14, dampingFraction: 0.65), value: waveformEngine.audioLevels[index])
                    }
                }
                .padding(.horizontal, 6)
                
                // Confirm / Tick Mark (✓) button in signature SAYN Deep Maroon with reliable hover
                Button(action: {
                    waveformEngine.isProcessing = true
                    onConfirm(transcriptText)
                }) {
                    ZStack {
                        Circle()
                            .fill(isHoveredConfirm ? Color(red: 168/255, green: 28/255, blue: 62/255) : Color(red: 111/255, green: 16/255, blue: 37/255))
                            .frame(width: 22, height: 22)
                            .scaleEffect(isHoveredConfirm ? 1.10 : 1.0)
                        Image(systemName: "checkmark")
                            .font(.system(size: 10.5, weight: .bold))
                            .foregroundColor(Color(red: 245/255, green: 235/255, blue: 221/255))
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Circle())
                .onHover { h in
                    withAnimation(.easeInOut(duration: 0.12)) {
                        isHoveredConfirm = h
                    }
                    if h {
                        NSCursor.pointingHand.set()
                    } else {
                        NSCursor.arrow.set()
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(height: 34)
        .contentShape(Capsule())
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 45/255, green: 10/255, blue: 18/255),
                            Color(red: 20/255, green: 5/255, blue: 8/255)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Capsule()
                        .stroke(Color(red: 168/255, green: 50/255, blue: 73/255).opacity(0.6), lineWidth: 1)
                )
                .shadow(color: Color(red: 111/255, green: 16/255, blue: 37/255).opacity(0.4), radius: 10, x: 0, y: 3)
        )
        .animation(.easeInOut(duration: 0.16), value: waveformEngine.isProcessing)
    }
    
    // MARK: - 2. Fallback HUD Card (When No Textbox Focused)
    /// Floating 380x170 dark card with header, clean transcript, [ Copy ], and [ ✓ Insert ] buttons
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
            
            // Footer: [ Copy ] and [ ✓ Insert ] Tick Mark Buttons
            HStack(spacing: 10) {
                Spacer()
                
                // Copy Button
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
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 11, weight: .bold))
                        Text(isCopied ? "Copied!" : "Copy")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isCopied ? Color(red: 168/255, green: 50/255, blue: 73/255).opacity(0.85) : Color(red: 55/255, green: 15/255, blue: 24/255).opacity(isHoveredCopy ? 0.95 : 0.8))
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .onHover { h in isHoveredCopy = h }
                
                // Tick Mark / Insert (✓) Button
                Button(action: {
                    onConfirm(transcriptText)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                        Text("Insert")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(Color(red: 245/255, green: 235/255, blue: 221/255))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(red: 111/255, green: 16/255, blue: 37/255))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(18)
        .frame(width: 380, height: 170)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 35/255, green: 10/255, blue: 16/255),
                            Color(red: 16/255, green: 6/255, blue: 9/255)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color(red: 168/255, green: 50/255, blue: 73/255).opacity(0.45), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.75), radius: 24, x: 0, y: 12)
        )
    }
}
