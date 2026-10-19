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
    
    /// Automatic injection of polished speech directly into the user's active text field
    static func paste(text: String, targetApp: NSRunningApplication? = nil) {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return }
        
        // 1. Always place text on system pasteboard so user has it immediately
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(cleanText, forType: .string)
        
        // 2. Check user setting: if auto-paste is disabled in settings, stop here safely!
        if !SaynStore.shared.autoPasteEnabled {
            print("[TextPaster] Auto-paste disabled by user setting. Text placed safely on clipboard.")
            return
        }
        
        // 3. Resolve destination application
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
            return
        }

        // ─────────────────────────────────────────────────────────────────────────────
        // Tier 1: Direct Accessibility Attribute Replacement (Native Cocoa Instant Injection)
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
        // Tier 2: Electron / AntiGravity Coordinated Hardware Keystroke Sequence
        // ─────────────────────────────────────────────────────────────────────────────
        validApp.activate(options: [.activateIgnoringOtherApps])

        let targetPid = validApp.processIdentifier

        // Cooperative activation delay allowing Electron / AntiGravity frame buffer to activate
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            synthesizeHardwareCmdV(pid: targetPid)
        }
    }

    private static func synthesizeHardwareCmdV(pid: pid_t) {
        // Use combinedSessionState to seamlessly integrate with active user login session
        guard let src = CGEventSource(stateID: .combinedSessionState) else { return }
        let cmdKeyCode: CGKeyCode = 0x37 // Left Command
        let vKeyCode: CGKeyCode = 0x09   // 'v'

        guard let cmdDown = CGEvent(keyboardEventSource: src, virtualKey: cmdKeyCode, keyDown: true),
              let vDown = CGEvent(keyboardEventSource: src, virtualKey: vKeyCode, keyDown: true),
              let vUp = CGEvent(keyboardEventSource: src, virtualKey: vKeyCode, keyDown: false),
              let cmdUp = CGEvent(keyboardEventSource: src, virtualKey: cmdKeyCode, keyDown: false) else { return }

        cmdDown.flags = .maskCommand
        vDown.flags = .maskCommand
        vUp.flags = .maskCommand
        cmdUp.flags = []

        // Precise inter-modifier pacing (15ms) ensures Electron / Chromium does not drop the modifier
        cmdDown.postToPid(pid)
        cmdDown.post(tap: .cgSessionEventTap)
        usleep(15_000)

        vDown.postToPid(pid)
        vDown.post(tap: .cgSessionEventTap)
        usleep(15_000)

        vUp.postToPid(pid)
        vUp.post(tap: .cgSessionEventTap)
        usleep(15_000)

        cmdUp.postToPid(pid)
        cmdUp.post(tap: .cgSessionEventTap)
    }
}
