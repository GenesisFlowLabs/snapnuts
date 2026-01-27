import AppKit
import Carbon

/// Manages global hotkey registration using Carbon APIs
class HotkeyManager {
    private var windowManager: WindowManager
    private var eventHandler: EventHandlerRef?
    private var hotkeyRefs: [EventHotKeyRef?] = []
    private var shortcutObserver: NSObjectProtocol?

    // Hotkey signature for our app
    private let hotkeySignature: UInt32 = OSType("SNAP".utf8.reduce(0) { ($0 << 8) + UInt32($1) })

    // Map hotkey IDs to action names
    private var hotkeyActions: [UInt32: String] = [:]
    private var nextHotkeyID: UInt32 = 1

    init(windowManager: WindowManager) {
        self.windowManager = windowManager

        // Listen for shortcut changes
        shortcutObserver = NotificationCenter.default.addObserver(
            forName: .shortcutsDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reregisterHotkeys()
        }
    }

    deinit {
        if let observer = shortcutObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        unregisterHotkeys()
    }

    private func reregisterHotkeys() {
        unregisterHotkeys()
        registerHotkeys()
    }

    private func debugLog(_ message: String) {
        let logPath = NSHomeDirectory() + "/Desktop/snapnuts-debug.log"
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logMessage = "[\(timestamp)] \(message)\n"
        if let handle = FileHandle(forWritingAtPath: logPath) {
            handle.seekToEndOfFile()
            handle.write(logMessage.data(using: .utf8)!)
            handle.closeFile()
        } else {
            FileManager.default.createFile(atPath: logPath, contents: logMessage.data(using: .utf8))
        }
        print(message)
    }

