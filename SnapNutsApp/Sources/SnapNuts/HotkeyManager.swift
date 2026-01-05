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

    func registerHotkeys() {
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

        // Also register fallback Cmd+Ctrl+Number shortcuts for keyboards without numpad
        let fallbackShortcuts: [(action: String, keyCode: UInt32)] = [
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

        for (action, keyCode) in fallbackShortcuts {
            registerHotkey(actionKey: action, keyCode: keyCode, modifiers: UInt32(cmdKey | controlKey))
        }

        // Cmd+Ctrl+Option+4 for sixteenths fallback
        registerHotkey(actionKey: "sixteenths", keyCode: 21, modifiers: UInt32(cmdKey | controlKey | optionKey))

        print("SnapNuts: Hotkeys registered (custom shortcuts enabled)")
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
        } else {
            // Silently fail for conflicts (e.g., duplicate registrations)
            if status != -9878 { // paramErr for already registered
                print("Failed to register hotkey for \(actionKey): \(status)")
            }
        }
    }

    func handleHotkey(id: UInt32) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let actionKey = self.hotkeyActions[id] else { return }

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
