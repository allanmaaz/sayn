import AppKit
import Carbon

final class TextPaster {
    static func paste(text: String) {
        guard !text.isEmpty else { return }
        
        // 1. Copy text to system clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // 2. Small delay to ensure clipboard buffer is populated
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            // 3. Post simulated Cmd+V keystroke via Quartz Event Services
            let src = CGEventSource(stateID: .combinedSessionState)
            
            // Keycode 9 is 'V' on standard US keyboard
            let vKeyDown = CGEvent(keyboardEventSource: src, virtualKey: 9, keyDown: true)
            vKeyDown?.flags = .maskCommand
            
            let vKeyUp = CGEvent(keyboardEventSource: src, virtualKey: 9, keyDown: false)
            vKeyUp?.flags = .maskCommand
            
            vKeyDown?.post(tap: .cghidEventTap)
            vKeyUp?.post(tap: .cghidEventTap)
        }
    }
}
