import AppKit
import SwiftUI

final class ClipboardPopupWindow: NSPanel {
    
    private let viewModel = ClipboardPopupViewModel()
    private var localMonitor: Any?
    private var globalMonitor: Any?
    
    init() {
        let width = SettingsStore.shared.popupWidth
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: width, height: 340),
            styleMask: [.borderless, .nonactivatingPanel, .resizable],
            backing: .buffered,
            defer: false
        )
        
        self.isFloatingPanel = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.hidesOnDeactivate = false
        self.becomesKeyOnlyIfNeeded = true
        self.isMovableByWindowBackground = false
        self.minSize = NSSize(width: 320, height: 220)
        self.maxSize = NSSize(width: 560, height: 700)
        
        self.contentView?.layoutSubtreeIfNeeded()
        
        let rootView = ClipboardPopupView(viewModel: viewModel, onClose: { [weak self] in
            self?.hide()
        })
        
        let hosting = NSHostingView(rootView: rootView)
        hosting.frame = contentView?.bounds ?? .zero
        hosting.autoresizingMask = [.width, .height]
        
        let container = EdgeResizeContainerView(frame: contentView?.bounds ?? .zero)
        container.autoresizingMask = [.width, .height]
        container.addSubview(hosting)
        hosting.frame = container.bounds
        hosting.autoresizingMask = [.width, .height]
        contentView = container
        
        setupKeyMonitors()
    }
    
    private func setupKeyMonitors() {
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            
            if event.keyCode == 53 {
                self.hide()
                return nil
            }
            
            if self.isVisible,
               !self.viewModel.isSearchActive,
               !self.viewModel.isCalendarOpen,
               let chars = event.charactersIgnoringModifiers,
               !chars.isEmpty {
                let first = chars.unicodeScalars.first!
                let isPrintable = CharacterSet.alphanumerics.contains(first)
                    || CharacterSet.punctuationCharacters.contains(first)
                    || CharacterSet.symbols.contains(first)
                if isPrintable && !event.modifierFlags.contains(.command)
                    && !event.modifierFlags.contains(.control)
                    && !event.modifierFlags.contains(.option) {
                    self.viewModel.searchText = chars
                    self.viewModel.isSearchActive = true
                    self.viewModel.requestSearchFocus()
                    return nil
                }
            }
            
            return event
        }
        
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53, self?.isVisible == true {
                DispatchQueue.main.async { self?.hide() }
            }
        }
    }
    
    func show() {
        Task { await viewModel.refresh() }
        
        let targetFrame = calculateFrame()
        self.setFrame(targetFrame, display: true)
        
        self.alphaValue = 0
        self.orderFront(nil)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.22
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().alphaValue = 1
        }
        
        self.makeKeyAndOrderFront(nil)
    }
    
    func hide() {
        guard isVisible else { return }
        
        SettingsStore.shared.lastWindowFrame = self.frame
        viewModel.isSearchActive = false
        viewModel.searchText = ""
        viewModel.isCalendarOpen = false
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            self.animator().alphaValue = 0
        }, completionHandler: {
            self.orderOut(nil)
        })
    }
    
    private func calculateFrame() -> NSRect {
        let settings = SettingsStore.shared
        let width = max(self.frame.width, settings.popupWidth)
        let height = min(max(self.frame.height, 300), 520)
        let size = NSSize(width: width, height: height)
        
        switch settings.openPositionMode {
        case .lastPosition:
            if let saved = settings.lastWindowFrame, saved.width > 50, saved.height > 50 {
                return clampToVisible(NSRect(origin: saved.origin, size: size))
            }
            return fallbackFrame(size: size)
            
        case .screenCorner:
            return fallbackFrame(size: size)
        }
    }
    
    private func clampToVisible(_ rect: NSRect) -> NSRect {
        guard let screen = NSScreen.main else { return rect }
        let visible = screen.visibleFrame
        var r = rect
        r.origin.x = max(visible.minX + 8, min(r.origin.x, visible.maxX - r.width - 8))
        r.origin.y = max(visible.minY + 8, min(r.origin.y, visible.maxY - r.height - 8))
        return r
    }
    
    private func fallbackFrame(size: NSSize) -> NSRect {
        guard let screen = NSScreen.main else {
            return NSRect(origin: .zero, size: size)
        }
        let visible = screen.visibleFrame
        return NSRect(
            origin: CGPoint(x: visible.maxX - size.width - 16, y: visible.minY + 16),
            size: size
        )
    }
    
    override var canBecomeKey: Bool { true }
    
    deinit {
        if let monitor = localMonitor { NSEvent.removeMonitor(monitor) }
        if let monitor = globalMonitor { NSEvent.removeMonitor(monitor) }
    }
}

