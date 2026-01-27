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
    var lastPermissionState: Bool = false

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

        // Initialize grid overlay
        GridOverlayController.shared.setWindowManager(windowManager!)

        // Initialize drag-to-snap
        DragSnapController.shared.setWindowManager(windowManager!)
        DragSnapController.shared.start()

        // Initialize window stashing
        WindowStashController.shared.setWindowManager(windowManager!)

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
        // Track initial state
        lastPermissionState = AXIsProcessTrusted()

        // Check permission status periodically to update UI and re-register hotkeys if needed
        // 2-second interval provides responsive feedback without excessive polling
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            let currentPermission = AXIsProcessTrusted()

            // If permission was just granted, re-register hotkeys
            if currentPermission && !self.lastPermissionState {
                print("SnapNuts: Accessibility permission granted - re-registering hotkeys")
                self.hotkeyManager?.unregisterHotkeys()
                self.hotkeyManager?.registerHotkeys()
            }

            self.lastPermissionState = currentPermission
            self.updateStatusBarIcon()
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

        // Grid Overlay
        let gridItem = NSMenuItem(title: "Show Grid Overlay", action: #selector(showGridOverlay), keyEquivalent: "g")
        gridItem.target = self
        menu.addItem(gridItem)

        // Workspaces submenu
        let workspacesItem = NSMenuItem(title: "Workspaces", action: nil, keyEquivalent: "")
        workspacesItem.submenu = createWorkspacesMenu()
        menu.addItem(workspacesItem)

        // Window Stashing submenu
        let stashItem = NSMenuItem(title: "Stash Window", action: nil, keyEquivalent: "")
        stashItem.submenu = createStashMenu()
        menu.addItem(stashItem)

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

    @objc func showGridOverlay() {
        windowManager?.showGridOverlay()
    }

    func createWorkspacesMenu() -> NSMenu {
        let menu = NSMenu()

        // Save current layout
        let saveItem = NSMenuItem(title: "Save Current Layout...", action: #selector(saveWorkspace), keyEquivalent: "S")
        saveItem.keyEquivalentModifierMask = [.command, .shift]
        saveItem.target = self
        menu.addItem(saveItem)

        menu.addItem(NSMenuItem.separator())

        // List saved layouts
        let layouts = WorkspaceManager.shared.layouts
        if layouts.isEmpty {
            let emptyItem = NSMenuItem(title: "No saved layouts", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            for layout in layouts {
                var title = layout.name
                if let slot = layout.shortcutSlot {
                    title = "[\(slot)] \(layout.name)"
                }

                let item = NSMenuItem(title: title, action: #selector(restoreWorkspaceFromMenu(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = layout.id
                menu.addItem(item)
            }
        }

        menu.addItem(NSMenuItem.separator())

        // Open settings to workspaces tab
        let manageItem = NSMenuItem(title: "Manage Workspaces...", action: #selector(openSettings), keyEquivalent: "")
        manageItem.target = self
        menu.addItem(manageItem)

        return menu
    }

    @objc func saveWorkspace() {
        windowManager?.promptSaveWorkspace()
    }

    @objc func restoreWorkspaceFromMenu(_ sender: NSMenuItem) {
        guard let layoutId = sender.representedObject as? UUID,
              let layout = WorkspaceManager.shared.layouts.first(where: { $0.id == layoutId }) else { return }
        _ = WorkspaceManager.shared.restoreLayout(layout)
        alertWindow?.showAlert("Restored: \(layout.name)")
    }

    func createStashMenu() -> NSMenu {
        let menu = NSMenu()

        let stashLeftItem = NSMenuItem(title: "Stash to Left", action: #selector(stashLeft), keyEquivalent: "")
        stashLeftItem.keyEquivalentModifierMask = [.command, .shift]
        stashLeftItem.target = self
        menu.addItem(stashLeftItem)

        let stashRightItem = NSMenuItem(title: "Stash to Right", action: #selector(stashRight), keyEquivalent: "")
        stashRightItem.keyEquivalentModifierMask = [.command, .shift]
        stashRightItem.target = self
        menu.addItem(stashRightItem)

        menu.addItem(NSMenuItem.separator())

        let unstashAllItem = NSMenuItem(title: "Unstash All Windows", action: #selector(unstashAll), keyEquivalent: "U")
        unstashAllItem.keyEquivalentModifierMask = [.command, .shift]
        unstashAllItem.target = self
        menu.addItem(unstashAllItem)

        // Show stashed windows count
        let stashedCount = WindowStashController.shared.stashedWindowCount
        if stashedCount > 0 {
            menu.addItem(NSMenuItem.separator())
            let countItem = NSMenuItem(title: "\(stashedCount) window(s) stashed", action: nil, keyEquivalent: "")
            countItem.isEnabled = false
            menu.addItem(countItem)
        }

        return menu
    }

    @objc func stashLeft() {
        WindowStashController.shared.stashFocusedWindow(to: .left)
    }

    @objc func stashRight() {
        WindowStashController.shared.stashFocusedWindow(to: .right)
    }

    @objc func unstashAll() {
        WindowStashController.shared.unstashAllWindows()
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
