import Foundation
import AppKit
import ApplicationServices

struct TextFieldInfo {
    let frame: CGRect
    let isValid: Bool
}

enum AccessibilityHelper {
    
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }
    
    static func requestTrust() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
    
    /// Look for the focused text field using every available strategy
    static func focusedTextFieldFrame() -> TextFieldInfo {
        guard isTrusted else {
            return TextFieldInfo(frame: .zero, isValid: false)
        }
        
        if let frame = frameFromFocusedElement() {
            return TextFieldInfo(frame: frame, isValid: true)
        }
        
        if let frame = frameFromFocusedTree() {
            return TextFieldInfo(frame: frame, isValid: true)
        }
        
        if let frame = frameFromFrontmostApp() {
            return TextFieldInfo(frame: frame, isValid: true)
        }
        
        return TextFieldInfo(frame: .zero, isValid: false)
    }
    
    // MARK: - Strategy 1
    
    private static func frameFromFocusedElement() -> CGRect? {
        let systemWide = AXUIElementCreateSystemWide()
        var focusedRef: CFTypeRef?
        
        guard AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focusedRef
        ) == .success,
        let focused = focusedRef else { return nil }
        
        let element = focused as! AXUIElement
        
        if isTextLike(element), let frame = getFrame(element) {
            return frame
        }
        
        return nil
    }
    
    // MARK: - Strategy 2
    
    private static func frameFromFocusedTree() -> CGRect? {
        let systemWide = AXUIElementCreateSystemWide()
        var focusedRef: CFTypeRef?
        
        guard AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focusedRef
        ) == .success,
        let focused = focusedRef else { return nil }
        
        let element = focused as! AXUIElement
        
        if isTextLike(element), let frame = getFrame(element) {
            return frame
        }
        
        var current: AXUIElement? = element
        for _ in 0..<6 {
            guard let el = current else { break }
            var parentRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(el, kAXParentAttribute as CFString, &parentRef) == .success,
               let parent = parentRef {
                let parentEl = parent as! AXUIElement
                if isTextLike(parentEl), let frame = getFrame(parentEl) {
                    return frame
                }
                current = parentEl
            } else {
                break
            }
        }
        
        if let frame = findTextFieldInChildren(element, depth: 2) {
            return frame
        }
        
        return nil
    }
    
    // MARK: - Strategy 3
    
    private static func frameFromFrontmostApp() -> CGRect? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        let pid = app.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)
        
        var focusedRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedRef
        ) == .success,
        let focused = focusedRef {
            let el = focused as! AXUIElement
            if isTextLike(el), let frame = getFrame(el) {
                return frame
            }
            if let frame = findTextFieldInChildren(el, depth: 3) {
                return frame
            }
        }
        
        var windowRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedWindowAttribute as CFString,
            &windowRef
        ) == .success,
        let window = windowRef {
            let win = window as! AXUIElement
            if let frame = findTextFieldInChildren(win, depth: 4) {
                return frame
            }
        }
        
        return nil
    }
    
    // MARK: - Helpers
    
    private static let textRoles: Set<String> = [
        kAXTextFieldRole as String,
        kAXTextAreaRole as String,
        kAXComboBoxRole as String,
        "AXSearchField",
        "AXURLField",
        "AXTextField",
        "AXTextArea",
        "AXComboBox",
        "AXEditableText",
        "AXWebArea",
    ]
    
    private static func isTextLike(_ element: AXUIElement) -> Bool {
        var roleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef)
        let role = roleRef as? String ?? ""
        
        if textRoles.contains(role) {
            if role == "AXWebArea" {
                return isEditable(element)
            }
            return true
        }
        
        var subroleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXSubroleAttribute as CFString, &subroleRef)
        let subrole = subroleRef as? String ?? ""
        if subrole.contains("Search") || subrole.contains("Text") || subrole.contains("URL") {
            return true
        }
        
        if isEditable(element) {
            return true
        }
        
        return false
    }
    
    private static func isEditable(_ element: AXUIElement) -> Bool {
        var editableRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(
            element,
            "AXEditable" as CFString,
            &editableRef
        ) == .success,
        let editable = editableRef as? Bool {
            return editable
        }
        
        var rangeRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextRangeAttribute as CFString,
            &rangeRef
        ) == .success, rangeRef != nil {
            return true
        }
        
        var numRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(
            element,
            kAXNumberOfCharactersAttribute as CFString,
            &numRef
        ) == .success, numRef != nil {
            return true
        }
        
        return false
    }
    
    private static func getFrame(_ element: AXUIElement) -> CGRect? {
        var posRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        
        let posOk = AXUIElementCopyAttributeValue(
            element, kAXPositionAttribute as CFString, &posRef
        ) == .success
        let sizeOk = AXUIElementCopyAttributeValue(
            element, kAXSizeAttribute as CFString, &sizeRef
        ) == .success
        
        guard posOk, sizeOk, let pos = posRef, let sz = sizeRef else { return nil }
        
        var position = CGPoint.zero
        var size = CGSize.zero
        
        let posValue = pos as! AXValue
        let sizeValue = sz as! AXValue
        
        guard AXValueGetValue(posValue, .cgPoint, &position),
              AXValueGetValue(sizeValue, .cgSize, &size) else {
            return nil
        }
        
        guard size.width >= 8, size.height >= 8 else { return nil }
        guard position.x > -10000, position.y > -10000 else { return nil }
        
        return CGRect(origin: position, size: size)
    }
    
    private static func findTextFieldInChildren(_ element: AXUIElement, depth: Int) -> CGRect? {
        guard depth > 0 else { return nil }
        
        var childrenRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            element,
            kAXChildrenAttribute as CFString,
            &childrenRef
        ) == .success,
        let children = childrenRef as? [AXUIElement] else {
            return nil
        }
        
        for child in children {
            var focusedRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(
                child,
                kAXFocusedAttribute as CFString,
                &focusedRef
            ) == .success,
            let focused = focusedRef as? Bool, focused {
                if isTextLike(child), let frame = getFrame(child) {
                    return frame
                }
            }
        }
        
        for child in children {
            if isTextLike(child), isEditable(child), let frame = getFrame(child) {
                return frame
            }
        }
        
        for child in children {
            if let frame = findTextFieldInChildren(child, depth: depth - 1) {
                return frame
            }
        }
        
        return nil
    }
    
    /// AX (top-left global) → AppKit (bottom-left)
    static func convertToAppKitCoordinates(_ axFrame: CGRect) -> CGRect {
        let primaryHeight = NSScreen.screens.first(where: { $0.frame.origin == .zero })?.frame.height
            ?? NSScreen.main?.frame.height
            ?? 900
        
        let flippedY = primaryHeight - axFrame.origin.y - axFrame.height
        
        return CGRect(
            x: axFrame.origin.x,
            y: flippedY,
            width: axFrame.width,
            height: axFrame.height
        )
    }
}
