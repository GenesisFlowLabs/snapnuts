import SwiftUI
import AppKit

/// Visual grid overlay that shows available snap zones
/// Activated by hotkey, dismissed on click or escape
class GridOverlayController {
    static let shared = GridOverlayController()

    private var overlayWindows: [NSWindow] = []
    private var isVisible = false
    private weak var windowManager: WindowManager?

    func setWindowManager(_ manager: WindowManager) {
        self.windowManager = manager
    }

    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }

    func show() {
        guard !isVisible else { return }
        guard let windowManager = windowManager else { return }

        isVisible = true

        // Create overlay for each screen
        for screen in NSScreen.screens {
            let overlayWindow = createOverlayWindow(for: screen, windowManager: windowManager)
            overlayWindows.append(overlayWindow)
            overlayWindow.makeKeyAndOrderFront(nil)
        }
    }

    func hide() {
        isVisible = false
        for window in overlayWindows {
            window.close()
        }
        overlayWindows.removeAll()
    }

    private func createOverlayWindow(for screen: NSScreen, windowManager: WindowManager) -> NSWindow {
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let gridView = GridOverlayView(
            screen: screen,
            windowManager: windowManager,
            onZoneSelected: { [weak self] position in
                self?.hide()
                windowManager.snapToPosition(position, screen: screen)
            },
            onDismiss: { [weak self] in
                self?.hide()
            }
        )

        window.contentView = NSHostingView(rootView: gridView)

        return window
    }
}

/// Grid zone definition for display
struct GridZone: Identifiable {
    let id = UUID()
    let position: WindowPosition
    let label: String
    let shortcut: String
    let rect: CGRect // Normalized 0-1 coordinates

    var frame: CGRect {
        rect
    }
}

/// SwiftUI view for the grid overlay
struct GridOverlayView: View {
    let screen: NSScreen
    let windowManager: WindowManager
    let onZoneSelected: (WindowPosition) -> Void
    let onDismiss: () -> Void

    @State private var hoveredZone: UUID?
    @State private var selectedLayout: GridLayout = .halves

    enum GridLayout: String, CaseIterable {
        case halves = "Halves"
        case thirds = "Thirds"
        case quarters = "Quarters"
        case sixths = "Sixths"
        case ninths = "Ninths"

        var shortcutKey: String {
            switch self {
            case .halves: return "2"
            case .thirds: return "3"
            case .quarters: return "4"
            case .sixths: return "6"
            case .ninths: return "9"
            }
        }
    }

