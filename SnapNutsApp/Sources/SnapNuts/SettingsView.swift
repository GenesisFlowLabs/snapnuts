import SwiftUI

struct SettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showAlerts") private var showAlerts = true
    @AppStorage("alertDuration") private var alertDuration = 0.5
    @State private var hasAccessibility = AXIsProcessTrusted()

    // Check permission every 2 seconds for responsive feedback
    let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            // Permission warning banner - always reserve space to avoid window resize
            if !hasAccessibility {
                PermissionBanner()
            }

            TabView {
                GeneralSettingsView(
                    launchAtLogin: $launchAtLogin,
                    showAlerts: $showAlerts,
                    alertDuration: $alertDuration,
                    hasAccessibility: $hasAccessibility
                )
                .tabItem {
                    Label("General", systemImage: "gear")
                }

                ShortcutsEditorView()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }

                WorkspacesSettingsView()
                .tabItem {
                    Label("Workspaces", systemImage: "rectangle.3.group")
                }

                AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
            }
        }
        // Fixed frame size - never resize window dynamically to avoid SwiftUI/AppKit race conditions
        .frame(width: 520, height: 500)
        .onReceive(timer) { _ in
            // Only update if value actually changed to minimize UI updates
            let newValue = AXIsProcessTrusted()
            if newValue != hasAccessibility {
                hasAccessibility = newValue
            }
        }
    }
}

struct PermissionBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 2) {
                Text("Accessibility Permission Required")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("SnapNuts needs permission to manage windows")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
            }

            Spacer()

            Button("Grant Access") {
                let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                NSWorkspace.shared.open(url)
            }
            .buttonStyle(.bordered)
            .tint(.white)
        }
        .padding()
        .background(Color.orange)
    }
}

struct GeneralSettingsView: View {
    @Binding var launchAtLogin: Bool
    @Binding var showAlerts: Bool
    @Binding var alertDuration: Double
    @Binding var hasAccessibility: Bool
    @AppStorage("dragToSnapEnabled") private var dragToSnapEnabled = true
    @AppStorage("windowStashingEnabled") private var windowStashingEnabled = true
    @AppStorage("windowGap") private var windowGap: Int = 0