// MARK: - Easier edge resize for borderless panel

final class EdgeResizeContainerView: NSView {
    private let margin: CGFloat = 8
    private var tracking: NSTrackingArea?
    private var dragEdge: Edge = .none
    private var dragStartMouse: NSPoint = .zero
    private var dragStartFrame: NSRect = .zero
    
    private enum Edge {
        case none, left, right, top, bottom
        case topLeft, topRight, bottomLeft, bottomRight
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let tracking { removeTrackingArea(tracking) }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseMoved, .mouseEnteredAndExited, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        tracking = area
    }
    
    override func mouseMoved(with event: NSEvent) {
        let edge = edge(at: convert(event.locationInWindow, from: nil))
        window?.disableCursorRects()
        switch edge {
        case .left, .right:
            NSCursor.resizeLeftRight.set()
        case .top, .bottom:
            NSCursor.resizeUpDown.set()
        case .topLeft, .bottomRight:
            NSCursor.crosshair.set()
        case .topRight, .bottomLeft:
            NSCursor.crosshair.set()
        case .none:
            NSCursor.arrow.set()
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        NSCursor.arrow.set()
    }
    
    override func mouseDown(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        dragEdge = edge(at: p)
        guard dragEdge != .none, let window else {
            super.mouseDown(with: event)
            return
        }
        dragStartMouse = event.locationInWindow
        dragStartFrame = window.frame
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard dragEdge != .none, let window else {
            super.mouseDragged(with: event)
            return
        }
        
        let delta = NSPoint(
            x: event.locationInWindow.x - dragStartMouse.x,
            y: event.locationInWindow.y - dragStartMouse.y
        )
        
        var f = dragStartFrame
        let minW = window.minSize.width
        let minH = window.minSize.height
        let maxW = window.maxSize.width
        let maxH = window.maxSize.height
        
        switch dragEdge {
        case .right:
            f.size.width = min(maxW, max(minW, dragStartFrame.width + delta.x))
        case .left:
            let newW = min(maxW, max(minW, dragStartFrame.width - delta.x))
            f.origin.x = dragStartFrame.maxX - newW
            f.size.width = newW
        case .top:
            f.size.height = min(maxH, max(minH, dragStartFrame.height + delta.y))
        case .bottom:
            let newH = min(maxH, max(minH, dragStartFrame.height - delta.y))
            f.origin.y = dragStartFrame.maxY - newH
            f.size.height = newH
        case .topRight:
            f.size.width = min(maxW, max(minW, dragStartFrame.width + delta.x))
            f.size.height = min(maxH, max(minH, dragStartFrame.height + delta.y))
        case .topLeft:
            let newW = min(maxW, max(minW, dragStartFrame.width - delta.x))
            f.origin.x = dragStartFrame.maxX - newW
            f.size.width = newW
            f.size.height = min(maxH, max(minH, dragStartFrame.height + delta.y))
        case .bottomRight:
            f.size.width = min(maxW, max(minW, dragStartFrame.width + delta.x))
            let newH = min(maxH, max(minH, dragStartFrame.height - delta.y))
            f.origin.y = dragStartFrame.maxY - newH
            f.size.height = newH
        case .bottomLeft:
            let newW = min(maxW, max(minW, dragStartFrame.width - delta.x))
            f.origin.x = dragStartFrame.maxX - newW
            f.size.width = newW
            let newH = min(maxH, max(minH, dragStartFrame.height - delta.y))
            f.origin.y = dragStartFrame.maxY - newH
            f.size.height = newH
        case .none:
            break
        }
        
        window.setFrame(f, display: true)
    }
    
    override func mouseUp(with event: NSEvent) {
        dragEdge = .none
        super.mouseUp(with: event)
    }
    
    private func edge(at point: NSPoint) -> Edge {
        let b = bounds
        let onLeft = point.x <= margin
        let onRight = point.x >= b.width - margin
        let onBottom = point.y <= margin
        let onTop = point.y >= b.height - margin
        
        if onTop && onLeft { return .topLeft }
        if onTop && onRight { return .topRight }
        if onBottom && onLeft { return .bottomLeft }
        if onBottom && onRight { return .bottomRight }
        if onLeft { return .left }
        if onRight { return .right }
        if onTop { return .top }
        if onBottom { return .bottom }
        return .none
    }
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        let edge = edge(at: point)
        if edge != .none {
            return self
        }
        return super.hitTest(point)
    }
}