    var zones: [GridZone] {
        switch selectedLayout {
        case .halves:
            return [
                GridZone(position: WindowPosition(0, 0, 0.5, 1), label: "Left", shortcut: "1", rect: CGRect(x: 0, y: 0, width: 0.5, height: 1)),
                GridZone(position: WindowPosition(0.5, 0, 0.5, 1), label: "Right", shortcut: "2", rect: CGRect(x: 0.5, y: 0, width: 0.5, height: 1))
            ]
        case .thirds:
            return [
                GridZone(position: WindowPosition(0, 0, 1.0/3.0, 1), label: "Left", shortcut: "1", rect: CGRect(x: 0, y: 0, width: 1.0/3.0, height: 1)),
                GridZone(position: WindowPosition(1.0/3.0, 0, 1.0/3.0, 1), label: "Center", shortcut: "2", rect: CGRect(x: 1.0/3.0, y: 0, width: 1.0/3.0, height: 1)),
                GridZone(position: WindowPosition(2.0/3.0, 0, 1.0/3.0, 1), label: "Right", shortcut: "3", rect: CGRect(x: 2.0/3.0, y: 0, width: 1.0/3.0, height: 1))
            ]
        case .quarters:
            return [
                // Top row
                GridZone(position: WindowPosition(0, 0, 0.5, 0.5), label: "Top Left", shortcut: "1", rect: CGRect(x: 0, y: 0, width: 0.5, height: 0.5)),
                GridZone(position: WindowPosition(0.5, 0, 0.5, 0.5), label: "Top Right", shortcut: "2", rect: CGRect(x: 0.5, y: 0, width: 0.5, height: 0.5)),
                // Bottom row
                GridZone(position: WindowPosition(0, 0.5, 0.5, 0.5), label: "Bottom Left", shortcut: "3", rect: CGRect(x: 0, y: 0.5, width: 0.5, height: 0.5)),
                GridZone(position: WindowPosition(0.5, 0.5, 0.5, 0.5), label: "Bottom Right", shortcut: "4", rect: CGRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5))
            ]
        case .sixths:
            var zones: [GridZone] = []
            for row in 0..<2 {
                for col in 0..<3 {
                    let x = CGFloat(col) / 3.0
                    let y = CGFloat(row) / 2.0
                    let num = row * 3 + col + 1
                    zones.append(GridZone(
                        position: WindowPosition(x, y, 1.0/3.0, 0.5),
                        label: "\(num)",
                        shortcut: "\(num)",
                        rect: CGRect(x: x, y: y, width: 1.0/3.0, height: 0.5)
                    ))
                }
            }
            return zones
        case .ninths:
            var zones: [GridZone] = []
            for row in 0..<3 {
                for col in 0..<3 {
                    let x = CGFloat(col) / 3.0
                    let y = CGFloat(row) / 3.0
                    let num = row * 3 + col + 1
                    zones.append(GridZone(
                        position: WindowPosition(x, y, 1.0/3.0, 1.0/3.0),
                        label: "\(num)",
                        shortcut: "\(num)",
                        rect: CGRect(x: x, y: y, width: 1.0/3.0, height: 1.0/3.0)
                    ))
                }
            }
            return zones
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Semi-transparent background
                Color.black.opacity(0.3)
                    .onTapGesture {
                        onDismiss()
                    }

                // Grid zones
                ForEach(zones) { zone in
                    ZoneView(
                        zone: zone,
                        isHovered: hoveredZone == zone.id,
                        geometry: geometry
                    )
                    .onHover { hovering in
                        hoveredZone = hovering ? zone.id : nil
                    }
                    .onTapGesture {
                        onZoneSelected(zone.position)
                    }
                }

                // Layout selector at top
                VStack {
                    HStack(spacing: 12) {
                        ForEach(GridLayout.allCases, id: \.self) { layout in
                            LayoutButton(
                                layout: layout,
                                isSelected: selectedLayout == layout,
                                action: { selectedLayout = layout }
                            )
                        }

                        Spacer()

                        // Maximize button
                        Button(action: {
                            onZoneSelected(WindowPosition(0, 0, 1, 1))
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                Text("Max")
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.8))
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)

                        // Close button
                        Button(action: onDismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                    .background(Color.black.opacity(0.5))

                    Spacer()

                    // Instructions at bottom
                    Text("Click a zone to snap • Press ESC to cancel • ⌘+G to toggle")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                        .padding(.bottom, 40)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
        .onAppear {
            // Set up ESC key handler
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.keyCode == 53 { // ESC key
                    onDismiss()
                    return nil
                }
                return event
            }
        }
    }
}

struct ZoneView: View {
    let zone: GridZone
    let isHovered: Bool
    let geometry: GeometryProxy

    var zoneFrame: CGRect {
        CGRect(
            x: zone.frame.origin.x * geometry.size.width,
            y: zone.frame.origin.y * geometry.size.height,
            width: zone.frame.width * geometry.size.width,
            height: zone.frame.height * geometry.size.height
        )
    }

    var body: some View {
        ZStack {
            // Zone background
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.blue.opacity(0.4) : Color.white.opacity(0.1))

            // Zone border
            RoundedRectangle(cornerRadius: 8)
                .stroke(isHovered ? Color.blue : Color.white.opacity(0.5), lineWidth: isHovered ? 3 : 1)

            // Zone label
            VStack(spacing: 4) {
                Text(zone.label)
                    .font(.system(size: isHovered ? 18 : 14, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .frame(width: zoneFrame.width - 8, height: zoneFrame.height - 8)
        .position(x: zoneFrame.midX, y: zoneFrame.midY)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}

struct LayoutButton: View {
    let layout: GridOverlayView.GridLayout
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text("⌘\(layout.shortcutKey)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                Text(layout.rawValue)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color.white.opacity(0.2))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - WindowManager Extension

extension WindowManager {
    /// Snap current window to a specific position on a specific screen
    func snapToPosition(_ position: WindowPosition, screen: NSScreen) {
        guard let window = getFocusedWindow() else {
            alertWindow?.showAlert("No focused window!")
            return
        }

        moveWindowToPosition(window, position: position, screen: screen)
        alertWindow?.showAlert("Snapped!")
    }

    /// Toggle the grid overlay
    func toggleGridOverlay() {
        GridOverlayController.shared.toggle()
    }

    /// Show the grid overlay
    func showGridOverlay() {
        GridOverlayController.shared.show()
    }

    /// Hide the grid overlay
    func hideGridOverlay() {
        GridOverlayController.shared.hide()
    }
}
