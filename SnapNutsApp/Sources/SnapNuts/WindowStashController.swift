import AppKit
import ApplicationServices

/// Represents a stashed window
struct StashedWindow: Identifiable {
    let id = UUID()
    let windowRef: AXUIElement
    let bundleIdentifier: String
    let appName: String
    let windowTitle: String
    let originalFrame: CGRect
    let stashSide: StashSide
    let screen: NSScreen

    enum StashSide: String {
        case left, right
    }
}

/// Controller for window stashing functionality
/// Hides windows at screen edges with hover-to-reveal
class WindowStashController {
    static let shared = WindowStashController()

    private var stashedWindows: [StashedWindow] = []
    private var tabWindows: [UUID: NSWindow] = [:]
    private var isHovering: [UUID: Bool] = [:]
    private var hoverTrackingAreas: [UUID: NSTrackingArea] = [:]
    private weak var windowManager: WindowManager?

    // Stash settings
    private let tabWidth: CGFloat = 24
    private let tabHeight: CGFloat = 80
    private let peekAmount: CGFloat = 50 // How much of window shows when stashed
    private let revealAnimationDuration: TimeInterval = 0.2

    // Enabled state
    var isEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "windowStashingEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "windowStashingEnabled") }
    }

    private init() {
        // Set default
        if UserDefaults.standard.object(forKey: "windowStashingEnabled") == nil {
            UserDefaults.standard.set(true, forKey: "windowStashingEnabled")
        }
    }

    func setWindowManager(_ manager: WindowManager) {
        self.windowManager = manager
    }

    // MARK: - Stash/Unstash Window

    /// Stashes the currently focused window to the specified side
    func stashFocusedWindow(to side: StashedWindow.StashSide) {
        guard isEnabled else { return }
        guard let frontApp = NSWorkspace.shared.frontmostApplication,
              let bundleId = frontApp.bundleIdentifier,
              let appName = frontApp.localizedName else { return }

        // Get focused window
        let appRef = AXUIElementCreateApplication(frontApp.processIdentifier)

        var focusedWindow: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute as CFString, &focusedWindow) == .success else {
            windowManager?.alertWindow?.showAlert("No focused window")
            return
        }

        let window = focusedWindow as! AXUIElement

        // Get current position and size
        var positionValue: CFTypeRef?
        var sizeValue: CFTypeRef?

        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue) == .success,
              AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue) == .success else {
            return
        }

        var position = CGPoint.zero
        var size = CGSize.zero

        AXValueGetValue(positionValue as! AXValue, .cgPoint, &position)
        AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)

        let originalFrame = CGRect(origin: position, size: size)

        // Get window title
        var titleValue: CFTypeRef?
        AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleValue)
        let windowTitle = titleValue as? String ?? "Untitled"

        // Find which screen the window is on
        guard let screen = NSScreen.screens.first(where: { $0.frame.intersects(originalFrame) }) ?? NSScreen.main else {
            return
        }

        // Check if already stashed
        if let existingIndex = stashedWindows.firstIndex(where: { compareAXElements($0.windowRef, window) }) {
            // Unstash it
            unstashWindow(stashedWindows[existingIndex])
            return
        }

        // Create stashed window record
        let stashedWindow = StashedWindow(
            windowRef: window,
            bundleIdentifier: bundleId,
            appName: appName,
            windowTitle: windowTitle,
            originalFrame: originalFrame,
            stashSide: side,
            screen: screen
        )

        stashedWindows.append(stashedWindow)

        // Move window off-screen
        let stashedPosition: CGPoint
        switch side {
        case .left:
            stashedPosition = CGPoint(
                x: screen.frame.origin.x - size.width + peekAmount,
                y: position.y
            )
        case .right:
            stashedPosition = CGPoint(
                x: screen.frame.maxX - peekAmount,
                y: position.y
            )
        }

        // Animate to stashed position
        animateWindow(window, to: stashedPosition)

        // Create tab indicator
        createTabForStashedWindow(stashedWindow)

        windowManager?.alertWindow?.showAlert("Stashed \(side.rawValue)")
    }

    /// Unstashes a window
    func unstashWindow(_ stashedWindow: StashedWindow) {
        guard let index = stashedWindows.firstIndex(where: { $0.id == stashedWindow.id }) else { return }

        // Move window back to original position
        animateWindow(stashedWindow.windowRef, to: stashedWindow.originalFrame.origin)

        // Remove tab
        if let tabWindow = tabWindows[stashedWindow.id] {
            tabWindow.close()
            tabWindows.removeValue(forKey: stashedWindow.id)
        }

        stashedWindows.remove(at: index)

        windowManager?.alertWindow?.showAlert("Unstashed")
    }

    /// Unstashes all windows
    func unstashAllWindows() {
        let windowsToUnstash = stashedWindows
        for stashedWindow in windowsToUnstash {
            unstashWindow(stashedWindow)
        }
    }

    // MARK: - Tab Creation

    private func createTabForStashedWindow(_ stashedWindow: StashedWindow) {
        let screen = stashedWindow.screen
        let originalY = stashedWindow.originalFrame.origin.y

        // Calculate tab position
        let tabX: CGFloat
        switch stashedWindow.stashSide {
        case .left:
            tabX = screen.frame.origin.x
        case .right:
            tabX = screen.frame.maxX - tabWidth
        }

        // Convert Y coordinate (Accessibility uses screen coords with Y=0 at top)
        let primaryHeight = NSScreen.screens[0].frame.height
        let cocoaY = primaryHeight - originalY - tabHeight

        let tabFrame = CGRect(x: tabX, y: cocoaY, width: tabWidth, height: tabHeight)

        let tabWindow = NSWindow(
            contentRect: tabFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        tabWindow.level = .floating
        tabWindow.isOpaque = false
        tabWindow.backgroundColor = .clear
        tabWindow.ignoresMouseEvents = false
        tabWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Create tab view
        let tabView = StashTabView(
            stashedWindow: stashedWindow,
            onHover: { [weak self] isHovering in
                self?.handleTabHover(stashedWindow: stashedWindow, isHovering: isHovering)
            },
            onClick: { [weak self] in
                self?.unstashWindow(stashedWindow)
            }
        )

        tabWindow.contentView = NSHostingView(rootView: tabView)
        tabWindow.orderFront(nil)

        tabWindows[stashedWindow.id] = tabWindow
    }

    // MARK: - Hover Handling

    private func handleTabHover(stashedWindow: StashedWindow, isHovering: Bool) {
        self.isHovering[stashedWindow.id] = isHovering

        if isHovering {
            // Reveal window
            revealStashedWindow(stashedWindow)
        } else {
            // Hide window again after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self else { return }
                if self.isHovering[stashedWindow.id] != true {
                    self.hideStashedWindow(stashedWindow)
                }
            }
        }
    }

    private func revealStashedWindow(_ stashedWindow: StashedWindow) {
        let screen = stashedWindow.screen
        let size = stashedWindow.originalFrame.size

        // Calculate revealed position (still at edge but visible)
        let revealedPosition: CGPoint
        switch stashedWindow.stashSide {
        case .left:
            revealedPosition = CGPoint(
                x: screen.frame.origin.x,
                y: stashedWindow.originalFrame.origin.y
            )
        case .right:
            revealedPosition = CGPoint(
                x: screen.frame.maxX - size.width,
                y: stashedWindow.originalFrame.origin.y
            )
        }

        animateWindow(stashedWindow.windowRef, to: revealedPosition)
    }

    private func hideStashedWindow(_ stashedWindow: StashedWindow) {
        guard stashedWindows.contains(where: { $0.id == stashedWindow.id }) else { return }

        let screen = stashedWindow.screen
        let size = stashedWindow.originalFrame.size

        // Calculate stashed position
        let stashedPosition: CGPoint
        switch stashedWindow.stashSide {
        case .left:
            stashedPosition = CGPoint(
                x: screen.frame.origin.x - size.width + peekAmount,
                y: stashedWindow.originalFrame.origin.y
            )
        case .right:
            stashedPosition = CGPoint(
                x: screen.frame.maxX - peekAmount,
                y: stashedWindow.originalFrame.origin.y
            )
        }

        animateWindow(stashedWindow.windowRef, to: stashedPosition)
    }

    // MARK: - Window Animation

    private func animateWindow(_ window: AXUIElement, to position: CGPoint) {
        // AXUIElement doesn't support animation directly, so we just set the position
        var pos = position
        let positionValue = AXValueCreate(.cgPoint, &pos)!
        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
    }

    // MARK: - Utility

    private func compareAXElements(_ a: AXUIElement, _ b: AXUIElement) -> Bool {
        // Compare by getting window IDs or positions
        var aPos: CFTypeRef?
        var bPos: CFTypeRef?

        guard AXUIElementCopyAttributeValue(a, kAXPositionAttribute as CFString, &aPos) == .success,
              AXUIElementCopyAttributeValue(b, kAXPositionAttribute as CFString, &bPos) == .success else {
            return false
        }

        var aPosValue = CGPoint.zero
        var bPosValue = CGPoint.zero

        AXValueGetValue(aPos as! AXValue, .cgPoint, &aPosValue)
        AXValueGetValue(bPos as! AXValue, .cgPoint, &bPosValue)

        return aPosValue == bPosValue
    }

    // MARK: - Public Accessors

    var stashedWindowCount: Int {
        return stashedWindows.count
    }

    func getStashedWindows() -> [StashedWindow] {
        return stashedWindows
    }
}

// MARK: - SwiftUI Tab View

import SwiftUI

struct StashTabView: View {
    let stashedWindow: StashedWindow
    let onHover: (Bool) -> Void
    let onClick: () -> Void

    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 4) {
            // App icon
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: stashedWindow.bundleIdentifier) {
                let icon = NSWorkspace.shared.icon(forFile: appURL.path)
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 16, height: 16)
            }

            // Side indicator
            Image(systemName: stashedWindow.stashSide == .left ? "chevron.right" : "chevron.left")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: 24, height: 80)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isHovered ? Color.blue : Color.black.opacity(0.7))
        )
        .onHover { hovering in
            isHovered = hovering
            onHover(hovering)
        }
        .onTapGesture {
            onClick()
        }
    }
}

// MARK: - NSHostingView wrapper for SwiftUI

class NSHostingView<Content: View>: NSView {
    private var hostingController: NSHostingController<Content>

    init(rootView: Content) {
        hostingController = NSHostingController(rootView: rootView)
        super.init(frame: .zero)

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
