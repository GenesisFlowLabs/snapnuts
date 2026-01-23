import SwiftUI
import AppKit
import Sparkle

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
    var onboardingWindow: NSWindow?
    var permissionCheckTimer: Timer?

    // Sparkle updater controller
    var updaterController: SPUStandardUpdaterController!

    // Check if this is the first launch
    var isFirstLaunch: Bool {
        !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize Sparkle updater
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)

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

        // Show onboarding or check permissions
        if isFirstLaunch || !AXIsProcessTrusted() {
            showOnboarding()
        } else {
            // Start permission monitoring for menu bar indicator
            startPermissionMonitoring()
        }
    }

    func showOnboarding() {
        if onboardingWindow == nil {
            let onboardingView = OnboardingView(onComplete: { [weak self] in
                self?.completeOnboarding()
            })

            onboardingWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 500, height: 520),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            onboardingWindow?.title = "Welcome to SnapNuts"
            onboardingWindow?.contentView = NSHostingView(rootView: onboardingView)
            onboardingWindow?.center()
            onboardingWindow?.isReleasedWhenClosed = false
        }

        onboardingWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        onboardingWindow?.close()
        onboardingWindow = nil

        // Update menu bar status
        updateStatusBarIcon()
        startPermissionMonitoring()

        // If permissions not granted, the menu will show the warning
        if !AXIsProcessTrusted() {
            // Show a subtle reminder
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.openSettings()
            }
        }
    }

    func startPermissionMonitoring() {
        // Check permission status periodically to update UI
        // Use longer interval (10s) to avoid excessive polling and potential race conditions
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.updateStatusBarIcon()
        }
    }

    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusBarIcon()

        let menu = NSMenu()

        // Title with permission status
        updateMenu(menu)

        statusItem?.menu = menu
    }

    func updateStatusBarIcon() {
        guard let button = statusItem?.button else { return }

        let hasPermission = AXIsProcessTrusted()

        // Try to load custom icon, fall back to SF Symbol
        if let iconImage = NSImage(named: "StatusBarIcon") {
            iconImage.size = NSSize(width: 18, height: 18)
            iconImage.isTemplate = true
            button.image = iconImage
        } else {
            button.image = NSImage(systemSymbolName: "square.grid.3x3", accessibilityDescription: "SnapNuts")
        }

        // Add warning badge if no permission
        if !hasPermission {
            button.image = NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: "SnapNuts - Permission Required")
        }

        button.toolTip = hasPermission ? "SnapNuts - Window Manager" : "SnapNuts - Permission Required"

        // Update menu
        if let menu = statusItem?.menu {
            updateMenu(menu)
        }
    }

    func updateMenu(_ menu: NSMenu) {
        menu.removeAllItems()

        let hasPermission = AXIsProcessTrusted()

        // Title
        let titleItem = NSMenuItem(title: "SnapNuts", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        // Permission warning if needed
        if !hasPermission {
            menu.addItem(NSMenuItem.separator())

            let warningItem = NSMenuItem(title: "⚠️ Accessibility Permission Required", action: #selector(openAccessibilitySettings), keyEquivalent: "")
            warningItem.target = self
            menu.addItem(warningItem)

            let helpItem = NSMenuItem(title: "   Click to grant access...", action: #selector(openAccessibilitySettings), keyEquivalent: "")
            helpItem.target = self
            helpItem.isEnabled = true
            menu.addItem(helpItem)
        }

        menu.addItem(NSMenuItem.separator())

        // Shortcuts reference
        let shortcutsItem = NSMenuItem(title: "Shortcuts", action: nil, keyEquivalent: "")
        shortcutsItem.submenu = createShortcutsMenu()
        menu.addItem(shortcutsItem)

        menu.addItem(NSMenuItem.separator())

        // Settings
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))

        // Show onboarding again option
        let onboardingItem = NSMenuItem(title: "Show Welcome Guide...", action: #selector(showOnboardingFromMenu), keyEquivalent: "")
        onboardingItem.target = self
        menu.addItem(onboardingItem)

        // Check for Updates
        let updateItem = NSMenuItem(title: "Check for Updates...", action: #selector(SPUStandardUpdaterController.checkForUpdates(_:)), keyEquivalent: "u")
        updateItem.target = updaterController
        menu.addItem(updateItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        menu.addItem(NSMenuItem(title: "Quit SnapNuts", action: #selector(quitApp), keyEquivalent: "q"))
    }

    @objc func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    @objc func showOnboardingFromMenu() {
        showOnboarding()
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
        permissionCheckTimer?.invalidate()
        NSApplication.shared.terminate(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager?.unregisterHotkeys()
        permissionCheckTimer?.invalidate()
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
