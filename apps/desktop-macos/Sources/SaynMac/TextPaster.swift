import AppKit
import Carbon
import ApplicationServices

final class TextPaster {
    /// Tracks the last non-SAYN active application so text is always pasted into the correct field
    static var lastExternalApp: NSRunningApplication?
    
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
        let app = targetApp ?? lastExternalApp ?? NSWorkspace.shared.frontmostApplication
        guard let validApp = app, validApp.bundleIdentifier != Bundle.main.bundleIdentifier else { return nil }
        
        let appRef = AXUIElementCreateApplication(validApp.processIdentifier)
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
    
    /// Checks whether the target foreground application has an active editable text box / caret
    static func hasActiveEditableTextBox(targetApp: NSRunningApplication? = nil) -> Bool {
        let app = targetApp ?? lastExternalApp ?? NSWorkspace.shared.frontmostApplication
        guard let validApp = app, validApp.bundleIdentifier != Bundle.main.bundleIdentifier else { return false }
        
        let appRef = AXUIElementCreateApplication(validApp.processIdentifier)
        var focusedElement: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appRef, kAXFocusedUIElementAttribute as CFString, &focusedElement) == .success,
              let element = focusedElement else {
            return false
        }
        
        let axElement = element as! AXUIElement
        var roleValue: CFTypeRef?
        if AXUIElementCopyAttributeValue(axElement, kAXRoleAttribute as CFString, &roleValue) == .success,
           let role = roleValue as? String {
            let editableRoles = ["AXTextField", "AXTextArea", "AXWebArea", "AXComboBox", "AXSearchField"]
            if editableRoles.contains(role) { return true }
        }
        
        var isSettable: DarwinBoolean = false
        if AXUIElementIsAttributeSettable(axElement, kAXValueAttribute as CFString, &isSettable) == .success,
           isSettable.boolValue {
            return true
        }
        
        var selectedTextValue: CFTypeRef?
        if AXUIElementCopyAttributeValue(axElement, kAXSelectedTextAttribute as CFString, &selectedTextValue) == .success {
            return true
        }
        
        return false
    }
    
    /// Automatic injection of polished speech directly into the user's active text field
    static func paste(text: String, targetApp: NSRunningApplication? = nil) {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return }
        
        // 1. Copy polished text directly to system clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(cleanText, forType: .string)
        
        // 2. Resolve destination application (guarantee non-SAYN target)
        var appToActivate = targetApp ?? lastExternalApp
        if appToActivate?.bundleIdentifier == Bundle.main.bundleIdentifier || appToActivate == nil {
            let front = NSWorkspace.shared.frontmostApplication
            if front?.bundleIdentifier != Bundle.main.bundleIdentifier {
                appToActivate = front
            } else {
                appToActivate = lastExternalApp
            }
        }
        
        // 3. Force activate target application so its window and caret receive focus
        if let app = appToActivate {
            app.activate(options: [.activateIgnoringOtherApps])
        }
        
        // 4. Synthesize Cmd+V after cooperative window transition delay (140ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
            let pid = appToActivate?.processIdentifier
            
            // Method A: Targeted CoreGraphics HID Event directly to process PID
            let src = CGEventSource(stateID: .hidSystemState)
            let vKeyCode: CGKeyCode = 0x09 // 'v'
            
            if let keyDown = CGEvent(keyboardEventSource: src, virtualKey: vKeyCode, keyDown: true),
               let keyUp = CGEvent(keyboardEventSource: src, virtualKey: vKeyCode, keyDown: false) {
                
                keyDown.flags = .maskCommand
                keyUp.flags = []
                
                // Post directly into target process event stream
                if let targetPid = pid {
                    keyDown.postToPid(targetPid)
                    keyUp.postToPid(targetPid)
                }
                
                // Also broadcast to HID and Session event taps for Electron / Antigravity IDE
                keyDown.post(tap: .cghidEventTap)
                keyUp.post(tap: .cghidEventTap)
                keyDown.post(tap: .cgSessionEventTap)
                keyUp.post(tap: .cgSessionEventTap)
            }
            
            // Method B: AppleScript System Events keystroke redundancy
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
                let scriptSource = """
                tell application "System Events"
                    keystroke "v" using command down
                end tell
                """
                if let script = NSAppleScript(source: scriptSource) {
                    var errorDict: NSDictionary?
                    script.executeAndReturnError(&errorDict)
                }
            }
        }
    }
}
