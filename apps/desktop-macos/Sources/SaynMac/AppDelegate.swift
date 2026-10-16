import AppKit
import SwiftUI
import Carbon

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var pillWindow: SanPillWindow?
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
                button.title = "SAYN"
            }
            button.toolTip = "SAYN — Voice Dictation & AI Studio (Fn key or ⌥ Space)"
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Toggle SAYN Voice (Fn or ⌥ Space)", action: #selector(togglePill), keyEquivalent: " "))
        menu.addItem(NSMenuItem(title: "Cycle Mode (⌥ M)", action: #selector(cycleModeAction), keyEquivalent: "m"))
        menu.addItem(NSMenuItem.separator())
        
        // 1. Execution Modes Submenu
        let modeSubmenu = NSMenu()
        for mode in SanExecutionMode.allCases {
            let item = NSMenuItem(title: "\(mode.displayName) Mode", action: #selector(selectModeAction(_:)), keyEquivalent: "")
            item.representedObject = mode.rawValue
            if mode == waveformEngine.currentMode {
                item.state = .on
            }
            modeSubmenu.addItem(item)
        }
        let modeMenuItem = NSMenuItem(title: "Active Mode: \(waveformEngine.currentMode.displayName)", action: nil, keyEquivalent: "")
        modeMenuItem.submenu = modeSubmenu
        menu.addItem(modeMenuItem)
        
        // 2. Tone / Style Submenu
        let styleSubmenu = NSMenu()
        let styles = [
            ("natural", "Natural (Authentic & Conversational)"),
            ("fluent", "Fluent (Polished Grammar & Flow)"),
            ("professional", "Professional (Executive & Formal)")
        ]
        
        for (id, label) in styles {
            let item = NSMenuItem(title: label, action: #selector(selectStyle(_:)), keyEquivalent: "")
            item.representedObject = id
            if id == waveformEngine.activeStyle {
                item.state = .on
            }
            styleSubmenu.addItem(item)
        }
        
        let styleMenuItem = NSMenuItem(title: "Tone & Style Mode", action: nil, keyEquivalent: "")
        styleMenuItem.submenu = styleSubmenu
        menu.addItem(styleMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "📝 Edit Custom Vocabulary...", action: #selector(openVocabularyFile), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "⚡ Edit Voice Snippets...", action: #selector(openSnippetsFile), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "🔑 Enable Auto-Paste (Accessibility)...", action: #selector(openAccessibilitySettings), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit SAYN", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem.menu = menu
    }
    
    @objc func cycleModeAction() {
        waveformEngine.cycleNextMode()
        setupStatusItem()
    }
    
    @objc func selectModeAction(_ sender: NSMenuItem) {
        if let raw = sender.representedObject as? String,
           let mode = SanExecutionMode(rawValue: raw) {
            waveformEngine.setMode(mode)
            setupStatusItem()
        }
    }
    
    @objc func selectStyle(_ sender: NSMenuItem) {
        if let styleId = sender.representedObject as? String {
            waveformEngine.activeStyle = styleId
            setupStatusItem()
        }
    }
    
    @objc func openVocabularyFile() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let vocabURL = home.appendingPathComponent(".sayn/vocabulary.json")
        let fallbackURL = home.appendingPathComponent(".san/vocabulary.json")
        if FileManager.default.fileExists(atPath: vocabURL.path) {
            NSWorkspace.shared.open(vocabURL)
        } else {
            NSWorkspace.shared.open(fallbackURL)
        }
    }
    
    @objc func openSnippetsFile() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let snippetsURL = home.appendingPathComponent(".sayn/snippets.json")
        let fallbackURL = home.appendingPathComponent(".san/snippets.json")
        if FileManager.default.fileExists(atPath: snippetsURL.path) {
            NSWorkspace.shared.open(snippetsURL)
        } else {
            NSWorkspace.shared.open(fallbackURL)
        }
    }
    
    @objc func openAccessibilitySettings() {
        TextPaster.openAccessibilitySettings()
    }
    
    private func fallbackLogoPath() -> String? {
        let paths = [
            Bundle.main.path(forResource: "logo", ofType: "png"),
            "/Applications/SAYN.app/Contents/Resources/logo.png",
            "/Applications/San.app/Contents/Resources/logo.png",
            "/Users/apple/Desktop/SAYN/apps/desktop-macos/Resources/logo.png"
        ]
        return paths.compactMap({ $0 }).first(where: { FileManager.default.fileExists(atPath: $0) })
    }
    
    private func setupPillWindow() {
        let pillView = SanPillView(
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
        pillWindow = SanPillWindow(contentView: hostingView)
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
        
        // 2. Global Monitor for Option + Space (Toggle) & Option + M (Cycle Mode)
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains(.option) && event.keyCode == 49 { // Option + Space
                DispatchQueue.main.async {
                    self?.togglePill()
                }
            } else if event.modifierFlags.contains(.option) && event.keyCode == 46 { // Option + M
                DispatchQueue.main.async {
                    self?.waveformEngine.cycleNextMode()
                    self?.setupStatusItem()
                }
            }
        }
        
        // 3. Local Monitor for Escape to dismiss, Option+Space, Option+M
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains(.option) && event.keyCode == 49 {
                DispatchQueue.main.async {
                    self?.togglePill()
                }
                return nil
            } else if event.modifierFlags.contains(.option) && event.keyCode == 46 {
                DispatchQueue.main.async {
                    self?.waveformEngine.cycleNextMode()
                    self?.setupStatusItem()
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
                if self.pillWindow?.isVisible == true && (self.pillWindow?.alphaValue ?? 0) > 0.5 {
                    self.fnWasAlreadyOpen = true
                } else {
                    self.fnWasAlreadyOpen = false
                    self.showPill()
                }
            } else {
                guard let pressTime = self.fnPressTimestamp else { return }
                let duration = Date().timeIntervalSince(pressTime)
                self.fnPressTimestamp = nil
                
                if self.fnWasAlreadyOpen {
                    self.commitPill(text: self.currentTranscript)
                    self.fnWasAlreadyOpen = false
                } else if duration > 0.35 {
                    self.commitPill(text: self.currentTranscript)
                }
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
        let front = NSWorkspace.shared.frontmostApplication
        if front?.bundleIdentifier != Bundle.main.bundleIdentifier {
            targetApp = front
        }
        currentTranscript = ""
        
        // Capture currently selected text if entering Prompt or Proofread mode
        if waveformEngine.currentMode == .prompt || waveformEngine.currentMode == .proofread {
            waveformEngine.selectedContextText = TextPaster.getSelectedText(targetApp: targetApp)
        }
        
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
        let appToPasteInto = targetApp ?? NSWorkspace.shared.frontmostApplication
        
        waveformEngine.stopRecording(activeAppBundleId: appToPasteInto?.bundleIdentifier) { [weak self] finalText in
            self?.pillWindow?.orderOut(nil)
            
            let chosen = finalText.isEmpty ? text : finalText
            let trimmed = chosen.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !trimmed.isEmpty {
                TextPaster.paste(text: trimmed, targetApp: appToPasteInto)
            }
            self?.currentTranscript = ""
        }
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
