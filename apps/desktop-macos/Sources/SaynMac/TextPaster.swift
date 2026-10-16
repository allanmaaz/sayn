import AppKit
import Carbon
import ApplicationServices

final class TextPaster {
    @discardableResult
    static func checkAccessibilityPermission(prompt: Bool = false) -> Bool {
        if prompt {
            let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            return AXIsProcessTrustedWithOptions(options)
        }
        return AXIsProcessTrusted()
    }
    
    static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    static func paste(text: String, targetApp: NSRunningApplication? = nil) {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return }
        
        // 1. Always copy text to system pasteboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(cleanText, forType: .string)
        
        // 2. Reactivate the target application where the user had the cursor
        if let app = targetApp {
            app.activate()
        }
        
        // 3. Tier 1: Try Direct Accessibility Insertion (Instant, zero clipboard race)
        if let app = targetApp {
            let appRef = AXUIElementCreateApplication(app.processIdentifier)
            var focusedElement: CFTypeRef?
            let copyResult = AXUIElementCopyAttributeValue(appRef, kAXFocusedUIElementAttribute as CFString, &focusedElement)
            
            if copyResult == .success, let element = focusedElement {
                let axElement = element as! AXUIElement
                let setResult = AXUIElementSetAttributeValue(axElement, kAXSelectedTextAttribute as CFString, cleanText as CFTypeRef)
                if setResult == .success {
                    return // Injected directly into active chat box / text input!
                }
            }
        }
        
        // 4. Tier 2: Synthesize Cmd+V with proper focus delay (140ms for Electron/Web/Native)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
            let src = CGEventSource(stateID: .combinedSessionState)
            let vKeyCode: CGKeyCode = 0x09 // 'v'
            let cmdKeyCode: CGKeyCode = 0x37 // Left Command
            
            // Post explicit sequence: Cmd down -> V down -> V up -> Cmd up
            if let cmdDown = CGEvent(keyboardEventSource: src, virtualKey: cmdKeyCode, keyDown: true),
               let vDown = CGEvent(keyboardEventSource: src, virtualKey: vKeyCode, keyDown: true),
               let vUp = CGEvent(keyboardEventSource: src, virtualKey: vKeyCode, keyDown: false),
               let cmdUp = CGEvent(keyboardEventSource: src, virtualKey: cmdKeyCode, keyDown: false) {
                
                cmdDown.flags = .maskCommand
                vDown.flags = .maskCommand
                vUp.flags = .maskCommand
                cmdUp.flags = []
                
                // If target app is known, deliver directly to its process event queue
                if let pid = targetApp?.processIdentifier {
                    cmdDown.postToPid(pid)
                    vDown.postToPid(pid)
                    vUp.postToPid(pid)
                    cmdUp.postToPid(pid)
                }
                
                // Also broadcast to HID event tap as standard fallback
                cmdDown.post(tap: .cghidEventTap)
                vDown.post(tap: .cghidEventTap)
                vUp.post(tap: .cghidEventTap)
                cmdUp.post(tap: .cghidEventTap)
            }
        }
    }
}
