import AppKit
import SwiftUI

/// Main Window Controller and Native Studio Window for SAYN macOS App
final class SaynMainWindow: NSWindow, NSWindowDelegate {
    init(contentView: NSView) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 880, height: 620),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        self.delegate = self
        self.title = "SAYN — AI Studio"
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.isMovableByWindowBackground = true
        self.backgroundColor = NSColor(red: 16/255, green: 7/255, blue: 9/255, alpha: 1.0)
        self.minSize = NSSize(width: 760, height: 520)
        self.contentView = contentView
        self.center()
        self.setFrameAutosaveName("SaynMainWindowAutosave")
    }
    
    // When user clicks the red close button, hide the window instead of quitting,
    // so global background shortcuts (Fn / Option+Space) stay active and clicking
    // the Dock icon brings it right back!
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        self.orderOut(nil)
        return false
    }
}

/// Native SwiftUI Main Studio View for SAYN on MacBook
struct SaynStudioView: View {
    @ObservedObject var waveformEngine: AudioWaveformEngine
    var onToggleDictation: () -> Void
    var onRefineText: (String, @escaping (String) -> Void) -> Void
    
    @State private var inputText: String = ""
    @State private var refinedText: String = ""
    @State private var isRefining: Bool = false
    @State private var copied: Bool = false
    @State private var autoPasted: Bool = false
    @State private var statusMessage: String = "Ready to dictate"
    
    // Official SAYN Colors
    private let bgDark = Color(red: 16/255, green: 7/255, blue: 9/255)
    private let cardDark = Color(red: 24/255, green: 11/255, blue: 15/255)
    private let cardInset = Color(red: 14/255, green: 5/255, blue: 7/255)
    private let borderDark = Color(red: 61/255, green: 21/255, blue: 32/255)
    private let accentMaroon = Color(red: 111/255, green: 16/255, blue: 37/255)
    private let roseMaroon = Color(red: 168/255, green: 50/255, blue: 73/255)
    private let warmCream = Color(red: 245/255, green: 235/255, blue: 221/255)
    private let mutedCream = Color(red: 168/255, green: 159/255, blue: 145/255)
    
    var body: some View {
        ZStack {
            bgDark.ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Top Header Section
                headerBar
                
                // Controls Strip (Mode + Style + Shortcuts)
                controlsBar
                
                // Main Dual-Pane Studio
                HStack(spacing: 16) {
                    // Left: Input & Speech Studio
                    inputCard
                    
                    // Center Floating Arrow Button
                    refineArrowButton
                    
                    // Right: Refined Natural Output
                    outputCard
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Bottom Shortcuts & System Status Bar
                bottomBar
            }
            .padding(20)
        }
        .frame(minWidth: 760, minHeight: 520)
    }
    
