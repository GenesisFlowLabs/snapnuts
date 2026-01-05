import SwiftUI
import AppKit
import Carbon

/// Represents a keyboard shortcut with modifiers and key code
struct KeyboardShortcut: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32

    var displayString: String {
        var parts: [String] = []

        if modifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("⌥") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("⇧") }
        if modifiers & UInt32(cmdKey) != 0 { parts.append("⌘") }

        parts.append(keyCodeToString(keyCode))

        return parts.joined(separator: " ")
    }

    private func keyCodeToString(_ code: UInt32) -> String {
        // Numpad keys
        let numpadKeys: [UInt32: String] = [
            82: "Num 0", 83: "Num 1", 84: "Num 2", 85: "Num 3",
            86: "Num 4", 87: "Num 5", 88: "Num 6", 89: "Num 7",
            91: "Num 8", 92: "Num 9"
        ]

        // Regular number keys
        let numberKeys: [UInt32: String] = [
            29: "0", 18: "1", 19: "2", 20: "3", 21: "4",
            23: "5", 22: "6", 26: "7", 28: "8", 25: "9"
        ]

        // Letter keys
        let letterKeys: [UInt32: String] = [
            0: "A", 11: "B", 8: "C", 2: "D", 14: "E", 3: "F",
            5: "G", 4: "H", 34: "I", 38: "J", 40: "K", 37: "L",
            46: "M", 45: "N", 31: "O", 35: "P", 12: "Q", 15: "R",
            1: "S", 17: "T", 32: "U", 9: "V", 13: "W", 7: "X",
            16: "Y", 6: "Z"
        ]

        // Function keys
        let functionKeys: [UInt32: String] = [
            122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5",
            97: "F6", 98: "F7", 100: "F8", 101: "F9", 109: "F10",
            103: "F11", 111: "F12"
        ]

        // Special keys
        let specialKeys: [UInt32: String] = [
            36: "↩", 48: "⇥", 49: "Space", 51: "⌫",
            53: "⎋", 123: "←", 124: "→", 125: "↓", 126: "↑"
        ]

        if let name = numpadKeys[code] { return name }
        if let name = numberKeys[code] { return name }
        if let name = letterKeys[code] { return name }
        if let name = functionKeys[code] { return name }
        if let name = specialKeys[code] { return name }

        return "Key \(code)"
    }

    static let defaultShortcuts: [String: KeyboardShortcut] = [
        "tileAll": KeyboardShortcut(keyCode: 82, modifiers: UInt32(cmdKey)),
        "maximize": KeyboardShortcut(keyCode: 83, modifiers: UInt32(cmdKey)),
        "halves": KeyboardShortcut(keyCode: 84, modifiers: UInt32(cmdKey)),
        "thirds": KeyboardShortcut(keyCode: 85, modifiers: UInt32(cmdKey)),
        "fourths": KeyboardShortcut(keyCode: 86, modifiers: UInt32(cmdKey)),
        "center": KeyboardShortcut(keyCode: 87, modifiers: UInt32(cmdKey)),
        "sixths": KeyboardShortcut(keyCode: 88, modifiers: UInt32(cmdKey)),
        "almostMax": KeyboardShortcut(keyCode: 89, modifiers: UInt32(cmdKey)),
        "eighths": KeyboardShortcut(keyCode: 91, modifiers: UInt32(cmdKey)),
        "ninths": KeyboardShortcut(keyCode: 92, modifiers: UInt32(cmdKey)),
        "sixteenths": KeyboardShortcut(keyCode: 86, modifiers: UInt32(cmdKey | optionKey))
    ]
}

/// Manages shortcut storage
class ShortcutStorage: ObservableObject {
    static let shared = ShortcutStorage()

    @Published var shortcuts: [String: KeyboardShortcut] = KeyboardShortcut.defaultShortcuts

    private let storageKey = "customShortcuts"

    init() {
        loadShortcuts()
    }

    func loadShortcuts() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([String: KeyboardShortcut].self, from: data) {
            shortcuts = decoded
        } else {
            shortcuts = KeyboardShortcut.defaultShortcuts
        }
    }

    func saveShortcuts() {
        if let encoded = try? JSONEncoder().encode(shortcuts) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
        // Notify hotkey manager to re-register
        NotificationCenter.default.post(name: .shortcutsDidChange, object: nil)
    }

    func resetToDefaults() {
        shortcuts = KeyboardShortcut.defaultShortcuts
        saveShortcuts()
    }
}

extension Notification.Name {
    static let shortcutsDidChange = Notification.Name("shortcutsDidChange")
}

