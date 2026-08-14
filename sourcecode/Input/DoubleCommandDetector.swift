import Foundation
import AppKit
import ApplicationServices

@MainActor
final class DoubleCommandDetector {
    static let shared = DoubleCommandDetector()
    
    var onDoubleCommand: (() -> Void)?
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    private var lastCommandUp: Date?
    private let doublePressInterval: TimeInterval = 0.4
    
    private var commandKeyDown = false
    private var sawOtherKey = false
    
    private init() {}
    
    var isRunning: Bool { eventTap != nil }
    
    func start() {
        if eventTap != nil { return }
        
        let eventMask: CGEventMask =
            (1 << CGEventType.flagsChanged.rawValue) |
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.tapDisabledByTimeout.rawValue) |
            (1 << CGEventType.tapDisabledByUserInput.rawValue)
        
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { proxy, type, event, refcon in
                let detector = Unmanaged<DoubleCommandDetector>.fromOpaque(refcon!).takeUnretainedValue()
                return detector.handle(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("DoubleCommandDetector: Failed to create event tap. Accessibility is NOT granted for this process.")
            print("  → AXIsProcessTrusted() = \(AXIsProcessTrusted())")
            return
        }
        
        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        
        print("DoubleCommandDetector: started successfully ✅")
    }
    
    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }
    
    func restart() {
        stop()
        start()
    }
    
    private func handle(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }
        
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        
        let isCommandKey = (keyCode == 55 || keyCode == 54)
        
        if type == .flagsChanged {
            let commandNow = flags.contains(.maskCommand)
            
            if commandNow && !commandKeyDown {
                commandKeyDown = true
                sawOtherKey = false
            } else if !commandNow && commandKeyDown {
                commandKeyDown = false
                
                if !sawOtherKey {
                    let now = Date()
                    if let last = lastCommandUp,
                       now.timeIntervalSince(last) <= doublePressInterval {
                        lastCommandUp = nil
                        DispatchQueue.main.async {
                            self.onDoubleCommand?()
                        }
                    } else {
                        lastCommandUp = now
                    }
                }
            }
        } else if type == .keyDown {
            if commandKeyDown && !isCommandKey {
                sawOtherKey = true
            }
        }
        
        return Unmanaged.passUnretained(event)
    }
}