    // MARK: - Header Bar
    private var headerBar: some View {
        HStack(alignment: .center, spacing: 12) {
            // SAYN Logo Icon
            ZStack {
                Circle()
                    .fill(accentMaroon)
                    .frame(width: 36, height: 36)
                
                Image(systemName: "waveform.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundColor(warmCream)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text("SAYN")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(warmCream)
                    
                    Text("AI Studio")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(warmCream.opacity(0.9))
                    
                    // Status Badge
                    HStack(spacing: 5) {
                        Circle()
                            .fill(waveformEngine.isRecording ? Color.red : (isRefining ? Color.orange : Color.green))
                            .frame(width: 7, height: 7)
                        
                        Text(waveformEngine.isRecording ? "Listening..." : (isRefining ? "Polishing..." : "Ready"))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(warmCream)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(borderDark.opacity(0.6))
                    .cornerRadius(12)
                }
                
                Text("Turn your rough thoughts into clear, refined writing with natural human flow.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(mutedCream)
            }
            
            Spacer()
            
            // Voice Dictation (Fn) Top Button
            Button(action: onToggleDictation) {
                HStack(spacing: 6) {
                    Image(systemName: waveformEngine.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text(waveformEngine.isRecording ? "Stop Dictation" : "Voice Dictation (Fn)")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(warmCream)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(waveformEngine.isRecording ? Color.red : accentMaroon)
                .cornerRadius(20)
                .shadow(color: accentMaroon.opacity(0.4), radius: 6, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Controls Bar
    private var controlsBar: some View {
        HStack(spacing: 16) {
            // Mode Segmented Control
            HStack(spacing: 8) {
                Text("Mode:")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(mutedCream)
                
                HStack(spacing: 4) {
                    ForEach(SanExecutionMode.allCases, id: \.self) { mode in
                        let isSelected = waveformEngine.currentMode == mode
                        Button(action: {
                            waveformEngine.setMode(mode)
                        }) {
                            Text(mode.displayName)
                                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? warmCream : mutedCream)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(isSelected ? accentMaroon : Color.clear)
                                .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(3)
                .background(cardInset)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(borderDark, lineWidth: 1))
            }
            
            Divider()
                .frame(height: 18)
                .background(borderDark)
            
            // Style Selector
            HStack(spacing: 8) {
                Text("Style:")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(mutedCream)
                
                let styles: [(String, String)] = [
                    ("natural", "Natural (Human Flow)"),
                    ("fluent", "Fluent"),
                    ("professional", "Professional")
                ]
                
                HStack(spacing: 4) {
                    ForEach(styles, id: \.0) { item in
                        let isSelected = waveformEngine.activeStyle == item.0
                        Button(action: {
                            waveformEngine.activeStyle = item.0
                        }) {
                            Text(item.1)
                                .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? warmCream : mutedCream)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(isSelected ? roseMaroon.opacity(0.8) : Color.clear)
                                .cornerRadius(10)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(3)
                .background(cardInset)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderDark, lineWidth: 1))
            }
            
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(cardDark)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(borderDark, lineWidth: 1))
    }
    
    // MARK: - Left Card: Input Text & Speech
    private var inputCard: some View {
        VStack(spacing: 12) {
            // Card Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 12))
                        .foregroundColor(roseMaroon)
                    Text("Input Text & Speech")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(warmCream)
                }
                
                Spacer()
                
                Button(action: {
                    inputText = ""
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                        Text("Clear")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(mutedCream)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Text Input Box
            ZStack(alignment: .topLeading) {
                cardInset
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderDark, lineWidth: 1))
                
                if inputText.isEmpty && !waveformEngine.isRecording {
                    Text("Speak using the Fn key or microphone button below, or type your thoughts here...")
                        .font(.system(size: 13))
                        .foregroundColor(mutedCream.opacity(0.6))
                        .padding(12)
                }
                
                TextEditor(text: $inputText)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(warmCream)
                    .padding(8)
                    .background(Color.clear)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Audio Waveform Visualizer (Active during recording)
            if waveformEngine.isRecording {
                HStack(spacing: 4) {
                    ForEach(0..<waveformEngine.audioLevels.count, id: \.self) { idx in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(accentMaroon)
                            .frame(width: 4, height: max(6, CGFloat(waveformEngine.audioLevels[idx]) * 32))
                            .animation(.easeOut(duration: 0.08), value: waveformEngine.audioLevels[idx])
                    }
                }
                .frame(height: 24)
            }
            
            // Footer
            HStack {
                let count = inputText.split(separator: " ").count
                Text("\(count) \(count == 1 ? "word" : "words")")
                    .font(.system(size: 11))
                    .foregroundColor(mutedCream)
                
                Spacer()
                
                Button(action: onToggleDictation) {
                    HStack(spacing: 6) {
                        Image(systemName: waveformEngine.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 11))
                        Text(waveformEngine.isRecording ? "Listening..." : "Dictate")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(warmCream)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(waveformEngine.isRecording ? Color.red : accentMaroon)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(14)
        .background(cardDark)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(borderDark, lineWidth: 1))
    }
    
    // MARK: - Center Refine Arrow Button
    private var refineArrowButton: some View {
        Button(action: executeRefine) {
            ZStack {
                Circle()
                    .fill(accentMaroon)
                    .frame(width: 38, height: 38)
                    .overlay(Circle().stroke(roseMaroon, lineWidth: 1))
                    .shadow(color: accentMaroon.opacity(0.5), radius: 8, x: 0, y: 2)
                
                if isRefining {
                    ProgressView()
                        .scaleEffect(0.7)
                        .colorScheme(.dark)
                } else {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(warmCream)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isRefining)
        .opacity(inputText.isEmpty ? 0.5 : 1.0)
    }
    
    // MARK: - Right Card: Refined Natural Output
    private var outputCard: some View {
        VStack(spacing: 12) {
            // Card Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundColor(roseMaroon)
                    Text("Refined Output")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(warmCream)
                    
                    Text("(Natural Flow)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(mutedCream)
                }
                
                Spacer()
                
                // Copy Button
                Button(action: copyToClipboard) {
                    HStack(spacing: 4) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 10))
                        Text(copied ? "Copied" : "Copy")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(copied ? Color.green : warmCream)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(borderDark)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(refinedText.isEmpty)
                
                // Auto-Paste to Frontmost App Button
                Button(action: autoPasteToFrontmostApp) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.turn.up.right")
                            .font(.system(size: 10))
                        Text(autoPasted ? "Pasted!" : "Auto-Paste")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(autoPasted ? Color.green : warmCream)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(borderDark)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(refinedText.isEmpty)
            }
            
            // Output Content Box
            ZStack {
                cardInset
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderDark, lineWidth: 1))
                
                if refinedText.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 32))
                            .foregroundColor(roseMaroon.opacity(0.4))
                        
                        Text("Your refined text will appear here")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(warmCream)
                        
                        Text("Zero excessive commas, full stops, or underscores.\nPure, natural human communication.")
                            .font(.system(size: 11))
                            .foregroundColor(mutedCream)
                            .multilineTextAlignment(.center)
                    }
                    .padding(20)
                } else {
                    ScrollView {
                        Text(refinedText)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(warmCream)
                            .lineSpacing(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Footer
            HStack {
                let count = refinedText.split(separator: " ").count
                Text("\(count) \(count == 1 ? "word" : "words")")
                    .font(.system(size: 11))
                    .foregroundColor(mutedCream)
                
                Spacer()
                
                if !refinedText.isEmpty {
                    Button(action: {
                        inputText = refinedText
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 10))
                            Text("Use as Input")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(warmCream)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(borderDark)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(14)
        .background(cardDark)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(borderDark, lineWidth: 1))
    }
    
    // MARK: - Bottom Bar
    private var bottomBar: some View {
        HStack(spacing: 16) {
            // Global Shortcut Indicators
            HStack(spacing: 12) {
                shortcutBadge(key: "Fn key", desc: "Hold/Tap anywhere to speak")
                shortcutBadge(key: "⌥ Space", desc: "Toggle floating pill")
                shortcutBadge(key: "⌥ M", desc: "Cycle mode")
            }
            
            Spacer()
            
            // Quick Links to Vocabulary & Snippets
            Button(action: {
                openConfigURL("vocabulary.json")
            }) {
                Text("Custom Vocabulary")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(mutedCream)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                openConfigURL("snippets.json")
            }) {
                Text("Voice Snippets")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(mutedCream)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                TextPaster.openAccessibilitySettings()
            }) {
                Text("Accessibility Permissions")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(mutedCream)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 4)
    }
    
    private func shortcutBadge(key: String, desc: String) -> some View {
        HStack(spacing: 5) {
            Text(key)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(warmCream)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(borderDark)
                .cornerRadius(4)
            
            Text(desc)
                .font(.system(size: 10))
                .foregroundColor(mutedCream)
        }
    }
    
    // MARK: - Actions
    private func executeRefine() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        isRefining = true
        onRefineText(text) { result in
            DispatchQueue.main.async {
                self.refinedText = result
                self.isRefining = false
            }
        }
    }
    
    private func copyToClipboard() {
        guard !refinedText.isEmpty else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(refinedText, forType: .string)
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            copied = false
        }
    }
    
    private func autoPasteToFrontmostApp() {
        guard !refinedText.isEmpty else { return }
        TextPaster.paste(text: refinedText)
        autoPasted = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            autoPasted = false
        }
    }
    
    private func openConfigURL(_ filename: String) {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let url = home.appendingPathComponent(".sayn/\(filename)")
        let fallback = home.appendingPathComponent(".san/\(filename)")
        if FileManager.default.fileExists(atPath: url.path) {
            NSWorkspace.shared.open(url)
        } else if FileManager.default.fileExists(atPath: fallback.path) {
            NSWorkspace.shared.open(fallback)
        }
    }
}