    var body: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .help("Start SnapNuts automatically when you log in")
            } header: {
                Text("Startup")
            }

            Section {
                Toggle("Drag to Screen Edge", isOn: $dragToSnapEnabled)
                    .help("Snap windows by dragging them to screen edges")
                    .onChange(of: dragToSnapEnabled) { newValue in
                        if newValue {
                            DragSnapController.shared.start()
                        } else {
                            DragSnapController.shared.stop()
                        }
                    }

                Toggle("Window Stashing", isOn: $windowStashingEnabled)
                    .help("Stash windows at screen edges with ⌘⇧← / ⌘⇧→")
            } header: {
                Text("Advanced Features")
            }

            Section {
                Picker("Window Gap", selection: $windowGap) {
                    Text("None").tag(0)
                    Text("Small (4px)").tag(4)
                    Text("Medium (8px)").tag(8)
                    Text("Large (12px)").tag(12)
                    Text("Extra Large (16px)").tag(16)
                }
                .help("Add spacing between snapped windows")
            } header: {
                Text("Appearance")
            }

            Section {
                Toggle("Show Position Alerts", isOn: $showAlerts)
                    .help("Display feedback when snapping windows")

                if showAlerts {
                    Slider(value: $alertDuration, in: 0.2...2.0, step: 0.1) {
                        Text("Alert Duration")
                    }
                    Text("\(alertDuration, specifier: "%.1f") seconds")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            } header: {
                Text("Feedback")
            }

            Section {
                HStack {
                    Text("Accessibility")
                    Spacer()
                    if hasAccessibility {
                        Label("Enabled", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Button("Grant Access") {
                            openAccessibilitySettings()
                        }
                    }
                }
            } header: {
                Text("Permissions")
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}

struct ShortcutsReferenceView: View {
    let shortcuts: [(key: String, description: String, positions: String)] = [
        ("⌘ + 0", "Tile All Windows", "-"),
        ("⌘ + 1", "Maximize", "1 position, cycles monitors"),
        ("⌘ + 2", "Halves", "Left ↔ Right"),
        ("⌘ + 3", "Thirds", "Left → Center → Right"),
        ("⌘ + 4", "Fourths + Corners", "4 strips + 4 corners"),
        ("⌘ + 5", "Center", "80% centered"),
        ("⌘ + 6", "Sixths", "3×2 grid"),
        ("⌘ + 7", "Almost Maximize", "90% centered"),
        ("⌘ + 8", "Eighths", "4×2 grid"),
        ("⌘ + 9", "Ninths", "3×3 grid"),
        ("⌘ + ⌥ + 4", "Sixteenths", "4×4 grid")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("The number = the division")
                .font(.headline)
                .foregroundColor(.secondary)

            List(shortcuts, id: \.key) { shortcut in
                HStack {
                    Text(shortcut.key)
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 100, alignment: .leading)

                    VStack(alignment: .leading) {
                        Text(shortcut.description)
                            .fontWeight(.medium)
                        Text(shortcut.positions)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Text("For keyboards without a numpad, use ⌘ + ⌃ + Number")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct WorkspacesSettingsView: View {
    @ObservedObject var workspaceManager = WorkspaceManager.shared
    @State private var showingSaveSheet = false
    @State private var newLayoutName = ""
    @State private var selectedSlot: Int = 0

    var body: some View {
        VStack(spacing: 16) {
            // Header with instructions
            VStack(spacing: 8) {
                Text("Workspace Layouts")
                    .font(.headline)

                Text("Save and restore window arrangements with shortcuts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top)

            // Shortcut hint
            HStack(spacing: 16) {
                Label("⌘⇧S", systemImage: "square.and.arrow.down")
                    .font(.system(.caption, design: .monospaced))
                Text("Save current layout")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Label("⌘⇧1-9", systemImage: "rectangle.3.group")
                    .font(.system(.caption, design: .monospaced))
                Text("Restore layout")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)

            // Layout list
            if workspaceManager.layouts.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "rectangle.3.group")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.5))

                    Text("No saved layouts")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("Press ⌘⇧S or click 'Save Current Layout' to create one")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                List {
                    ForEach(workspaceManager.layouts) { layout in
                        WorkspaceLayoutRow(layout: layout)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            workspaceManager.deleteLayout(workspaceManager.layouts[index])
                        }
                    }
                }
            }

            // Action buttons
            HStack {
                Button(action: {
                    showingSaveSheet = true
                }) {
                    Label("Save Current Layout", systemImage: "plus")
                }

                Spacer()

                if !workspaceManager.layouts.isEmpty {
                    Button(action: {
                        // Clear all layouts
                        for layout in workspaceManager.layouts {
                            workspaceManager.deleteLayout(layout)
                        }
                    }) {
                        Label("Clear All", systemImage: "trash")
                    }
                    .foregroundColor(.red)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingSaveSheet) {
            SaveLayoutSheet(
                isPresented: $showingSaveSheet,
                layoutName: $newLayoutName,
                selectedSlot: $selectedSlot,
                onSave: {
                    let slot = selectedSlot > 0 ? selectedSlot : nil
                    workspaceManager.saveCurrentLayout(name: newLayoutName.isEmpty ? "Workspace" : newLayoutName, shortcutSlot: slot)
                    newLayoutName = ""
                    selectedSlot = 0
                }
            )
        }
    }
}

struct WorkspaceLayoutRow: View {
    let layout: WorkspaceLayout
    @ObservedObject var workspaceManager = WorkspaceManager.shared
    @State private var isEditing = false
    @State private var editedName = ""

    var body: some View {
        HStack {
            // Shortcut badge
            if let slot = layout.shortcutSlot {
                Text("⌘⇧\(slot)")
                    .font(.system(.caption, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
            } else {
                Text("   -   ")
                    .font(.system(.caption, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }

            // Layout name and info
            VStack(alignment: .leading, spacing: 2) {
                if isEditing {
                    TextField("Layout name", text: $editedName, onCommit: {
                        workspaceManager.renameLayout(layout, to: editedName)
                        isEditing = false
                    })
                    .textFieldStyle(.plain)
                    .font(.headline)
                } else {
                    Text(layout.name)
                        .font(.headline)
                }

                Text("\(layout.windows.count) windows • Created \(layout.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Actions
            Button(action: {
                _ = workspaceManager.restoreLayout(layout)
            }) {
                Image(systemName: "arrow.uturn.backward")
            }
            .buttonStyle(.borderless)
            .help("Restore this layout")

            Button(action: {
                workspaceManager.updateLayout(layout)
            }) {
                Image(systemName: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(.borderless)
            .help("Update with current windows")

            Menu {
                ForEach(0..<10) { slot in
                    Button(action: {
                        workspaceManager.assignShortcut(layout, slot: slot == 0 ? nil : slot)
                    }) {
                        if slot == 0 {
                            Text("No shortcut")
                        } else {
                            Text("⌘⇧\(slot)")
                        }
                        if layout.shortcutSlot == slot || (slot == 0 && layout.shortcutSlot == nil) {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            } label: {
                Image(systemName: "keyboard")
            }
            .menuStyle(.borderlessButton)
            .frame(width: 30)
            .help("Assign shortcut")

            Button(action: {
                editedName = layout.name
                isEditing = true
            }) {
                Image(systemName: "pencil")
            }
            .buttonStyle(.borderless)
            .help("Rename")
        }
        .padding(.vertical, 4)
    }
}

struct SaveLayoutSheet: View {
    @Binding var isPresented: Bool
    @Binding var layoutName: String
    @Binding var selectedSlot: Int
    let onSave: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Save Workspace Layout")
                .font(.headline)

            TextField("Layout Name", text: $layoutName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 250)

            Picker("Shortcut", selection: $selectedSlot) {
                Text("No shortcut").tag(0)
                ForEach(1..<10) { slot in
                    let existing = WorkspaceManager.shared.layoutForSlot(slot)
                    if let layout = existing {
                        Text("⌘⇧\(slot) (replaces \(layout.name))").tag(slot)
                    } else {
                        Text("⌘⇧\(slot)").tag(slot)
                    }
                }
            }
            .frame(width: 250)

            HStack(spacing: 20) {
                Button("Cancel") {
                    isPresented = false
                }

                Button("Save") {
                    onSave()
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(30)
        .frame(width: 350)
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 100, height: 100)

            Text("SnapNuts")
                .font(.title)
                .fontWeight(.bold)

            Text("The number = the division")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Version 1.0.0")
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()
                .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 12) {
                AboutRow(label: "Created by", value: "Genesis Flow Labs", url: "https://genesisflowlabs.com")
                AboutRow(label: "Refined by", value: "Magic Unicorn Tech", url: "https://magicunicorn.tech")
                AboutRow(label: "Logo by", value: "Skybehind", url: "https://github.com/skybehind")
                AboutRow(label: "Built with", value: "Claude (Anthropic)", url: "https://claude.ai")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 40)

            Spacer()

            Link("View on GitHub", destination: URL(string: "https://github.com/GenesisFlowLabs/snapnuts")!)
                .font(.caption)

            Text("MIT License")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct AboutRow: View {
    let label: String
    let value: String
    let url: String?

    init(label: String, value: String, url: String? = nil) {
        self.label = label
        self.value = value
        self.url = url
    }

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .trailing)
            if let url = url, let linkURL = URL(string: url) {
                Link(value, destination: linkURL)
            } else {
                Text(value)
            }
        }
        .font(.caption)
    }
}

#if DEBUG && canImport(PreviewsMacros)
#Preview {
    SettingsView()
}
#endif
