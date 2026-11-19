import AppKit
import ApplicationServices
import Foundation

/// Encapsulates the exact text field or editor active at the moment dictation was triggered.
struct AppTextInsertionTarget {
    let element: AXUIElement
    let window: AXUIElement?
    let valueAtCapture: String?
    let selectedTextRange: NSRange?
    let processIdentifier: pid_t
    let isSupportedTextControl: Bool
    let isWebContent: Bool

    /// Captures the focused text element from the active application.
    /// Excludes known secure password controls to protect sensitive credentials.
    static func capture(from app: NSRunningApplication?) -> AppTextInsertionTarget? {
        guard let app = app, app.bundleIdentifier != Bundle.main.bundleIdentifier else { return nil }
        let pid = app.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)
        
        guard let focused = accessibilityElement(from: appElement, attribute: kAXFocusedUIElementAttribute as CFString) else {
            return nil
        }
        
        // Exclude secure password text fields
        if let subrole = accessibilityString(from: focused, attribute: kAXSubroleAttribute as CFString),
           subrole == (kAXSecureTextFieldSubrole as String) {
            return nil
        }
        
        let role = accessibilityString(from: focused, attribute: kAXRoleAttribute as CFString)
        let subrole = accessibilityString(from: focused, attribute: kAXSubroleAttribute as CFString)
        
        let supportedRoles = ["AXTextField", "AXTextArea", "AXComboBox", "AXWebArea", "AXSearchField"]
        let isSupported = supportedRoles.contains(role ?? "")
        let isWeb = (role == "AXWebArea") || (subrole == "AXUnknown" && (role == "AXTextArea" || role == "AXTextField"))
        
        let windowElement = accessibilityElement(from: appElement, attribute: kAXFocusedWindowAttribute as CFString)
        let textValue = accessibilityString(from: focused, attribute: kAXValueAttribute as CFString)
        let selectionRange = accessibilityRange(from: focused, attribute: kAXSelectedTextRangeAttribute as CFString)
        
        return AppTextInsertionTarget(
            element: focused,
            window: windowElement,
            valueAtCapture: textValue,
            selectedTextRange: selectionRange,
            processIdentifier: pid,
            isSupportedTextControl: isSupported,
            isWebContent: isWeb
        )
    }

    /// Attempts direct in-memory insertion at the cursor via Accessibility API without modifying clipboard.
    func tryDirectAXInsert(text: String) -> Bool {
        var isSettable: DarwinBoolean = false
        let settableResult = AXUIElementIsAttributeSettable(element, kAXSelectedTextAttribute as CFString, &isSettable)
        
        guard settableResult == .success && isSettable.boolValue else {
            return false
        }
        
        let setResult = AXUIElementSetAttributeValue(element, kAXSelectedTextAttribute as CFString, text as CFTypeRef)
        guard setResult == .success else { return false }
        
        // Readback verification: strictly verify that the element accepted the write
        if let currentValue = Self.accessibilityString(from: element, attribute: kAXValueAttribute as CFString) {
            if currentValue.contains(text) || (valueAtCapture != nil && currentValue != valueAtCapture) {
                print("[AppTextInsertionTarget] Direct AX insertion verified in buffer.")
                return true
            }
        }
        
        // If the write could not be confirmed in the buffer, return false so Cmd-V paste handles it
        return false
    }

    // MARK: - Accessibility Helpers
    private static func accessibilityElement(from element: AXUIElement, attribute: CFString) -> AXUIElement? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute, &value)
        guard result == .success,
              let rawValue = value,
              CFGetTypeID(rawValue) == AXUIElementGetTypeID() else {
            return nil
        }
        return unsafeBitCast(rawValue, to: AXUIElement.self)
    }

    private static func accessibilityString(from element: AXUIElement, attribute: CFString) -> String? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute, &value)
        guard result == .success, let str = value as? String else { return nil }
        return str
    }

    private static func accessibilityRange(from element: AXUIElement, attribute: CFString) -> NSRange? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute, &value)
        guard result == .success,
              let rawValue = value,
              CFGetTypeID(rawValue) == AXValueGetTypeID() else {
            return nil
        }
        let axValue = unsafeBitCast(rawValue, to: AXValue.self)
        var cfRange = CFRange(location: 0, length: 0)
        guard AXValueGetValue(axValue, .cfRange, &cfRange) else { return nil }
        return NSRange(location: cfRange.location, length: cfRange.length)
    }
}
