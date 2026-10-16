import AppKit
import SwiftUI
import Carbon

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var pillWindow: WisprPillWindow?
    private let waveformEngine = AudioWaveformEngine()
    private var currentTranscript = ""
    
    private var eventMonitor: Any?
    private var flagsMonitor: Any?
    private var localFlagsMonitor: Any?
    private var localKeyMonitor: Any?
    
    private var fnPressTimestamp: Date?
    private var fnWasAlreadyOpen: Bool = false
    private var targetApp: NSRunningApplication?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPillWindow()
        setupGlobalShortcut()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            if let logoPath = Bundle.main.path(forResource: "logo", ofType: "png") ?? fallbackLogoPath(),
               let rawImage = NSImage(contentsOfFile: logoPath) {
                let resized = NSImage(size: NSSize(width: 18, height: 18))
                resized.lockFocus()
                rawImage.draw(in: NSRect(x: 0, y: 0, width: 18, height: 18),
                              from: NSRect(origin: .zero, size: rawImage.size),
                              operation: .copy, fraction: 1.0)
                resized.unlockFocus()
                resized.isTemplate = false
                button.image = resized
            } else {
                button.title = "S"
            }
            button.toolTip = "SAYN — Wispr Flow Voice Assistant (Fn key or ⌥ Space)"
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Toggle Voice Pill (Fn or ⌥ Space)", action: #selector(togglePill), keyEquivalent: " "))
        menu.addItem(NSMenuItem.separator())
        
        // Engine Selection Submenu
        let engineSubmenu = NSMenu()
        for engine in TranscriptionEngine.allCases {
            let item = NSMenuItem(title: engine.displayName, action: #selector(selectEngine(_:)), keyEquivalent: "")
            item.representedObject = engine.rawValue
            if engine == waveformEngine.activeEngine {
                item.state = .on
            }
            engineSubmenu.addItem(item)
        }
        let engineMenuItem = NSMenuItem(title: "Speech Engine Mode", action: nil, keyEquivalent: "")
        engineMenuItem.submenu = engineSubmenu
        menu.addItem(engineMenuItem)
        
        menu.addItem(NSMenuItem(title: "⚡ Configure Groq Key (Wispr Turbo)...", action: #selector(configureGroqKey), keyEquivalent: "k"))
        menu.addItem(NSMenuItem(title: "🔑 Enable Auto-Paste (Accessibility)...", action: #selector(openAccessibilitySettings), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit SAYN", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem.menu = menu
    }
    
    @objc func selectEngine(_ sender: NSMenuItem) {
        if let raw = sender.representedObject as? String,
           let engine = TranscriptionEngine(rawValue: raw) {
            waveformEngine.activeEngine = engine
            setupStatusItem()
        }
    }
    
    @objc func configureGroqKey() {
        GroqService.shared.promptForApiKey { saved in
            if saved {
                print("Groq API key updated successfully.")
            }
        }
    }
    
    @objc func openAccessibilitySettings() {
        TextPaster.openAccessibilitySettings()
    }
    
    private func fallbackLogoPath() -> String? {
        let paths = [
            "/Applications/SAYN.app/Contents/Resources/logo.png",
            "/Users/apple/Desktop/SAYN/apps/desktop-macos/Resources/logo.png"
        ]
        return paths.first(where: { FileManager.default.fileExists(atPath: $0) })
    }
    
    private func setupPillWindow() {
        let pillView = WisprPillView(
            waveformEngine: waveformEngine,
            transcriptText: Binding(
                get: { self.currentTranscript },
                set: { self.currentTranscript = $0 }
            ),
            onCancel: { [weak self] in
                self?.hidePill()
            },
            onConfirm: { [weak self] text in
                self?.commitPill(text: text)
            }
        )
        
        let hostingView = NSHostingView(rootView: pillView)
        pillWindow = WisprPillWindow(contentView: hostingView)
    }
    
    private func setupGlobalShortcut() {
        // 1. Global Monitor for Fn / Globe Key (.flagsChanged)
        flagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event: event)
        }
        
        localFlagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event: event)
            return event
        }
        
        // 2. Global Monitor for Option + Space (as alternate shortcut)
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains(.option) && event.keyCode == 49 {
                DispatchQueue.main.async {
                    self?.togglePill()
                }
            }
        }
        
        // 3. Local Monitor for Escape to dismiss & Option+Space
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains(.option) && event.keyCode == 49 {
                DispatchQueue.main.async {
                    self?.togglePill()
                }
                return nil
            } else if event.keyCode == 53 { // Escape
                DispatchQueue.main.async {
                    self?.hidePill()
                }
                return nil
            }
            return event
        }
    }
    
    private func handleFlagsChanged(event: NSEvent) {
        let isFnKey = (event.keyCode == 63) || event.modifierFlags.contains(.function)
        guard isFnKey else { return }
        
        let isPressed = event.modifierFlags.contains(.function)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if isPressed {
                self.fnPressTimestamp = Date()
                if self.pillWindow?.isVisible == true && self.pillWindow?.alphaValue ?? 0 > 0.5 {
                    self.fnWasAlreadyOpen = true
                } else {
                    self.fnWasAlreadyOpen = false
                    self.showPill()
                }
            } else {
                // Fn key released
                guard let pressTime = self.fnPressTimestamp else { return }
                let duration = Date().timeIntervalSince(pressTime)
                self.fnPressTimestamp = nil
                
                if self.fnWasAlreadyOpen {
                    // Quick tap while already open -> commit and close
                    self.commitPill(text: self.currentTranscript)
                    self.fnWasAlreadyOpen = false
                } else if duration > 0.35 {
                    // Push-to-Talk mode: user held Fn while speaking and let go!
                    self.commitPill(text: self.currentTranscript)
                }
                // If quick tap (< 0.35s) while closed: it opened on key down, stays open for dictation!
            }
        }
    }
    
    @objc func togglePill() {
        if pillWindow?.isVisible == true && (pillWindow?.alphaValue ?? 0) > 0.5 {
            hidePill()
        } else {
            showPill()
        }
    }
    
    private func showPill() {
        // Record the exact application that had focus when the user triggered dictation
        let front = NSWorkspace.shared.frontmostApplication
        if front?.bundleIdentifier != Bundle.main.bundleIdentifier {
            targetApp = front
        }
        currentTranscript = ""
        
        pillWindow?.showAnimated()
        waveformEngine.startRecording { [weak self] transcript in
            self?.currentTranscript = transcript
        }
    }
    
    private func hidePill() {
        waveformEngine.stopRecording { _ in }
        pillWindow?.hideAnimated()
        currentTranscript = ""
    }
    
    private func commitPill(text: String) {
        let appToPasteInto = targetApp
        
        waveformEngine.stopRecording(activeAppBundleId: appToPasteInto?.bundleIdentifier) { [weak self] finalText in
            // Immediately dismiss the floating pill smoothly
            self?.pillWindow?.hideAnimated()
            
            let chosen = finalText.isEmpty ? text : finalText
            let trimmed = chosen.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !trimmed.isEmpty {
                // Automatically re-activate the target app and paste into the text box
                TextPaster.paste(text: trimmed, targetApp: appToPasteInto)
            }
            self?.currentTranscript = ""
        }
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
