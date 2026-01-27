import AppKit
import ApplicationServices

/// Position definition for window placement
struct WindowPosition {
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat

    init(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) {
        self.x = x
        self.y = y
        self.width = w
        self.height = h
    }
}

/// Represents a window's previous position for undo
struct WindowHistory {
    let windowRef: AXUIElement
    let pid: pid_t
    let frame: CGRect
}

/// Manages window positioning and multi-monitor cycling
class WindowManager {
    weak var alertWindow: AlertWindow?

    private func debugLog(_ message: String) {
        let logPath = NSHomeDirectory() + "/Desktop/snapnuts-debug.log"
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logMessage = "[\(timestamp)] [WM] \(message)\n"
        if let handle = FileHandle(forWritingAtPath: logPath) {
            handle.seekToEndOfFile()
            handle.write(logMessage.data(using: .utf8)!)
            handle.closeFile()
        } else {
            FileManager.default.createFile(atPath: logPath, contents: logMessage.data(using: .utf8))
        }
    }

    // Position tracking for cycling (per-key)
    private var currentPositionIndex: [String: Int] = [:]
    private var currentScreenIndex: [String: Int] = [:]

    // Undo history (max 10 entries)
    private var undoHistory: [WindowHistory] = []
    private let maxUndoHistory = 10

    // Window gaps (in pixels)
    var windowGap: CGFloat {
        CGFloat(UserDefaults.standard.integer(forKey: "windowGap"))
    }

    // Position definitions (ported from Lua)
    let maximizePositions = [
        WindowPosition(0, 0, 1, 1)
    ]

    let halfPositions = [
        WindowPosition(0, 0, 0.5, 1),      // Left half
        WindowPosition(0.5, 0, 0.5, 1)     // Right half
    ]

    let thirdPositions = [
        WindowPosition(0, 0, 1.0/3.0, 1),        // Left third
        WindowPosition(1.0/3.0, 0, 1.0/3.0, 1),  // Center third
        WindowPosition(2.0/3.0, 0, 1.0/3.0, 1)   // Right third
    ]

    let fourthPositions = [
        // Horizontal fourths (positions 1-4)
        WindowPosition(0, 0, 0.25, 1),       // Left fourth
        WindowPosition(0.25, 0, 0.25, 1),    // Center-left fourth
        WindowPosition(0.5, 0, 0.25, 1),     // Center-right fourth
        WindowPosition(0.75, 0, 0.25, 1),    // Right fourth
        // 2x2 corner quarters (positions 5-8)
        WindowPosition(0, 0, 0.5, 0.5),      // Top-left
        WindowPosition(0.5, 0, 0.5, 0.5),    // Top-right
        WindowPosition(0, 0.5, 0.5, 0.5),    // Bottom-left
        WindowPosition(0.5, 0.5, 0.5, 0.5)   // Bottom-right
    ]

    let centerPositions = [
        WindowPosition(0.1, 0.1, 0.8, 0.8)   // 80% centered
    ]

    let sixthPositions = [
        // Row 1 (top)
        WindowPosition(0, 0, 1.0/3.0, 0.5),        // Top-left
        WindowPosition(1.0/3.0, 0, 1.0/3.0, 0.5),  // Top-center
        WindowPosition(2.0/3.0, 0, 1.0/3.0, 0.5),  // Top-right
        // Row 2 (bottom)
        WindowPosition(0, 0.5, 1.0/3.0, 0.5),      // Bottom-left
        WindowPosition(1.0/3.0, 0.5, 1.0/3.0, 0.5),// Bottom-center
        WindowPosition(2.0/3.0, 0.5, 1.0/3.0, 0.5) // Bottom-right
    ]

    let almostMaxPositions = [
        WindowPosition(0.05, 0.05, 0.9, 0.9)   // 90% centered
    ]

    let eighthPositions = [
        // Row 1 (top)
        WindowPosition(0, 0, 0.25, 0.5),       // Top-left
        WindowPosition(0.25, 0, 0.25, 0.5),    // Top-center-left
        WindowPosition(0.5, 0, 0.25, 0.5),     // Top-center-right
        WindowPosition(0.75, 0, 0.25, 0.5),    // Top-right
        // Row 2 (bottom)
        WindowPosition(0, 0.5, 0.25, 0.5),     // Bottom-left
        WindowPosition(0.25, 0.5, 0.25, 0.5),  // Bottom-center-left
        WindowPosition(0.5, 0.5, 0.25, 0.5),   // Bottom-center-right
        WindowPosition(0.75, 0.5, 0.25, 0.5)   // Bottom-right
    ]

