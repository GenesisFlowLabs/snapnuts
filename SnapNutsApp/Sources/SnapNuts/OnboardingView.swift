import SwiftUI
import AppKit

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var hasAccessibility = AXIsProcessTrusted()
    var onComplete: () -> Void

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 80, height: 80)

                Text("Welcome to SnapNuts")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Window management made simple")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 30)
            .padding(.bottom, 20)

            Divider()

            // Content
            TabView(selection: $currentPage) {
                IntroPage()
                    .tag(0)

                PermissionPage(hasAccessibility: $hasAccessibility)
                    .tag(1)

                ReadyPage(hasAccessibility: hasAccessibility, onComplete: onComplete)
                    .tag(2)
            }
            .tabViewStyle(.automatic)
            .frame(height: 280)

            Divider()

            // Navigation
            HStack {
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<3) { page in
                        Circle()
                            .fill(page == currentPage ? Color.accentColor : Color.secondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }

                Spacer()

                if currentPage < 2 {
                    Button("Next") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(hasAccessibility ? "Get Started" : "Skip for Now") {
                        onComplete()
                    }
                    .buttonStyle(.borderedProminent)
                    // Always allow clicking - "Skip for Now" should work without permission
                }
            }
            .padding()
        }
        .frame(width: 500, height: 520)
        .onReceive(timer) { _ in
            // Check permission status periodically
            hasAccessibility = AXIsProcessTrusted()
        }
    }
}

struct IntroPage: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("The number = the division")
                .font(.title2)
                .fontWeight(.semibold)

            Text("SnapNuts uses a simple, intuitive system:\nPress ⌘ + a number to divide your screen.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                ShortcutRow(shortcut: "⌘ + 2", description: "Halves", detail: "Left ↔ Right")
                ShortcutRow(shortcut: "⌘ + 4", description: "Fourths", detail: "Strips + Corners")
                ShortcutRow(shortcut: "⌘ + 6", description: "Sixths", detail: "3×2 Grid")
                ShortcutRow(shortcut: "⌘ + 9", description: "Ninths", detail: "3×3 Grid")
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)

            Text("Press the shortcut multiple times to cycle through positions")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("No numpad? Use ⌘ + ⌃ + Number instead")
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
        }
        .padding()
    }
}

struct ShortcutRow: View {
    let shortcut: String
    let description: String
    let detail: String

    var body: some View {
        HStack {
            Text(shortcut)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
                .frame(width: 70, alignment: .leading)

            Text(description)
                .fontWeight(.medium)

            Spacer()

            Text(detail)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct PermissionPage: View {
    @Binding var hasAccessibility: Bool

    var body: some View {
        VStack(spacing: 20) {
            if hasAccessibility {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.green)

                Text("Permission Granted!")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("SnapNuts can now manage your windows.\nYou're all set!")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "lock.shield")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)

                Text("Accessibility Permission Required")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("SnapNuts needs Accessibility permission to move and resize windows. This is a one-time setup.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                VStack(spacing: 12) {
                    Button(action: openAccessibilitySettings) {
                        HStack {
                            Image(systemName: "gear")
                            Text("Open System Settings")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Find **SnapNuts** in the list", systemImage: "1.circle")
                        Label("Toggle it **ON**", systemImage: "2.circle")
                        Label("Return here - we'll detect it automatically", systemImage: "3.circle")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
    }

    private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}

struct ReadyPage: View {
    let hasAccessibility: Bool
    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            if hasAccessibility {
                Image(systemName: "sparkles")
                    .font(.system(size: 50))
                    .foregroundColor(.accentColor)

                Text("You're Ready!")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("SnapNuts is now running in your menu bar.\nTry pressing ⌘ + 2 on any window!")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Label("Access settings from the menu bar icon", systemImage: "menubar.rectangle")
                    Label("Customize shortcuts in Settings", systemImage: "keyboard")
                    Label("Check out all positions in the Shortcuts menu", systemImage: "square.grid.3x3")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
            } else {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)

                Text("Permission Not Granted")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("SnapNuts won't be able to manage windows without Accessibility permission. Please go back and grant access.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                Text("You can also grant permission later from Settings.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}
