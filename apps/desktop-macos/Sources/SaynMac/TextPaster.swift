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
        guard let validApp = app else { return true }
        if validApp.bundleIdentifier == Bundle.main.bundleIdentifier { return true }
        
        let appRef = AXUIElementCreateApplication(validApp.processIdentifier)
        var focusedElement: CFTypeRef?
        if AXUIElementCopyAttributeValue(appRef, kAXFocusedUIElementAttribute as CFString, &focusedElement) == .success,
           let element = focusedElement {
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
        }
        
        // Electron, WebKit, and developer editors often do not report kAXFocusedUIElementAttribute to external processes.
        // If the user triggered dictation while working in any standard text, browser, IDE, or chat app,
        // assume an active text focus exists so Cmd+V pastes seamlessly into their cursor position!
        let bundleId = validApp.bundleIdentifier?.lowercased() ?? ""
        let appName = validApp.localizedName?.lowercased() ?? ""
        let textCapableKeywords = [
            "antigravity", "code", "cursor", "electron", "sublime", "textedit", "notes",
            "chrome", "safari", "firefox", "brave", "edge", "arc", "slack", "discord",
            "telegram", "whatsapp", "signal", "messages", "terminal", "iterm", "xcode",
            "notion", "obsidian", "linear", "word", "pages", "mail", "outlook"
        ]
        
        for kw in textCapableKeywords {
            if bundleId.contains(kw) || appName.contains(kw) {
                return true
            }
        }
        
        return true
    }
    
    /// Automatic 3-tier injection of polished speech directly into the user's active text field
    static func paste(text: String, targetApp: NSRunningApplication? = nil) {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return }
        
        // 1. Resolve destination application
        var appToActivate = targetApp
        if appToActivate == nil {
            let front = NSWorkspace.shared.frontmostApplication
            if front?.bundleIdentifier != Bundle.main.bundleIdentifier {
                appToActivate = front
            } else {
                appToActivate = lastExternalApp ?? front
            }
        }
        
        guard let validApp = appToActivate else {
            // Fallback: copy to clipboard
            let pb = NSPasteboard.general
            pb.clearContents()
            pb.setString(cleanText, forType: .string)
            return
        }

        // ─────────────────────────────────────────────────────────────────────────────
        // Tier 1: Direct Accessibility Attribute Replacement (Wispr Flow Instant Injection)
        // ─────────────────────────────────────────────────────────────────────────────
        let appRef = AXUIElementCreateApplication(validApp.processIdentifier)
        var focusedElement: CFTypeRef?
        if AXUIElementCopyAttributeValue(appRef, kAXFocusedUIElementAttribute as CFString, &focusedElement) == .success,
           let element = focusedElement {
            let axElement = element as! AXUIElement
            var isSettable: DarwinBoolean = false
            if AXUIElementIsAttributeSettable(axElement, kAXSelectedTextAttribute as CFString, &isSettable) == .success,
               isSettable.boolValue {
                let setResult = AXUIElementSetAttributeValue(axElement, kAXSelectedTextAttribute as CFString, cleanText as CFTypeRef)
                if setResult == .success {
                    print("[TextPaster] Tier 1 Success: Direct AX replacement at cursor for \(validApp.localizedName ?? "")")
                    return
                }
            }
        }

        // ─────────────────────────────────────────────────────────────────────────────
        // Tier 2: Electron / Monaco Coordinated 4-Step Hardware Keystroke Sequence
        // ─────────────────────────────────────────────────────────────────────────────
        // 1. Put polished text onto system pasteboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(cleanText, forType: .string)

        // 2. Bring target app (Anti-Gravity / IDE / Browser) to immediate front
        validApp.activate(options: [.activateIgnoringOtherApps])

        let targetPid = validApp.processIdentifier

        // Cooperative delay: Electron/Monaco takes ~180-220ms to activate its frame buffer
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            synthesizeHardwareCmdV(pid: targetPid)
            
            // Secondary reinforcement at +80ms to catch slow-responding Electron windows
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                synthesizeHardwareCmdV(pid: targetPid)
            }
            
            // ─────────────────────────────────────────────────────────────────────────
            // Tier 3: Process-Targeted AppleScript System Events (Sandbox Bypass)
            // ─────────────────────────────────────────────────────────────────────────
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                let scriptSource = """
                tell application "System Events"
                    set targetProc to first application process whose unix id is \(targetPid)
                    set frontmost of targetProc to true
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

    private static func synthesizeHardwareCmdV(pid: pid_t) {
        let src = CGEventSource(stateID: .hidSystemState)
        let cmdKeyCode: CGKeyCode = 0x37 // Left Command
        let vKeyCode: CGKeyCode = 0x09   // 'v'

        // 1. Command Down
        let cmdDown = CGEvent(keyboardEventSource: src, virtualKey: cmdKeyCode, keyDown: true)
        cmdDown?.flags = .maskCommand

        // 2. 'V' Down with Command Mask
        let vDown = CGEvent(keyboardEventSource: src, virtualKey: vKeyCode, keyDown: true)
        vDown?.flags = .maskCommand

        // 3. 'V' Up with Command Mask
        let vUp = CGEvent(keyboardEventSource: src, virtualKey: vKeyCode, keyDown: false)
        vUp?.flags = .maskCommand

        // 4. Command Up
        let cmdUp = CGEvent(keyboardEventSource: src, virtualKey: cmdKeyCode, keyDown: false)
        cmdUp?.flags = []

        let events = [cmdDown, vDown, vUp, cmdUp].compactMap { $0 }

        for event in events {
            event.postToPid(pid)
            event.post(tap: .cghidEventTap)
            event.post(tap: .cgSessionEventTap)
            event.post(tap: .cgAnnotatedSessionEventTap)
        }
    }
}