    let ninthPositions = [
        // Row 1 (top)
        WindowPosition(0, 0, 1.0/3.0, 1.0/3.0),          // Top-left
        WindowPosition(1.0/3.0, 0, 1.0/3.0, 1.0/3.0),    // Top-center
        WindowPosition(2.0/3.0, 0, 1.0/3.0, 1.0/3.0),    // Top-right
        // Row 2 (middle)
        WindowPosition(0, 1.0/3.0, 1.0/3.0, 1.0/3.0),          // Middle-left
        WindowPosition(1.0/3.0, 1.0/3.0, 1.0/3.0, 1.0/3.0),    // Middle-center
        WindowPosition(2.0/3.0, 1.0/3.0, 1.0/3.0, 1.0/3.0),    // Middle-right
        // Row 3 (bottom)
        WindowPosition(0, 2.0/3.0, 1.0/3.0, 1.0/3.0),          // Bottom-left
        WindowPosition(1.0/3.0, 2.0/3.0, 1.0/3.0, 1.0/3.0),    // Bottom-center
        WindowPosition(2.0/3.0, 2.0/3.0, 1.0/3.0, 1.0/3.0)     // Bottom-right
    ]

    let sixteenthPositions: [WindowPosition] = {
        var positions: [WindowPosition] = []
        for row in 0..<4 {
            for col in 0..<4 {
                positions.append(WindowPosition(
                    CGFloat(col) * 0.25,
                    CGFloat(row) * 0.25,
                    0.25,
                    0.25
                ))
            }
        }
        return positions
    }()

    // MARK: - Screen Management

    /// Get all screens sorted left-to-right
    func getSortedScreens() -> [NSScreen] {
        NSScreen.screens.sorted { $0.frame.origin.x < $1.frame.origin.x }
    }

    /// Find which screen a window is currently on
    func screenForWindow(_ window: AXUIElement) -> NSScreen {
        guard let position = getWindowPosition(window),
              let size = getWindowSize(window) else {
            return NSScreen.main ?? NSScreen.screens[0]
        }

        // Window center in Accessibility coordinates
        let centerX = position.x + size.width / 2
        let centerY = position.y + size.height / 2

        // Check each screen - need to convert AX coords to screen coords
        // In AX: Y=0 is top of primary screen, increases downward
        // In Cocoa: Y=0 is bottom of primary screen, increases upward
        let primaryHeight = NSScreen.screens[0].frame.height
        let cocoaCenterY = primaryHeight - centerY
        let centerPoint = CGPoint(x: centerX, y: cocoaCenterY)

        // Use getSortedScreens() for consistency with positioning logic
        let sortedScreens = getSortedScreens()

        // First try to find exact match
        for screen in sortedScreens {
            if screen.frame.contains(centerPoint) {
                return screen
            }
        }

        // If no exact match, find the nearest screen by distance to center
        var nearestScreen = sortedScreens[0]
        var nearestDistance = CGFloat.greatestFiniteMagnitude

        for screen in sortedScreens {
            let screenCenterX = screen.frame.midX
            let screenCenterY = screen.frame.midY
            let distance = hypot(centerPoint.x - screenCenterX, centerPoint.y - screenCenterY)
            if distance < nearestDistance {
                nearestDistance = distance
                nearestScreen = screen
            }
        }

        return nearestScreen
    }

    /// Find the index of the screen a window is on
    func screenIndexForWindow(_ window: AXUIElement) -> Int {
        let screen = screenForWindow(window)
        let screens = getSortedScreens()
        return screens.firstIndex(of: screen) ?? 0
    }

    // MARK: - Window Access

    /// Get the frontmost window of the frontmost application
    func getFocusedWindow() -> AXUIElement? {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            return nil
        }

        let appElement = AXUIElementCreateApplication(frontmostApp.processIdentifier)
        var focusedWindow: CFTypeRef?

