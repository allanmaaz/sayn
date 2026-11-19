import AppKit
import Carbon
import ApplicationServices

/// Preserved pasteboard state for non-destructive clipboard restoration
struct PreservedPasteboardSnapshot {
    struct Item {
        let types: [NSPasteboard.PasteboardType]
        let dataByType: [NSPasteboard.PasteboardType: Data]
        let stringByType: [NSPasteboard.PasteboardType: String]
    }
    let items: [Item]

    init(pasteboard: NSPasteboard) {
        self.items = (pasteboard.pasteboardItems ?? []).map { item in
            var dataMap: [NSPasteboard.PasteboardType: Data] = [:]
            var stringMap: [NSPasteboard.PasteboardType: String] = [:]
            for type in item.types {
                if let data = item.data(forType: type) {
                    dataMap[type] = data
                } else if let str = item.string(forType: type) {
                    stringMap[type] = str
                }
            }
            return Item(types: item.types, dataByType: dataMap, stringByType: stringMap)
        }
    }

    func restore(to pasteboard: NSPasteboard) {
        pasteboard.clearContents()
        guard !items.isEmpty else { return }
        for item in items {
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
}

struct PendingClipboardRestore {
    let snapshot: PreservedPasteboardSnapshot
    let writtenTranscript: String
    let expectedChangeCount: Int
}

final class TextPaster {
    /// Tracks the last non-SAYN active application so text is always pasted into the correct field
    static var lastExternalApp: NSRunningApplication?
    
    /// Delay before restoring clipboard so target app has plenty of time to process the paste event (1.0 second, matching FreeFlow)
    private static let clipboardRestoreDelay: TimeInterval = 1.0
    private static let pasteAfterShortcutReleaseDelay: TimeInterval = 0.03
    
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
    
    /// Checks whether user is still physically holding modifier keys (Fn, Option, Command, Control)
    static var hasPressedModifierKeys: Bool {
        let flags = NSEvent.modifierFlags
        // Check for Option, Control, or Function (Fn/Globe)
        return flags.contains(.option) || flags.contains(.control) || flags.contains(.function)
    }

    /// Appends trailing space after sentence punctuation to prevent jamming against subsequent speech
    private static func formatTextForInsertion(_ text: String) -> String {
        guard let last = text.last, ".!?".contains(last) else { return text }
        return text + " "
    }

    /// Writes transcript to system pasteboard with standard transient types so clipboard managers skip it
    private static func writeTranscriptToPasteboard(_ text: String) -> PendingClipboardRestore {
        let pasteboard = NSPasteboard.general
        let snapshot = PreservedPasteboardSnapshot(pasteboard: pasteboard)
        let textToWrite = formatTextForInsertion(text)

        let transientType = NSPasteboard.PasteboardType("org.nspasteboard.TransientType")
        let concealedType = NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")
        let autoGeneratedType = NSPasteboard.PasteboardType("org.nspasteboard.AutoGeneratedType")
        let legacyTransientType = NSPasteboard.PasteboardType("de.petermaurer.TransientPasteboardType")

        pasteboard.declareTypes([
            .string,
            transientType,
            concealedType,
            autoGeneratedType,
            legacyTransientType
        ], owner: nil)

        pasteboard.setString(textToWrite, forType: .string)
        pasteboard.setString("", forType: transientType)
        pasteboard.setString("", forType: concealedType)
        pasteboard.setString("", forType: autoGeneratedType)
        pasteboard.setString("", forType: legacyTransientType)

        return PendingClipboardRestore(
            snapshot: snapshot,
            writtenTranscript: textToWrite,
            expectedChangeCount: pasteboard.changeCount
        )
    }

    /// Restores the user's prior clipboard safely after target app has consumed the paste
    private static func restoreClipboardIfNeeded(_ pendingRestore: PendingClipboardRestore) {
        DispatchQueue.main.asyncAfter(deadline: .now() + clipboardRestoreDelay) {
            let pasteboard = NSPasteboard.general
            let clipboardStillHoldsTranscript =
                pasteboard.string(forType: .string) == pendingRestore.writtenTranscript
            
            // Only restore if user hasn't deliberately copied something new in the meantime
            guard pasteboard.changeCount == pendingRestore.expectedChangeCount || clipboardStillHoldsTranscript else {
                return
            }
            pendingRestore.snapshot.restore(to: pasteboard)
            print("[TextPaster] Original clipboard state restored successfully.")
        }
    }

    /// Waits for all modifier keys to be physically released before posting paste
    private static func performAfterShortcutReleased(attempt: Int = 0, action: @escaping () -> Void) {
        let maxAttempts = 24
        if hasPressedModifierKeys && attempt < maxAttempts {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.025) {
                performAfterShortcutReleased(attempt: attempt + 1, action: action)
            }
            return
        }

        // WindowServer stabilization delay
        DispatchQueue.main.asyncAfter(deadline: .now() + pasteAfterShortcutReleaseDelay) {
            action()
        }
    }

    /// FreeFlow hardware-level Cmd-V paste synthesis via .hidSystemState
    private static func pasteAtCursor(processIdentifier: pid_t? = nil) {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }
        let vKeyCode: CGKeyCode = 9 // 'v'

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) else { return }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        if let processIdentifier {
            keyDown.postToPid(processIdentifier)
            keyUp.postToPid(processIdentifier)
        } else {
            keyDown.post(tap: .cgSessionEventTap)
            keyUp.post(tap: .cgSessionEventTap)
        }
    }

    /// Automatic injection of polished speech directly into the user's active text field
    static func paste(
        text: String,
        target: AppTextInsertionTarget? = nil,
        targetApp: NSRunningApplication? = nil
    ) {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return }
        
        // Check user setting
        if !SaynStore.shared.autoPasteEnabled {
            let pb = NSPasteboard.general
            pb.clearContents()
            pb.setString(cleanText, forType: .string)
            print("[TextPaster] Auto-paste disabled by user setting. Text placed on clipboard.")
            return
        }

        // ─────────────────────────────────────────────────────────────────────────────
        // Tier 1: Direct in-memory Accessibility text injection (0ms, no clipboard touch)
        // ─────────────────────────────────────────────────────────────────────────────
        if let target = target {
            if target.tryDirectAXInsert(text: cleanText) {
                print("[TextPaster] Direct AX insertion succeeded into target field.")
                return
            }
        }

        // ─────────────────────────────────────────────────────────────────────────────
        // Tier 2: FreeFlow Release-Gated Hardware Keystroke with 1.0s Clipboard Restore
        // ─────────────────────────────────────────────────────────────────────────────
        let pendingRestore = writeTranscriptToPasteboard(cleanText)
        let targetPid = target?.processIdentifier ?? targetApp?.processIdentifier

        performAfterShortcutReleased {
            pasteAtCursor(processIdentifier: targetPid)
            restoreClipboardIfNeeded(pendingRestore)
        }
    }
}
