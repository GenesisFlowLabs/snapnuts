import AppKit
import SwiftUI

/// Represents a saved window position within a layout
struct SavedWindow: Codable, Identifiable {
    var id: UUID = UUID()
    let bundleIdentifier: String
    let appName: String
    let windowTitle: String
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
    let screenIndex: Int // Which screen the window is on

    init(bundleIdentifier: String, appName: String, windowTitle: String, frame: CGRect, screenIndex: Int) {
        self.bundleIdentifier = bundleIdentifier
        self.appName = appName
        self.windowTitle = windowTitle
        self.x = frame.origin.x
        self.y = frame.origin.y
        self.width = frame.size.width
        self.height = frame.size.height
        self.screenIndex = screenIndex
    }

    var frame: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }
}

/// Represents a saved workspace layout
struct WorkspaceLayout: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var windows: [SavedWindow]
    var createdAt: Date
    var shortcutSlot: Int? // 1-9 for Cmd+Shift+1 through Cmd+Shift+9

    init(name: String, windows: [SavedWindow], shortcutSlot: Int? = nil) {
        self.name = name
        self.windows = windows
        self.createdAt = Date()
        self.shortcutSlot = shortcutSlot
    }
}

/// Manages workspace layouts - saving, loading, and restoring window arrangements
class WorkspaceManager: ObservableObject {
    static let shared = WorkspaceManager()

    @Published var layouts: [WorkspaceLayout] = []

    private let storageKey = "SnapNuts_WorkspaceLayouts"

    init() {
        loadLayouts()
    }

    // MARK: - Layout Persistence

