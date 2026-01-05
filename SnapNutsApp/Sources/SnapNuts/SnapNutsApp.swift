import SwiftUI
import AppKit

@main
struct SnapNutsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup("SnapNuts Settings", id: "settings") {
            SettingsView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var hotkeyManager: HotkeyManager?
    var windowManager: WindowManager?
    var alertWindow: AlertWindow?
    var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request accessibility permissions
        requestAccessibilityPermissions()

        // Initialize managers
        windowManager = WindowManager()
        hotkeyManager = HotkeyManager(windowManager: windowManager!)
        alertWindow = AlertWindow()
        windowManager?.alertWindow = alertWindow

        // Setup menu bar
        setupStatusBar()

        // Register global hotkeys
        hotkeyManager?.registerHotkeys()

        // Keep dock icon visible (default behavior for standard app)
        NSApp.setActivationPolicy(.regular)
    }

    func requestAccessibilityPermissions() {
        // First check if already trusted (without prompting)
        let alreadyTrusted = AXIsProcessTrusted()

        if !alreadyTrusted {
            // Only prompt if not already trusted
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
            print("SnapNuts needs Accessibility permissions to manage windows.")
            print("Please enable in System Settings > Privacy & Security > Accessibility")
        }
    }

    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            // Try to load custom icon, fall back to SF Symbol
            if let iconImage = NSImage(named: "StatusBarIcon") {
                iconImage.size = NSSize(width: 18, height: 18)
                iconImage.isTemplate = true
                button.image = iconImage
            } else {
                button.image = NSImage(systemSymbolName: "square.grid.3x3", accessibilityDescription: "SnapNuts")
            }
            button.toolTip = "SnapNuts - Window Manager"
        }

        let menu = NSMenu()

        // Title
        let titleItem = NSMenuItem(title: "SnapNuts", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        menu.addItem(NSMenuItem.separator())

        // Shortcuts reference
        let shortcutsItem = NSMenuItem(title: "Shortcuts", action: nil, keyEquivalent: "")
        shortcutsItem.submenu = createShortcutsMenu()
        menu.addItem(shortcutsItem)

        menu.addItem(NSMenuItem.separator())

        // Settings
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))

        menu.addItem(NSMenuItem.separator())

        // Quit
        menu.addItem(NSMenuItem(title: "Quit SnapNuts", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    func createShortcutsMenu() -> NSMenu {
        let menu = NSMenu()

        let shortcuts = [
            ("⌘ + 0", "Tile All Windows"),
            ("⌘ + 1", "Maximize"),
            ("⌘ + 2", "Halves (2 positions)"),
            ("⌘ + 3", "Thirds (3 positions)"),
            ("⌘ + 4", "Fourths + Corners (8 positions)"),
            ("⌘ + 5", "Center (80%)"),
            ("⌘ + 6", "Sixths (6 positions)"),
            ("⌘ + 7", "Almost Maximize (90%)"),
            ("⌘ + 8", "Eighths (8 positions)"),
            ("⌘ + 9", "Ninths (9 positions)"),
            ("⌘ + ⌥ + 4", "Sixteenths (16 positions)")
        ]

        for (key, description) in shortcuts {
            let item = NSMenuItem(title: "\(key)  →  \(description)", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        }

        return menu
    }

    @objc func openSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView()
            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 520, height: 420),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            settingsWindow?.title = "SnapNuts Settings"
            settingsWindow?.contentView = NSHostingView(rootView: settingsView)
            settingsWindow?.center()
            settingsWindow?.isReleasedWhenClosed = false
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func quitApp() {
        hotkeyManager?.unregisterHotkeys()
        NSApplication.shared.terminate(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager?.unregisterHotkeys()
    }

    // Handle dock icon click - open Settings window
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            openSettings()
        }
        return true
    }

    // Also handle when app becomes active with no windows
    func applicationDidBecomeActive(_ notification: Notification) {
        // If no windows are visible, show settings
        if NSApp.windows.filter({ $0.isVisible && !($0.className.contains("StatusBar")) }).isEmpty {
            // Small delay to avoid conflicts with initial launch
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                if NSApp.windows.filter({ $0.isVisible && $0.canBecomeMain }).isEmpty {
                    self?.openSettings()
                }
            }
        }
    }
}
