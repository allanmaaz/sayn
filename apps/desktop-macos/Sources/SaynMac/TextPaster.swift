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
    
    /// Automatic injection of polished speech directly into the user's active text field
    static func paste(text: String, targetApp: NSRunningApplication? = nil) {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return }
        
        // Check user setting: if auto-paste is disabled in settings, just place on clipboard and return
        if !SaynStore.shared.autoPasteEnabled {
            let pb = NSPasteboard.general
            pb.clearContents()
            pb.setString(cleanText, forType: .string)
            print("[TextPaster] Auto-paste disabled by user setting. Text placed safely on clipboard.")
            return
        }
        
        // Resolve destination application
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
            let pb = NSPasteboard.general
            pb.clearContents()
            pb.setString(cleanText, forType: .string)
            return
        }

        // ─────────────────────────────────────────────────────────────────────────────
        // Tier 1: Verified Direct Accessibility Attribute Replacement (Native Cocoa Instant Injection)
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
        // Tier 2: Safe Hardware Keystroke with Full Pasteboard State Preservation
        // ─────────────────────────────────────────────────────────────────────────────
        // 1. Backup user's existing pasteboard items so we don't clobber their clipboard
        let pasteboard = NSPasteboard.general
        let savedItems = backupPasteboard(pasteboard)
        
        // 2. Put text onto clipboard for paste
        pasteboard.clearContents()
        pasteboard.setString(cleanText, forType: .string)
        
        validApp.activate(options: [.activateIgnoringOtherApps])
        let targetPid = validApp.processIdentifier

        // Cooperative activation delay allowing Electron / Chromium / Native frame buffer to activate
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
            synthesizeHardwareCmdV(pid: targetPid)
            
            // 3. Restore user's previous clipboard contents after paste has completed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                restorePasteboard(pasteboard, from: savedItems)
            }
        }
    }
    
    // MARK: - Pasteboard Backup & Restore
    private struct SavedPasteboardItem {
        let types: [NSPasteboard.PasteboardType]
        let dataByType: [NSPasteboard.PasteboardType: Data]
        let stringByType: [NSPasteboard.PasteboardType: String]
    }
    
    private static func backupPasteboard(_ pasteboard: NSPasteboard) -> [SavedPasteboardItem] {
        guard let items = pasteboard.pasteboardItems else { return [] }
        return items.map { item in
            var dataMap: [NSPasteboard.PasteboardType: Data] = [:]
            var stringMap: [NSPasteboard.PasteboardType: String] = [:]
            for type in item.types {
                if let data = item.data(forType: type) {
                    dataMap[type] = data
                } else if let str = item.string(forType: type) {
                    stringMap[type] = str
                }
            }
            return SavedPasteboardItem(types: item.types, dataByType: dataMap, stringByType: stringMap)
        }
    }
    
    private static func restorePasteboard(_ pasteboard: NSPasteboard, from backup: [SavedPasteboardItem]) {
        guard !backup.isEmpty else { return }
        pasteboard.clearContents()
        for item in backup {
            let pbItem = NSPasteboardItem()
            for type in item.types {
                if let data = item.dataByType[type] {
                    pbItem.setData(data, forType: type)
                } else if let str = item.stringByType[type] {
                    pbItem.setString(str, forType: type)
                }
            }
            pasteboard.writeObjects([pbItem])
        }
    }

    private static func synthesizeHardwareCmdV(pid: pid_t) {
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
