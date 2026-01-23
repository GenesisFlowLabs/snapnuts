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

/// Manages window positioning and multi-monitor cycling
class WindowManager {
    weak var alertWindow: AlertWindow?

    // Position tracking for cycling
    private var currentPositionIndex: [String: Int] = [:]
    private var currentScreenIndex: Int = 1

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

    /// Find which screen a window is on
    func screenIndexForWindow(_ window: AXUIElement) -> Int {
        guard let position = getWindowPosition(window) else { return 0 }
        let screens = getSortedScreens()

        for (index, screen) in screens.enumerated() {
            if screen.frame.contains(CGPoint(x: position.x + 10, y: position.y + 10)) {
                return index
            }
        }
        return 0
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

    /// Move window to a position on a specific screen
    func moveWindowToPosition(_ window: AXUIElement, position: WindowPosition, screen: NSScreen) {
        let frame = screen.visibleFrame

        // Calculate pixel boundaries using consistent rounding to eliminate gaps
        // By calculating start and end positions separately, adjacent windows share exact boundaries
        let startX = round(frame.width * position.x)
        let endX = round(frame.width * (position.x + position.width))
        let startY = round(frame.height * position.y)
        let endY = round(frame.height * (position.y + position.height))

        let newX = frame.origin.x + startX
        let newY = frame.origin.y + frame.height - endY  // Flip Y coordinate (macOS origin is bottom-left)
        let newWidth = endX - startX
        let newHeight = endY - startY

        setWindowPosition(window, position: CGPoint(x: newX, y: newY))
        setWindowSize(window, size: CGSize(width: newWidth, height: newHeight))
    }

    // MARK: - Position Cycling

    /// Cycle to next position with multi-monitor support
    func cyclePosition(key: String, positions: [WindowPosition], labels: [String]? = nil) {
        guard let window = getFocusedWindow() else {
            alertWindow?.showAlert("No focused window!")
            return
        }

        let screens = getSortedScreens()
        let numScreens = screens.count

        // Get current index for this key
        var index = currentPositionIndex[key] ?? 0
        var wrapAround = false

        index += 1
        if index > positions.count {
            index = 1
            wrapAround = true
        }
        currentPositionIndex[key] = index

        // Handle multi-monitor cycling
        if wrapAround && numScreens > 1 {
            currentScreenIndex += 1
            if currentScreenIndex > numScreens {
                currentScreenIndex = 1
            }
        } else if !wrapAround {
            // Find current screen of window
            currentScreenIndex = screenIndexForWindow(window) + 1
        }

        let targetScreenIndex = min(currentScreenIndex - 1, screens.count - 1)
        let targetScreen = screens[targetScreenIndex]
        let pos = positions[index - 1]

        moveWindowToPosition(window, position: pos, screen: targetScreen)

        // Show feedback
        let label: String
        if let labels = labels, index <= labels.count {
            label = labels[index - 1]
        } else {
            label = "\(index)/\(positions.count)"
        }

        let screenInfo = numScreens > 1 ? " [\(currentScreenIndex)/\(numScreens)]" : ""
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

        var index = currentPositionIndex["ninths"] ?? 0
        var wrapAround = false

        index += 1
        if index > ninthPositions.count {
            index = 1
            wrapAround = true
        }
        currentPositionIndex["ninths"] = index

        if wrapAround && numScreens > 1 {
            currentScreenIndex += 1
            if currentScreenIndex > numScreens {
                currentScreenIndex = 1
            }
        } else if !wrapAround {
            currentScreenIndex = screenIndexForWindow(window) + 1
        }

        let targetScreenIndex = min(currentScreenIndex - 1, screens.count - 1)
        let targetScreen = screens[targetScreenIndex]
        let pos = ninthPositions[index - 1]

        moveWindowToPosition(window, position: pos, screen: targetScreen)

        let row = ((index - 1) / 3) + 1
        let col = ((index - 1) % 3) + 1
        let screenInfo = numScreens > 1 ? " [\(currentScreenIndex)/\(numScreens)]" : ""
        alertWindow?.showAlert("Ninth \(index)/9 (R\(row) C\(col))\(screenInfo)")
    }

    func sixteenths() {
        guard let window = getFocusedWindow() else {
            alertWindow?.showAlert("No focused window!")
            return
        }

        let screens = getSortedScreens()
        let numScreens = screens.count

        var index = currentPositionIndex["sixteenths"] ?? 0
        var wrapAround = false

        index += 1
        if index > sixteenthPositions.count {
            index = 1
            wrapAround = true
        }
        currentPositionIndex["sixteenths"] = index

        if wrapAround && numScreens > 1 {
            currentScreenIndex += 1
            if currentScreenIndex > numScreens {
                currentScreenIndex = 1
            }
        } else if !wrapAround {
            currentScreenIndex = screenIndexForWindow(window) + 1
        }

        let targetScreenIndex = min(currentScreenIndex - 1, screens.count - 1)
        let targetScreen = screens[targetScreenIndex]
        let pos = sixteenthPositions[index - 1]

        moveWindowToPosition(window, position: pos, screen: targetScreen)

        let row = ((index - 1) / 4) + 1
        let col = ((index - 1) % 4) + 1
        let screenInfo = numScreens > 1 ? " [\(currentScreenIndex)/\(numScreens)]" : ""
        alertWindow?.showAlert("16ths: \(index)/16 (R\(row) C\(col))\(screenInfo)")
    }

    func tileAllWindows() {
        // Get all visible windows
        let options = CGWindowListOption(arrayLiteral: .excludeDesktopElements, .optionOnScreenOnly)
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return
        }

        let mainScreen = NSScreen.main ?? NSScreen.screens.first!
        let frame = mainScreen.visibleFrame

        // Filter to regular windows (layer 0)
        let regularWindows = windowList.filter { window in
            let layer = window[kCGWindowLayer as String] as? Int ?? -1
            let alpha = window[kCGWindowAlpha as String] as? Float ?? 0
            return layer == 0 && alpha > 0
        }

        let count = regularWindows.count
        guard count > 0 else { return }

        // Calculate grid
        let cols = Int(ceil(sqrt(Double(count))))
        let rows = Int(ceil(Double(count) / Double(cols)))

        let windowWidth = frame.width / CGFloat(cols)
        let windowHeight = frame.height / CGFloat(rows)

        // We can't easily move arbitrary windows without their AXUIElement
        // This is a simplified version - full implementation would need to enumerate app windows
        alertWindow?.showAlert("Tile All: \(count) windows")
    }
}
