import AppKit
import ApplicationServices

/// Defines a snap zone at a screen edge or corner
struct SnapZone {
    let position: WindowPosition
    let triggerRect: CGRect // Screen-relative rect that triggers this zone
    let name: String

    init(_ position: WindowPosition, trigger: CGRect, name: String) {
        self.position = position
        self.triggerRect = trigger
        self.name = name
    }
}

/// Controller for drag-to-snap functionality
/// Monitors mouse events and shows preview overlays when dragging windows to screen edges
class DragSnapController {
    static let shared = DragSnapController()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isDragging = false
    private var previewWindow: NSWindow?
    private var currentZone: SnapZone?
    private var draggedWindowPID: pid_t?
    private weak var windowManager: WindowManager?

    // Trigger zones (in pixels from screen edge)
    private let edgeThreshold: CGFloat = 15
    private let cornerThreshold: CGFloat = 50

    // Enabled state (using UserDefaults directly since we're not in SwiftUI)
    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "dragToSnapEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "dragToSnapEnabled") }
    }

    private init() {
        // Set default value if not set
        if UserDefaults.standard.object(forKey: "dragToSnapEnabled") == nil {
            UserDefaults.standard.set(true, forKey: "dragToSnapEnabled")
        }
    }

    func setWindowManager(_ manager: WindowManager) {
        self.windowManager = manager
    }

    // MARK: - Start/Stop Monitoring

    func start() {
        guard isEnabled, eventTap == nil else { return }

        // Request accessibility permission if needed
        guard AXIsProcessTrusted() else {
            print("DragSnapController: Accessibility permission required")
            return
        }

        // Create event tap for mouse events
        let eventMask: CGEventMask = (1 << CGEventType.leftMouseDown.rawValue) |
                                      (1 << CGEventType.leftMouseUp.rawValue) |
                                      (1 << CGEventType.leftMouseDragged.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                let controller = Unmanaged<DragSnapController>.fromOpaque(refcon).takeUnretainedValue()
                return controller.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("DragSnapController: Failed to create event tap")
            return
        }

        eventTap = tap

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        print("DragSnapController: Started monitoring")
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            }
            eventTap = nil
            runLoopSource = nil
        }

        hidePreview()
        isDragging = false

        print("DragSnapController: Stopped monitoring")
    }

    // MARK: - Event Handling

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        guard isEnabled else { return Unmanaged.passUnretained(event) }

        switch type {
        case .leftMouseDown:
            // Check if clicking on a window title bar (potential drag start)
            let mouseLocation = event.location
            checkForDragStart(at: mouseLocation)

        case .leftMouseDragged:
            if isDragging {
                let mouseLocation = event.location
                updateDragPosition(at: mouseLocation)
            }

        case .leftMouseUp:
            if isDragging {
                finishDrag()
            }

        case .tapDisabledByTimeout:
            // Re-enable the tap if it gets disabled
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }

        default:
            break
        }

        return Unmanaged.passUnretained(event)
    }

    // MARK: - Drag Detection

    private func checkForDragStart(at point: CGPoint) {
        // Get the frontmost app
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return }

        // Check if we're clicking on a window's title bar
        let appRef = AXUIElementCreateApplication(frontApp.processIdentifier)

        var focusedWindow: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute as CFString, &focusedWindow) == .success else {
            return
        }

        let window = focusedWindow as! AXUIElement

        // Get window position and check if click is in title bar area
        var positionValue: CFTypeRef?
        var sizeValue: CFTypeRef?

        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue) == .success,
              AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue) == .success else {
            return
        }

        var position = CGPoint.zero
        var size = CGSize.zero

        AXValueGetValue(positionValue as! AXValue, .cgPoint, &position)
        AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)

        // Title bar is typically the top ~30 pixels of a window
        let titleBarHeight: CGFloat = 30
        let titleBarRect = CGRect(x: position.x, y: position.y, width: size.width, height: titleBarHeight)

        if titleBarRect.contains(point) {
            isDragging = true
            draggedWindowPID = frontApp.processIdentifier
        }
    }

    private func updateDragPosition(at point: CGPoint) {
        // Find which screen the mouse is on
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(point) }) else {
            hidePreview()
            currentZone = nil
            return
        }

        // Check which zone (if any) the mouse is in
        let zone = findZone(for: point, on: screen)

        if let zone = zone {
            if currentZone?.name != zone.name {
                currentZone = zone
                showPreview(for: zone, on: screen)
            }
        } else {
            hidePreview()
            currentZone = nil
        }
    }

    private func finishDrag() {
        isDragging = false

        if let zone = currentZone, let pid = draggedWindowPID {
            // Snap the window to the zone
            DispatchQueue.main.async { [weak self] in
                self?.snapWindow(pid: pid, to: zone)
            }
        }

        hidePreview()
        currentZone = nil
        draggedWindowPID = nil
    }

    // MARK: - Zone Detection

    private func findZone(for point: CGPoint, on screen: NSScreen) -> SnapZone? {
        let frame = screen.frame
        let visibleFrame = screen.visibleFrame

        // Convert to screen-local coordinates
        let localX = point.x - frame.origin.x
        let localY = point.y - frame.origin.y

        // Check corners first (they take priority over edges)
        // Top-left corner
        if localX < cornerThreshold && localY < cornerThreshold {
            return SnapZone(
                WindowPosition(0, 0, 0.5, 0.5),
                trigger: CGRect(x: 0, y: 0, width: cornerThreshold, height: cornerThreshold),
                name: "Top-Left"
            )
        }

        // Top-right corner
        if localX > frame.width - cornerThreshold && localY < cornerThreshold {
            return SnapZone(
                WindowPosition(0.5, 0, 0.5, 0.5),
                trigger: CGRect(x: frame.width - cornerThreshold, y: 0, width: cornerThreshold, height: cornerThreshold),
                name: "Top-Right"
            )
        }

        // Bottom-left corner
        if localX < cornerThreshold && localY > frame.height - cornerThreshold {
            return SnapZone(
                WindowPosition(0, 0.5, 0.5, 0.5),
                trigger: CGRect(x: 0, y: frame.height - cornerThreshold, width: cornerThreshold, height: cornerThreshold),
                name: "Bottom-Left"
            )
        }

        // Bottom-right corner
        if localX > frame.width - cornerThreshold && localY > frame.height - cornerThreshold {
            return SnapZone(
                WindowPosition(0.5, 0.5, 0.5, 0.5),
                trigger: CGRect(x: frame.width - cornerThreshold, y: frame.height - cornerThreshold, width: cornerThreshold, height: cornerThreshold),
                name: "Bottom-Right"
            )
        }

        // Check edges
        // Left edge
        if localX < edgeThreshold {
            return SnapZone(
                WindowPosition(0, 0, 0.5, 1),
                trigger: CGRect(x: 0, y: 0, width: edgeThreshold, height: frame.height),
                name: "Left Half"
            )
        }

        // Right edge
        if localX > frame.width - edgeThreshold {
            return SnapZone(
                WindowPosition(0.5, 0, 0.5, 1),
                trigger: CGRect(x: frame.width - edgeThreshold, y: 0, width: edgeThreshold, height: frame.height),
                name: "Right Half"
            )
        }

        // Top edge (maximize)
        if localY < edgeThreshold {
            return SnapZone(
                WindowPosition(0, 0, 1, 1),
                trigger: CGRect(x: 0, y: 0, width: frame.width, height: edgeThreshold),
                name: "Maximize"
            )
        }

        return nil
    }

    // MARK: - Preview Window

    private func showPreview(for zone: SnapZone, on screen: NSScreen) {
        hidePreview()

        let frame = screen.visibleFrame
        let position = zone.position

        // Calculate preview frame
        let previewFrame = CGRect(
            x: frame.origin.x + frame.width * position.x,
            y: frame.origin.y + frame.height * (1 - position.y - position.height),
            width: frame.width * position.width,
            height: frame.height * position.height
        )

        // Create preview window
        let window = NSWindow(
            contentRect: previewFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Create preview view
        let contentView = NSView(frame: window.contentView!.bounds)
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.3).cgColor
        contentView.layer?.borderColor = NSColor.systemBlue.cgColor
        contentView.layer?.borderWidth = 3
        contentView.layer?.cornerRadius = 8

        // Add zone label
        let label = NSTextField(labelWithString: zone.name)
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .white
        label.alignment = .center
        label.sizeToFit()
        label.frame = CGRect(
            x: (contentView.bounds.width - label.bounds.width) / 2,
            y: (contentView.bounds.height - label.bounds.height) / 2,
            width: label.bounds.width,
            height: label.bounds.height
        )
        contentView.addSubview(label)

        window.contentView = contentView
        window.orderFront(nil)

        previewWindow = window

        // Animate in
        window.alphaValue = 0
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            window.animator().alphaValue = 1
        }
    }

    private func hidePreview() {
        guard let window = previewWindow else { return }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.1
            window.animator().alphaValue = 0
        }, completionHandler: {
            window.close()
        })

        previewWindow = nil
    }

    // MARK: - Window Snapping

    private func snapWindow(pid: pid_t, to zone: SnapZone) {
        let appRef = AXUIElementCreateApplication(pid)

        var focusedWindow: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute as CFString, &focusedWindow) == .success else {
            return
        }

        let window = focusedWindow as! AXUIElement

        // Get the screen where the window should be placed
        guard let screen = NSScreen.screens.first(where: { screen in
            // Find screen based on current mouse position
            let mouseLocation = NSEvent.mouseLocation
            return screen.frame.contains(mouseLocation)
        }) ?? NSScreen.main else { return }

        // Use WindowManager to move the window
        windowManager?.moveWindowToPosition(window, position: zone.position, screen: screen)
        windowManager?.alertWindow?.showAlert(zone.name)
    }
}