        let result = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindow)

        if result == .success, let window = focusedWindow {
            return (window as! AXUIElement)
        }
        return nil
    }

    /// Get window position
    func getWindowPosition(_ window: AXUIElement) -> CGPoint? {
        var positionRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionRef)

        if result == .success, let positionValue = positionRef {
            var position = CGPoint.zero
            AXValueGetValue(positionValue as! AXValue, .cgPoint, &position)
            return position
        }
        return nil
    }

    /// Get window size
    func getWindowSize(_ window: AXUIElement) -> CGSize? {
        var sizeRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef)

        if result == .success, let sizeValue = sizeRef {
            var size = CGSize.zero
            AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
            return size
        }
        return nil
    }

    /// Set window position
    func setWindowPosition(_ window: AXUIElement, position: CGPoint) {
        var pos = position
        if let positionValue = AXValueCreate(.cgPoint, &pos) {
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
        }
    }

    /// Set window size
    func setWindowSize(_ window: AXUIElement, size: CGSize) {
        var sz = size
        if let sizeValue = AXValueCreate(.cgSize, &sz) {
            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        }
    }

    // MARK: - Undo Support

    /// Saves the current window position to undo history
    private func saveToUndoHistory(_ window: AXUIElement) {
        // Get current position and size
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

        // Get PID for the window's app
        var pid: pid_t = 0
        AXUIElementGetPid(window, &pid)

        let history = WindowHistory(
            windowRef: window,
            pid: pid,
            frame: CGRect(origin: position, size: size)
        )

        // Add to history, limiting size
        undoHistory.append(history)
        if undoHistory.count > maxUndoHistory {
            undoHistory.removeFirst()
        }
    }

    /// Undoes the last snap operation
    func undoLastSnap() {
        guard let lastHistory = undoHistory.popLast() else {
            alertWindow?.showAlert("Nothing to undo")
            return
        }

        // Restore the previous position
        var position = lastHistory.frame.origin
        let positionValue = AXValueCreate(.cgPoint, &position)!
        AXUIElementSetAttributeValue(lastHistory.windowRef, kAXPositionAttribute as CFString, positionValue)

        Thread.sleep(forTimeInterval: 0.05)

        var size = lastHistory.frame.size
        let sizeValue = AXValueCreate(.cgSize, &size)!
        AXUIElementSetAttributeValue(lastHistory.windowRef, kAXSizeAttribute as CFString, sizeValue)

        alertWindow?.showAlert("Undone!")
    }

    /// Move window to a position on a specific screen
    func moveWindowToPosition(_ window: AXUIElement, position: WindowPosition, screen: NSScreen) {
        // Save current position for undo
        saveToUndoHistory(window)

        let frame = screen.visibleFrame
        let primaryHeight = NSScreen.screens[0].frame.height
        let gap = windowGap

        debugLog("moveWindowToPosition called:")
        debugLog("  position: x=\(position.x), y=\(position.y), w=\(position.width), h=\(position.height)")
        debugLog("  screen.visibleFrame: \(frame)")
        debugLog("  primaryHeight: \(primaryHeight)")

        // Calculate pixel boundaries using consistent rounding to eliminate gaps
        let startX = round(frame.width * position.x)
        let endX = round(frame.width * (position.x + position.width))
        let startY = round(frame.height * position.y)
        let endY = round(frame.height * (position.y + position.height))

        var newWidth = endX - startX
        var newHeight = endY - startY

        // X coordinate: offset from left edge of visible frame
        var newX = frame.origin.x + startX

        // Y coordinate conversion:
        // 1. Calculate where the window TOP should be in Cocoa coords
        //    - Top of visible frame in Cocoa = frame.origin.y + frame.height
        //    - Window top in Cocoa = top of frame - startY (going down from top)
        var windowTopInCocoa = frame.origin.y + frame.height - startY

        // Apply gaps if enabled
        if gap > 0 {
            // Add gap to position
            newX += gap
            windowTopInCocoa -= gap

            // Reduce size to account for gaps
            newWidth -= gap * 2
            newHeight -= gap * 2

            // Ensure minimum size
            newWidth = max(newWidth, 100)
            newHeight = max(newHeight, 100)
        }

        // 2. Convert Cocoa Y to Accessibility Y
        //    - AX Y = primaryHeight - Cocoa Y
        let newY = primaryHeight - windowTopInCocoa

        debugLog("  Final: x=\(newX), y=\(newY), w=\(newWidth), h=\(newHeight)")

        // Step 1: Move window to target screen first
        setWindowPosition(window, position: CGPoint(x: newX, y: newY))

        // Step 2: Small delay to let macOS register the screen change
        // This is critical for cross-monitor moves
        Thread.sleep(forTimeInterval: 0.05)

        // Step 3: Now resize - macOS now knows the window is on the target screen
        setWindowSize(window, size: CGSize(width: newWidth, height: newHeight))

        // Step 4: Set position again to ensure it's exact after resize
        setWindowPosition(window, position: CGPoint(x: newX, y: newY))
    }

    // MARK: - Position Cycling

    /// Cycle to next position on CURRENT screen (no automatic monitor jumping)
    func cyclePosition(key: String, positions: [WindowPosition], labels: [String]? = nil) {
        guard let window = getFocusedWindow() else {
            alertWindow?.showAlert("No focused window!")
            return
        }

        let screens = getSortedScreens()
        let numScreens = screens.count

        // Always detect which screen the window is currently on
        let currentScreenIdx = screenIndexForWindow(window)
        let targetScreen = screens[currentScreenIdx]

        // Get current position index for this key on this screen
        let stateKey = "\(key)_screen\(currentScreenIdx)"
        var index = currentPositionIndex[stateKey] ?? 0

        // Cycle to next position
        index += 1
        if index > positions.count {
            index = 1  // Wrap back to first position (stay on same screen)
        }
        currentPositionIndex[stateKey] = index

        let pos = positions[index - 1]
        moveWindowToPosition(window, position: pos, screen: targetScreen)

        // Show feedback
        let label: String
        if let labels = labels, index <= labels.count {
            label = labels[index - 1]
        } else {
            label = "\(index)/\(positions.count)"
        }

        let screenInfo = numScreens > 1 ? " [Screen \(currentScreenIdx + 1)/\(numScreens)]" : ""
        alertWindow?.showAlert("\(label)\(screenInfo)")
    }

    // MARK: - Shortcut Actions

    func maximize() {
        cyclePosition(key: "maximize", positions: maximizePositions, labels: ["Maximize"])
    }

    func halves() {
        cyclePosition(key: "halves", positions: halfPositions, labels: ["Left", "Right"])
    }

    func thirds() {
        cyclePosition(key: "thirds", positions: thirdPositions, labels: ["Left", "Center", "Right"])
    }

    func fourths() {
        cyclePosition(key: "fourths", positions: fourthPositions, labels: [
            "Fourth 1/4", "Fourth 2/4", "Fourth 3/4", "Fourth 4/4",
            "Corner TL", "Corner TR", "Corner BL", "Corner BR"
        ])
    }

    func center() {
        cyclePosition(key: "center", positions: centerPositions, labels: ["Center"])
    }

    func sixths() {
        cyclePosition(key: "sixths", positions: sixthPositions)
    }

    func almostMax() {
        cyclePosition(key: "almostMax", positions: almostMaxPositions, labels: ["Almost Max"])
    }

    func eighths() {
        cyclePosition(key: "eighths", positions: eighthPositions)
    }

    func ninths() {
        guard let window = getFocusedWindow() else {
            alertWindow?.showAlert("No focused window!")
            return
        }

        let screens = getSortedScreens()
        let numScreens = screens.count

        // Always detect which screen the window is currently on
        let currentScreenIdx = screenIndexForWindow(window)
        let targetScreen = screens[currentScreenIdx]

        // Get current position index for this key on this screen
        let stateKey = "ninths_screen\(currentScreenIdx)"
        var index = currentPositionIndex[stateKey] ?? 0

        // Cycle to next position
        index += 1
        if index > ninthPositions.count {
            index = 1  // Wrap back to first position (stay on same screen)
        }
        currentPositionIndex[stateKey] = index

        let pos = ninthPositions[index - 1]
        moveWindowToPosition(window, position: pos, screen: targetScreen)

        let row = ((index - 1) / 3) + 1
        let col = ((index - 1) % 3) + 1
        let screenInfo = numScreens > 1 ? " [Screen \(currentScreenIdx + 1)/\(numScreens)]" : ""
        alertWindow?.showAlert("Ninth \(index)/9 (R\(row) C\(col))\(screenInfo)")
    }

    func sixteenths() {
        guard let window = getFocusedWindow() else {
            alertWindow?.showAlert("No focused window!")
            return
        }

        let screens = getSortedScreens()
        let numScreens = screens.count

        // Always detect which screen the window is currently on
        let currentScreenIdx = screenIndexForWindow(window)
        let targetScreen = screens[currentScreenIdx]

        // Get current position index for this key on this screen
        let stateKey = "sixteenths_screen\(currentScreenIdx)"
        var index = currentPositionIndex[stateKey] ?? 0

        // Cycle to next position
        index += 1
        if index > sixteenthPositions.count {
            index = 1  // Wrap back to first position (stay on same screen)
        }
        currentPositionIndex[stateKey] = index

        let pos = sixteenthPositions[index - 1]
        moveWindowToPosition(window, position: pos, screen: targetScreen)

        let row = ((index - 1) / 4) + 1
        let col = ((index - 1) % 4) + 1
        let screenInfo = numScreens > 1 ? " [Screen \(currentScreenIdx + 1)/\(numScreens)]" : ""
        alertWindow?.showAlert("16ths: \(index)/16 (R\(row) C\(col))\(screenInfo)")
    }

    func tileAllWindows() {
        // Get the frontmost app and tile all its windows
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            alertWindow?.showAlert("No active app")
            return
        }

        let appElement = AXUIElementCreateApplication(frontmostApp.processIdentifier)

        // Get all windows of this app
        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef)

        guard result == .success,
              let windowsArray = windowsRef as? [AXUIElement],
              !windowsArray.isEmpty else {
            alertWindow?.showAlert("No windows to tile")
            return
        }

        // Filter to visible, regular windows (exclude minimized, etc.)
        let visibleWindows = windowsArray.filter { window in
            var minimized: CFTypeRef?
            AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &minimized)
            let isMinimized = (minimized as? Bool) ?? false
            return !isMinimized
        }

        let count = visibleWindows.count
        guard count > 0 else {
            alertWindow?.showAlert("No visible windows")
            return
        }

        // Get the screen where the first window is located
        let targetScreen = screenForWindow(visibleWindows[0])

        let frame = targetScreen.visibleFrame
        let primaryHeight = NSScreen.screens[0].frame.height

        // Calculate optimal grid layout
        let cols = Int(ceil(sqrt(Double(count))))
        let rows = Int(ceil(Double(count) / Double(cols)))

        // Tile each window
        for (index, window) in visibleWindows.enumerated() {
            let col = index % cols
            let row = index / cols

            // Calculate position using same boundary math as other positions (no gaps)
            let startX = round(frame.width * CGFloat(col) / CGFloat(cols))
            let endX = round(frame.width * CGFloat(col + 1) / CGFloat(cols))
            let startY = round(frame.height * CGFloat(row) / CGFloat(rows))

            let newWidth = endX - startX
            let newHeight = round(frame.height * CGFloat(row + 1) / CGFloat(rows)) - startY

            // X coordinate: offset from left edge of visible frame
            let newX = frame.origin.x + startX

            // Y coordinate: same conversion as moveWindowToPosition
            let windowTopInCocoa = frame.origin.y + frame.height - startY
            let newY = primaryHeight - windowTopInCocoa

            setWindowPosition(window, position: CGPoint(x: newX, y: newY))
            setWindowSize(window, size: CGSize(width: newWidth, height: newHeight))
        }

        let appName = frontmostApp.localizedName ?? "App"
        let gridDesc = cols == rows ? "\(cols)x\(rows)" : "\(cols)x\(rows)"
        alertWindow?.showAlert("Tiled \(count) \(appName) windows (\(gridDesc))")
    }

    // MARK: - Workspace Layout Methods

    /// Restores a workspace layout by slot number (1-9)
    func restoreWorkspace(slot: Int) {
        if WorkspaceManager.shared.restoreLayoutBySlot(slot) {
            if let layout = WorkspaceManager.shared.layoutForSlot(slot) {
                alertWindow?.showAlert("Restored: \(layout.name)")
            } else {
                alertWindow?.showAlert("Workspace \(slot) restored")
            }
        } else {
            alertWindow?.showAlert("No layout in slot \(slot)")
        }
    }

    /// Shows a dialog to save the current workspace layout
    func promptSaveWorkspace() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Save Workspace Layout"
            alert.informativeText = "Enter a name for this layout:"
            alert.alertStyle = .informational

            let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
            textField.stringValue = "My Workspace"
            alert.accessoryView = textField

            alert.addButton(withTitle: "Save")
            alert.addButton(withTitle: "Cancel")

            // Add slot picker
            let slotPicker = NSPopUpButton(frame: NSRect(x: 0, y: 30, width: 200, height: 24))
            slotPicker.addItem(withTitle: "No shortcut")
            for i in 1...9 {
                let existingLayout = WorkspaceManager.shared.layoutForSlot(i)
                if let layout = existingLayout {
                    slotPicker.addItem(withTitle: "⌘⇧\(i) (replaces \(layout.name))")
                } else {
                    slotPicker.addItem(withTitle: "⌘⇧\(i)")
                }
            }

            let containerView = NSStackView(frame: NSRect(x: 0, y: 0, width: 200, height: 60))
            containerView.orientation = .vertical
            containerView.spacing = 8
            containerView.addArrangedSubview(textField)
            containerView.addArrangedSubview(slotPicker)
            alert.accessoryView = containerView

            NSApp.activate(ignoringOtherApps: true)

            if alert.runModal() == .alertFirstButtonReturn {
                let name = textField.stringValue.isEmpty ? "Workspace" : textField.stringValue
                let slotIndex = slotPicker.indexOfSelectedItem
                let slot = slotIndex > 0 ? slotIndex : nil

                WorkspaceManager.shared.saveCurrentLayout(name: name, shortcutSlot: slot)
                self.alertWindow?.showAlert("Saved: \(name)")
            }
        }
    }
}
