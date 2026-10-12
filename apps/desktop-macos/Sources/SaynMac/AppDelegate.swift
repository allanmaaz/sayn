import AppKit
import SwiftUI
import Carbon

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var pillWindow: WisprPillWindow?
    private let waveformEngine = AudioWaveformEngine()
    private var currentTranscript = ""
    private var eventMonitor: Any?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPillWindow()
        setupGlobalShortcut()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "S"
            button.toolTip = "SAYN — Wispr Flow Voice Assistant (Option + Space)"
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Toggle Voice Pill (⌥ Space)", action: #selector(togglePill), keyEquivalent: " "))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit SAYN", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem.menu = menu
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
        // Global monitor for Option + Space (key code 49 with .option flag)
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains(.option) && event.keyCode == 49 {
                DispatchQueue.main.async {
                    self?.togglePill()
                }
            }
        }
    }
    
    @objc func togglePill() {
        if pillWindow?.isVisible == true {
            hidePill()
        } else {
            showPill()
        }
    }
    
    private func showPill() {
        currentTranscript = ""
        pillWindow?.centerOnScreen()
        pillWindow?.orderFrontRegardless()
        waveformEngine.startRecording { [weak self] transcript in
            self?.currentTranscript = transcript
        }
    }
    
    private func hidePill() {
        waveformEngine.stopRecording()
        pillWindow?.orderOut(nil)
        currentTranscript = ""
    }
    
    private func commitPill(text: String) {
        waveformEngine.stopRecording()
        pillWindow?.orderOut(nil)
        
        // Universally paste text into whichever window was active
        let textToPaste = text.isEmpty ? "Hello, this is SAYN voice typing test." : text
        TextPaster.paste(text: textToPaste)
        currentTranscript = ""
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
