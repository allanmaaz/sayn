import Foundation
import AppKit
import ApplicationServices

struct AppContextInfo {
    let appName: String
    let bundleIdentifier: String?
    let windowTitle: String?
    let selectedText: String?
    let screenshotBase64: String?
    
    var promptHint: String {
        var lines: [String] = []
        lines.append("Destination App: \(appName)")
        if let bundle = bundleIdentifier, !bundle.isEmpty {
            lines.append("Bundle ID: \(bundle)")
        }
        if let title = windowTitle, !title.isEmpty {
            lines.append("Active Window: \"\(title)\"")
        }
        if let sel = selectedText, !sel.isEmpty {
            let truncated = sel.count > 200 ? String(sel.prefix(200)) + "..." : sel
            lines.append("Highlighted Context: \"\(truncated)\"")
        }
        
        return lines.joined(separator: "\n")
    }
}

final class AppContextService {
    static let shared = AppContextService()
    
    private init() {}
    
    /// Collects rich foreground application context: app name, bundle ID, window title, highlighted text, and window snapshot.
    func getForegroundAppContext(targetApp: NSRunningApplication? = nil) -> AppContextInfo {
        let app = targetApp ?? TextPaster.lastExternalApp ?? NSWorkspace.shared.frontmostApplication
        let appName = app?.localizedName ?? "Desktop"
        let bundleId = app?.bundleIdentifier
        
        var windowTitle: String? = nil
        var selectedText: String? = nil
        var screenshotBase64: String? = nil
        
        if let validApp = app, validApp.bundleIdentifier != Bundle.main.bundleIdentifier {
            let pid = validApp.processIdentifier
            let appRef = AXUIElementCreateApplication(pid)
            
            // 1. Extract focused window title
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
            
            // 2. Extract highlighted/selected text if any
            var focusedElement: CFTypeRef?
            if AXUIElementCopyAttributeValue(appRef, kAXFocusedUIElementAttribute as CFString, &focusedElement) == .success,
               let element = focusedElement {
                let axElement = element as! AXUIElement
                var selectedTextVal: CFTypeRef?
                if AXUIElementCopyAttributeValue(axElement, kAXSelectedTextAttribute as CFString, &selectedTextVal) == .success,
                   let str = selectedTextVal as? String {
                    let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        selectedText = trimmed
                    }
                }
            }
            
            // 3. Optional: Downscaled active window screenshot if Screen Recording is enabled
            if CGPreflightScreenCaptureAccess() {
                screenshotBase64 = captureActiveWindowScreenshot(processIdentifier: pid)
            }
        }
        
        return AppContextInfo(
            appName: appName,
            bundleIdentifier: bundleId,
            windowTitle: windowTitle,
            selectedText: selectedText,
            screenshotBase64: screenshotBase64
        )
    }
    
    // MARK: - Window Screenshot Capture (FreeFlow Algorithm)
    private func captureActiveWindowScreenshot(processIdentifier: pid_t) -> String? {
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }
        
        // Find frontmost on-screen window belonging to this PID
        guard let windowInfo = windowList.first(where: { info in
            let ownerPID = info[kCGWindowOwnerPID as String] as? pid_t ?? 0
            let isOnscreen = info[kCGWindowIsOnscreen as String] as? Bool ?? false
            let layer = info[kCGWindowLayer as String] as? Int ?? -1
            return ownerPID == processIdentifier && isOnscreen && layer == 0
        }),
        let windowIDValue = windowInfo[kCGWindowNumber as String] as? Int else {
            return nil
        }
        
        let windowID = CGWindowID(windowIDValue)
        guard let cgImage = CGWindowListCreateImage(
            .null,
            .optionIncludingWindow,
            windowID,
            [.boundsIgnoreFraming, .bestResolution]
        ) else {
            return nil
        }
        
        // Downscale to max dimension 1024px to keep size under 300KB
        let maxDim: CGFloat = 1024.0
        let origWidth = CGFloat(cgImage.width)
        let origHeight = CGFloat(cgImage.height)
        guard origWidth > 0, origHeight > 0 else { return nil }
        
        let scale = min(1.0, min(maxDim / origWidth, maxDim / origHeight))
        let targetSize = CGSize(width: origWidth * scale, height: origHeight * scale)
        
        let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(targetSize.width),
            pixelsHigh: Int(targetSize.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .calibratedRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )
        
        guard let rep = bitmapRep else { return nil }
        NSGraphicsContext.saveGraphicsState()
        let context = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current = context
        let nsImage = NSImage(cgImage: cgImage, size: targetSize)
        nsImage.draw(in: NSRect(origin: .zero, size: targetSize))
        NSGraphicsContext.restoreGraphicsState()
        
        guard let jpegData = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.5]) else {
            return nil
        }
        
        return "data:image/jpeg;base64," + jpegData.base64EncodedString()
    }
}