    func registerHotkeys() {
        debugLog("registerHotkeys() called - AXIsProcessTrusted: \(AXIsProcessTrusted())")

        // Install event handler if not already installed
        if eventHandler == nil {
            var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

            let handler: EventHandlerUPP = { (nextHandler, event, userData) -> OSStatus in
                guard let userData = userData else { return OSStatus(eventNotHandledErr) }

                var hotkeyID = EventHotKeyID()
                GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                                nil, MemoryLayout<EventHotKeyID>.size, nil, &hotkeyID)

                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                manager.handleHotkey(id: hotkeyID.id)

                return noErr
            }

            let selfPtr = Unmanaged.passUnretained(self).toOpaque()
            InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventType, selfPtr, &eventHandler)
        }

        // Clear existing registrations
        hotkeyActions.removeAll()
        nextHotkeyID = 1

        // Get shortcuts from storage
        let shortcuts = ShortcutStorage.shared.shortcuts

        // Register each shortcut
        let actionKeys = ["tileAll", "maximize", "halves", "thirds", "fourths",
                         "center", "sixths", "almostMax", "eighths", "ninths", "sixteenths"]

        for actionKey in actionKeys {
            if let shortcut = shortcuts[actionKey] {
                registerHotkey(actionKey: actionKey, keyCode: shortcut.keyCode, modifiers: shortcut.modifiers)
            }
        }

        // Also register regular number keys for users without numpads (Cmd+Number)
        let regularKeyShortcuts: [(action: String, keyCode: UInt32)] = [
            ("tileAll", 29),   // 0
            ("maximize", 18),  // 1
            ("halves", 19),    // 2
            ("thirds", 20),    // 3
            ("fourths", 21),   // 4
            ("center", 23),    // 5
            ("sixths", 22),    // 6
            ("almostMax", 26), // 7
            ("eighths", 28),   // 8
            ("ninths", 25)     // 9
        ]

        for (action, keyCode) in regularKeyShortcuts {
            registerHotkey(actionKey: action, keyCode: keyCode, modifiers: UInt32(cmdKey))
        }

        // Cmd+Option+4 for sixteenths on regular keyboard
        registerHotkey(actionKey: "sixteenths", keyCode: 21, modifiers: UInt32(cmdKey | optionKey))

        // Cmd+G for grid overlay
        registerHotkey(actionKey: "gridOverlay", keyCode: 5, modifiers: UInt32(cmdKey))

        // Cmd+Ctrl+G for grid overlay (fallback without numpad)
        registerHotkey(actionKey: "gridOverlay", keyCode: 5, modifiers: UInt32(cmdKey | controlKey))

        // Workspace Layout shortcuts: Cmd+Shift+1 through Cmd+Shift+9 to restore layouts
        let workspaceKeyCodes: [(slot: Int, keyCode: UInt32)] = [
            (1, 18),  // 1
            (2, 19),  // 2
            (3, 20),  // 3
            (4, 21),  // 4
            (5, 23),  // 5
            (6, 22),  // 6
            (7, 26),  // 7
            (8, 28),  // 8
            (9, 25)   // 9
        ]

        for (slot, keyCode) in workspaceKeyCodes {
            registerHotkey(actionKey: "workspace\(slot)", keyCode: keyCode, modifiers: UInt32(cmdKey | shiftKey))
        }

        // Cmd+Shift+S to save current layout
        registerHotkey(actionKey: "saveWorkspace", keyCode: 1, modifiers: UInt32(cmdKey | shiftKey))

        // Window stashing shortcuts
        // Cmd+Shift+Left Arrow (keyCode 123) to stash left
        registerHotkey(actionKey: "stashLeft", keyCode: 123, modifiers: UInt32(cmdKey | shiftKey))
        // Cmd+Shift+Right Arrow (keyCode 124) to stash right
        registerHotkey(actionKey: "stashRight", keyCode: 124, modifiers: UInt32(cmdKey | shiftKey))
        // Cmd+Shift+U to unstash all
        registerHotkey(actionKey: "unstashAll", keyCode: 32, modifiers: UInt32(cmdKey | shiftKey))

        // Cmd+Shift+Z to undo last snap
        registerHotkey(actionKey: "undoSnap", keyCode: 6, modifiers: UInt32(cmdKey | shiftKey))

        let permissionStatus = AXIsProcessTrusted() ? "granted" : "NOT GRANTED"
        print("SnapNuts: Hotkeys registered (custom shortcuts enabled) - Accessibility: \(permissionStatus)")
    }

    private func registerHotkey(actionKey: String, keyCode: UInt32, modifiers: UInt32) {
        let hotkeyID = nextHotkeyID
        nextHotkeyID += 1

        var carbonHotkeyID = EventHotKeyID(signature: hotkeySignature, id: hotkeyID)
        var hotkeyRef: EventHotKeyRef?

        let status = RegisterEventHotKey(keyCode, modifiers, carbonHotkeyID, GetApplicationEventTarget(), 0, &hotkeyRef)

        if status == noErr {
            hotkeyRefs.append(hotkeyRef)
            hotkeyActions[hotkeyID] = actionKey
            debugLog("  ✓ Registered hotkey \(actionKey) (id=\(hotkeyID), keyCode=\(keyCode))")
        } else {
            debugLog("  ✗ FAILED to register hotkey \(actionKey): error \(status)")
        }
    }

    func handleHotkey(id: UInt32) {
        debugLog("handleHotkey triggered: id=\(id)")
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let actionKey = self.hotkeyActions[id] else {
                self?.debugLog("  No action found for hotkey id \(id)")
                return
            }
            self.debugLog("  Executing action: \(actionKey)")

            switch actionKey {
            case "tileAll":
                self.windowManager.tileAllWindows()
            case "maximize":
                self.windowManager.maximize()
            case "halves":
                self.windowManager.halves()
            case "thirds":
                self.windowManager.thirds()
            case "fourths":
                self.windowManager.fourths()
            case "center":
                self.windowManager.center()
            case "sixths":
                self.windowManager.sixths()
            case "almostMax":
                self.windowManager.almostMax()
            case "eighths":
                self.windowManager.eighths()
            case "ninths":
                self.windowManager.ninths()
            case "sixteenths":
                self.windowManager.sixteenths()
            case "gridOverlay":
                self.windowManager.toggleGridOverlay()
            case "saveWorkspace":
                self.windowManager.promptSaveWorkspace()
            case let action where action.hasPrefix("workspace"):
                if let slotStr = action.dropFirst("workspace".count).first,
                   let slot = Int(String(slotStr)) {
                    self.windowManager.restoreWorkspace(slot: slot)
                }
            case "stashLeft":
                WindowStashController.shared.stashFocusedWindow(to: .left)
            case "stashRight":
                WindowStashController.shared.stashFocusedWindow(to: .right)
            case "unstashAll":
                WindowStashController.shared.unstashAllWindows()
            case "undoSnap":
                self.windowManager.undoLastSnap()
            default:
                break
            }
        }
    }

    func unregisterHotkeys() {
        for hotkeyRef in hotkeyRefs {
            if let ref = hotkeyRef {
                UnregisterEventHotKey(ref)
            }
        }
        hotkeyRefs.removeAll()
        hotkeyActions.removeAll()

        print("SnapNuts: Hotkeys unregistered")
    }
}
