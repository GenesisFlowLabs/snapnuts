import SwiftUI

struct SettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showAlerts") private var showAlerts = true
    @AppStorage("alertDuration") private var alertDuration = 0.5

    var body: some View {
        TabView {
            GeneralSettingsView(
                launchAtLogin: $launchAtLogin,
                showAlerts: $showAlerts,
                alertDuration: $alertDuration
            )
            .tabItem {
                Label("General", systemImage: "gear")
            }

            ShortcutsEditorView()
            .tabItem {
                Label("Shortcuts", systemImage: "keyboard")
            }

            AboutView()
            .tabItem {
                Label("About", systemImage: "info.circle")
            }
        }
        .frame(width: 520, height: 480)
    }
}

struct GeneralSettingsView: View {
    @Binding var launchAtLogin: Bool
    @Binding var showAlerts: Bool
    @Binding var alertDuration: Double

    var body: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .help("Start SnapNuts automatically when you log in")
            } header: {
                Text("Startup")
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
                    if AXIsProcessTrusted() {
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

#Preview {
    SettingsView()
}