    private func loadLayouts() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([WorkspaceLayout].self, from: data) else {
            return
        }
        layouts = decoded
    }

    private func saveLayouts() {
        guard let encoded = try? JSONEncoder().encode(layouts) else { return }
        UserDefaults.standard.set(encoded, forKey: storageKey)
    }

    // MARK: - Capture Current Windows

    /// Captures all visible windows and their positions
    func captureCurrentLayout(name: String, shortcutSlot: Int? = nil) -> WorkspaceLayout {
        var savedWindows: [SavedWindow] = []
        let screens = NSScreen.screens

        // Get running applications
        let runningApps = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular
        }

        for app in runningApps {
            guard let bundleId = app.bundleIdentifier,
                  let appName = app.localizedName else { continue }

            // Skip our own app
            if bundleId == Bundle.main.bundleIdentifier { continue }

            // Get windows for this app using Accessibility API
            let appRef = AXUIElementCreateApplication(app.processIdentifier)

            var windowsValue: CFTypeRef?
            guard AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowsValue) == .success,
                  let windows = windowsValue as? [AXUIElement] else { continue }

            for window in windows {
                // Check if window is visible and has a size
                var roleValue: CFTypeRef?
                AXUIElementCopyAttributeValue(window, kAXRoleAttribute as CFString, &roleValue)
                guard let role = roleValue as? String, role == kAXWindowRole as String else { continue }

                // Get window position and size
                var positionValue: CFTypeRef?
                var sizeValue: CFTypeRef?

                guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue) == .success,
                      AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue) == .success else { continue }

                var position = CGPoint.zero
                var size = CGSize.zero

                AXValueGetValue(positionValue as! AXValue, .cgPoint, &position)
                AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)

                // Skip windows that are too small (likely hidden or minimized)
                if size.width < 100 || size.height < 100 { continue }

                // Get window title
                var titleValue: CFTypeRef?
                AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleValue)
                let windowTitle = titleValue as? String ?? "Untitled"

                // Determine which screen the window is on
                let windowFrame = CGRect(origin: position, size: size)
                let screenIndex = findScreenIndex(for: windowFrame, screens: screens)

                let savedWindow = SavedWindow(
                    bundleIdentifier: bundleId,
                    appName: appName,
                    windowTitle: windowTitle,
                    frame: windowFrame,
                    screenIndex: screenIndex
                )

                savedWindows.append(savedWindow)
            }
        }

        let layout = WorkspaceLayout(name: name, windows: savedWindows, shortcutSlot: shortcutSlot)
        return layout
    }

    /// Finds which screen a window is primarily on
    private func findScreenIndex(for windowFrame: CGRect, screens: [NSScreen]) -> Int {
        var bestMatch = 0
        var maxOverlap: CGFloat = 0

        for (index, screen) in screens.enumerated() {
            let intersection = windowFrame.intersection(screen.frame)
            let overlap = intersection.width * intersection.height
            if overlap > maxOverlap {
                maxOverlap = overlap
                bestMatch = index
            }
        }

        return bestMatch
    }

    // MARK: - Save Layout

    /// Saves the current window arrangement as a new layout
    func saveCurrentLayout(name: String, shortcutSlot: Int? = nil) {
        let layout = captureCurrentLayout(name: name, shortcutSlot: shortcutSlot)

        // If a shortcut slot is assigned, remove it from any existing layout
        if let slot = shortcutSlot {
            for i in layouts.indices {
                if layouts[i].shortcutSlot == slot {
                    layouts[i].shortcutSlot = nil
                }
            }
        }

        layouts.append(layout)
        saveLayouts()
    }

    /// Updates an existing layout with current window positions
    func updateLayout(_ layout: WorkspaceLayout) {
        guard let index = layouts.firstIndex(where: { $0.id == layout.id }) else { return }
        let updatedLayout = captureCurrentLayout(name: layout.name, shortcutSlot: layout.shortcutSlot)
        layouts[index] = updatedLayout
        saveLayouts()
    }

    /// Deletes a layout
    func deleteLayout(_ layout: WorkspaceLayout) {
        layouts.removeAll { $0.id == layout.id }
        saveLayouts()
    }

    /// Renames a layout
    func renameLayout(_ layout: WorkspaceLayout, to newName: String) {
        guard let index = layouts.firstIndex(where: { $0.id == layout.id }) else { return }
        layouts[index].name = newName
        saveLayouts()
    }

    /// Assigns a shortcut slot to a layout
    func assignShortcut(_ layout: WorkspaceLayout, slot: Int?) {
        // Remove slot from any existing layout
        if let slot = slot {
            for i in layouts.indices {
                if layouts[i].shortcutSlot == slot {
                    layouts[i].shortcutSlot = nil
                }
            }
        }

        // Assign to the specified layout
        guard let index = layouts.firstIndex(where: { $0.id == layout.id }) else { return }
        layouts[index].shortcutSlot = slot
        saveLayouts()
    }

    // MARK: - Restore Layout

    /// Restores a saved layout by repositioning windows
    func restoreLayout(_ layout: WorkspaceLayout) -> Bool {
        let screens = NSScreen.screens
        var restoredCount = 0

        // Get running applications
        let runningApps = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular
        }

        for savedWindow in layout.windows {
            // Find the app
            guard let app = runningApps.first(where: { $0.bundleIdentifier == savedWindow.bundleIdentifier }) else {
                // App not running, try to launch it
                if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: savedWindow.bundleIdentifier) {
                    NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration()) { _, error in
                        if error != nil {
                            print("Failed to launch \(savedWindow.appName)")
                        }
                    }
                }
                continue
            }

            // Get the app's windows
            let appRef = AXUIElementCreateApplication(app.processIdentifier)

            var windowsValue: CFTypeRef?
            guard AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowsValue) == .success,
                  let windows = windowsValue as? [AXUIElement] else { continue }

            // Find a matching window (first available if title doesn't match)
            var targetWindow: AXUIElement?

            for window in windows {
                var titleValue: CFTypeRef?
                AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleValue)
                let title = titleValue as? String ?? ""

                if title == savedWindow.windowTitle {
                    targetWindow = window
                    break
                }
            }

            // If no exact match, use first window
            if targetWindow == nil && !windows.isEmpty {
                targetWindow = windows[0]
            }

            guard let window = targetWindow else { continue }

            // Calculate target position, accounting for screen changes
            var targetFrame = savedWindow.frame

            // If the original screen still exists, use it; otherwise use primary screen
            let targetScreen: NSScreen
            if savedWindow.screenIndex < screens.count {
                targetScreen = screens[savedWindow.screenIndex]
            } else {
                targetScreen = screens[0]
            }

            // Adjust position if screen has changed
            if savedWindow.screenIndex != 0 && savedWindow.screenIndex >= screens.count {
                // Original screen no longer exists, reposition to primary screen
                targetFrame.origin.x = targetScreen.frame.origin.x + (targetFrame.origin.x - targetFrame.origin.x)
                targetFrame.origin.y = targetScreen.frame.origin.y + (targetFrame.origin.y - targetFrame.origin.y)
            }

            // Set window position
            var position = targetFrame.origin
            var positionValue = AXValueCreate(.cgPoint, &position)!
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)

            // Small delay for cross-screen moves
            Thread.sleep(forTimeInterval: 0.05)

            // Set window size
            var size = targetFrame.size
            var sizeValue = AXValueCreate(.cgSize, &size)!
            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)

            restoredCount += 1
        }

        return restoredCount > 0
    }

    /// Restores layout by shortcut slot (1-9)
    func restoreLayoutBySlot(_ slot: Int) -> Bool {
        guard let layout = layouts.first(where: { $0.shortcutSlot == slot }) else {
            return false
        }
        return restoreLayout(layout)
    }

    /// Gets layout for a specific slot
    func layoutForSlot(_ slot: Int) -> WorkspaceLayout? {
        return layouts.first { $0.shortcutSlot == slot }
    }
}

// MARK: - Notification for Workspace Changes

extension Notification.Name {
    static let workspaceLayoutsDidChange = Notification.Name("workspaceLayoutsDidChange")
}
