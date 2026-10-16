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
    
    // Retrieve currently selected text in the active target app for Prompt & Proofread modes
    static func getSelectedText(targetApp: NSRunningApplication? = nil) -> String? {
        guard let app = targetApp ?? NSWorkspace.shared.frontmostApplication else { return nil }
        let appRef = AXUIElementCreateApplication(app.processIdentifier)
        var focusedElement: CFTypeRef?
        let copyResult = AXUIElementCopyAttributeValue(appRef, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        
        if copyResult == .success, let element = focusedElement {
            let axElement = element as! AXUIElement
            var selectedTextValue: CFTypeRef?
            let textResult = AXUIElementCopyAttributeValue(axElement, kAXSelectedTextAttribute as CFString, &selectedTextValue)
            if textResult == .success, let str = selectedTextValue as? String {
                let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    return trimmed
                }
            }
        }
        return nil
    }
    
    static func paste(text: String, targetApp: NSRunningApplication? = nil) {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return }
        
        // 1. Copy polished text directly to system clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(cleanText, forType: .string)
        
        // 2. Identify the app to restore focus to
        let appToActivate = targetApp ?? NSWorkspace.shared.frontmostApplication
        
        // 3. Force activate target application ignoring background daemon
        if let app = appToActivate {
            app.activate(options: [.activateIgnoringOtherApps])
        }
        
        // 4. Synthesize Cmd+V keystroke into the active window (Antigravity IDE, Terminal, VS Code, Slack, etc.)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) {
            // Priority 1: AppleScript System Events keystroke
            // Works 100% reliably in Electron (Antigravity IDE), Terminal, Cursor, VS Code, Browsers, etc.
            let scriptSource = """
            tell application "System Events"
                keystroke "v" using command down
            end tell
            """
            
            var appleScriptSucceeded = false
            if let script = NSAppleScript(source: scriptSource) {
                var errorDict: NSDictionary?
                script.executeAndReturnError(&errorDict)
                if errorDict == nil {
                    appleScriptSucceeded = true
                } else {
                    print("SAYN AppleScript paste notice: \(String(describing: errorDict))")
                }
            }
            
            // Priority 2: CoreGraphics Session Event Tap Fallback
            if !appleScriptSucceeded {
                let src = CGEventSource(stateID: .combinedSessionState)
                let vKeyCode: CGKeyCode = 0x09 // 'v'
                let cmdKeyCode: CGKeyCode = 0x37 // Left Command
                
                if let cmdDown = CGEvent(keyboardEventSource: src, virtualKey: cmdKeyCode, keyDown: true),
                   let vDown = CGEvent(keyboardEventSource: src, virtualKey: vKeyCode, keyDown: true),
                   let vUp = CGEvent(keyboardEventSource: src, virtualKey: vKeyCode, keyDown: false),
                   let cmdUp = CGEvent(keyboardEventSource: src, virtualKey: cmdKeyCode, keyDown: false) {
                    
                    cmdDown.flags = .maskCommand
                    vDown.flags = .maskCommand
                    vUp.flags = .maskCommand
                    cmdUp.flags = []
                    
                    cmdDown.post(tap: .cgSessionEventTap)
                    vDown.post(tap: .cgSessionEventTap)
                    vUp.post(tap: .cgSessionEventTap)
                    cmdUp.post(tap: .cgSessionEventTap)
                }
            }
        }
    }
}
