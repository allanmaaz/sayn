import Foundation
import AppKit
import ApplicationServices

struct AppContextInfo {
    let appName: String
    let bundleIdentifier: String?
    let windowTitle: String?
    
    var promptHint: String {
        var parts: [String] = []
        if !appName.isEmpty {
            parts.append("Application: \(appName)")
        }
        if let title = windowTitle, !title.isEmpty {
            parts.append("Window: \"\(title)\"")
        }
        guard !parts.isEmpty else { return "" }
        return "Context: \(parts.joined(separator: ", ")). Use this context only to ensure correct spelling and capitalization of visible names, terms, commands, and jargon."
    }
}

final class AppContextService {
    static let shared = AppContextService()
    
    private init() {}
    
    /// Collects active foreground application name, bundle ID, and window title
    func getForegroundAppContext(targetApp: NSRunningApplication? = nil) -> AppContextInfo {
        let app = targetApp ?? TextPaster.lastExternalApp ?? NSWorkspace.shared.frontmostApplication
        let appName = app?.localizedName ?? "Desktop"
        let bundleId = app?.bundleIdentifier
        
        var windowTitle: String? = nil
        
        if let validApp = app, validApp.bundleIdentifier != Bundle.main.bundleIdentifier {
            let appRef = AXUIElementCreateApplication(validApp.processIdentifier)
            var focusedWindow: CFTypeRef?
            if AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute as CFString, &focusedWindow) == .success,
               let win = focusedWindow {
                let axWindow = win as! AXUIElement
                var titleVal: CFTypeRef?
                if AXUIElementCopyAttributeValue(axWindow, kAXTitleAttribute as CFString, &titleVal) == .success,
                   let t = titleVal as? String {
                    let trimmed = t.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        windowTitle = trimmed
                    }
                }
            }
        }
        
        return AppContextInfo(appName: appName, bundleIdentifier: bundleId, windowTitle: windowTitle)
    }
}