/// NSView that captures keyboard events for recording shortcuts
class ShortcutRecorderView: NSView {
    var onShortcutRecorded: ((UInt32, UInt32) -> Void)?
    var isRecording = false

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        let keyCode = UInt32(event.keyCode)

        // Convert NSEvent modifier flags to Carbon modifiers
        var carbonModifiers: UInt32 = 0
        if event.modifierFlags.contains(.command) { carbonModifiers |= UInt32(cmdKey) }
        if event.modifierFlags.contains(.option) { carbonModifiers |= UInt32(optionKey) }
        if event.modifierFlags.contains(.control) { carbonModifiers |= UInt32(controlKey) }
        if event.modifierFlags.contains(.shift) { carbonModifiers |= UInt32(shiftKey) }

        // Require at least one modifier
        if carbonModifiers != 0 {
            onShortcutRecorded?(keyCode, carbonModifiers)
        }
    }

    override func flagsChanged(with event: NSEvent) {
        // Allow modifier-only detection for visual feedback
        super.flagsChanged(with: event)
    }
}

/// SwiftUI wrapper for shortcut recording
struct ShortcutRecorderRepresentable: NSViewRepresentable {
    @Binding var isRecording: Bool
    var onShortcutRecorded: (UInt32, UInt32) -> Void

    func makeNSView(context: Context) -> ShortcutRecorderView {
        let view = ShortcutRecorderView()
        view.onShortcutRecorded = onShortcutRecorded
        return view
    }

    func updateNSView(_ nsView: ShortcutRecorderView, context: Context) {
        nsView.isRecording = isRecording
        if isRecording {
            DispatchQueue.main.async {
                nsView.window?.makeFirstResponder(nsView)
            }
        }
    }
}

/// A single shortcut editor row
struct ShortcutEditorRow: View {
    let actionName: String
    let actionKey: String
    @ObservedObject var storage: ShortcutStorage
    @State private var isRecording = false
    @State private var tempShortcut: KeyboardShortcut?

    var currentShortcut: KeyboardShortcut {
        storage.shortcuts[actionKey] ?? KeyboardShortcut.defaultShortcuts[actionKey]!
    }

    var body: some View {
        HStack {
            Text(actionName)
                .frame(width: 140, alignment: .leading)

            ZStack {
                // Background for the shortcut display
                RoundedRectangle(cornerRadius: 6)
                    .fill(isRecording ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                    .frame(height: 28)

                if isRecording {
                    HStack {
                        Text(tempShortcut?.displayString ?? "Press keys...")
                            .foregroundColor(.secondary)
                            .font(.system(.body, design: .monospaced))

                        ShortcutRecorderRepresentable(isRecording: $isRecording) { keyCode, modifiers in
                            tempShortcut = KeyboardShortcut(keyCode: keyCode, modifiers: modifiers)
                        }
                        .frame(width: 1, height: 1)
                        .opacity(0)
                    }
                } else {
                    Text(currentShortcut.displayString)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.primary)
                }
            }
            .frame(width: 140)

            if isRecording {
                Button("Save") {
                    if let shortcut = tempShortcut {
                        storage.shortcuts[actionKey] = shortcut
                        storage.saveShortcuts()
                    }
                    isRecording = false
                    tempShortcut = nil
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button("Cancel") {
                    isRecording = false
                    tempShortcut = nil
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else {
                Button("Learn") {
                    isRecording = true
                    tempShortcut = nil
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }
}

/// Full shortcuts editor view
struct ShortcutsEditorView: View {
    @StateObject private var storage = ShortcutStorage.shared

    let actions: [(name: String, key: String)] = [
        ("Tile All (0)", "tileAll"),
        ("Maximize (1)", "maximize"),
        ("Halves (2)", "halves"),
        ("Thirds (3)", "thirds"),
        ("Fourths (4)", "fourths"),
        ("Center (5)", "center"),
        ("Sixths (6)", "sixths"),
        ("Almost Max (7)", "almostMax"),
        ("Eighths (8)", "eighths"),
        ("Ninths (9)", "ninths"),
        ("Sixteenths (⌥4)", "sixteenths")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Customize Shortcuts")
                .font(.headline)

            Text("Click \"Learn\" then press your desired key combination")
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(actions, id: \.key) { action in
                        ShortcutEditorRow(
                            actionName: action.name,
                            actionKey: action.key,
                            storage: storage
                        )
                        Divider()
                    }
                }
            }

            Divider()

            HStack {
                Button("Reset to Defaults") {
                    storage.resetToDefaults()
                }
                .buttonStyle(.bordered)

                Spacer()

                Text("Changes apply immediately")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}
