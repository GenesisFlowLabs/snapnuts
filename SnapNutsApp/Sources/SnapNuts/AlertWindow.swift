import AppKit
import SwiftUI

/// Displays temporary alert messages for position feedback
class AlertWindow {
    private var window: NSWindow?
    private var hideTimer: Timer?

    func showAlert(_ message: String, duration: TimeInterval = 0.5) {
        // Use asyncAfter with small delay to avoid SwiftUI/AppKit race conditions
        // when called immediately after batch window operations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.displayAlert(message, duration: duration)
        }
    }

    private func displayAlert(_ message: String, duration: TimeInterval) {
        // Cancel any existing timer
        hideTimer?.invalidate()

        // Get the screen with the focused window or main screen
        let targetScreen = getFocusedWindowScreen() ?? NSScreen.main ?? NSScreen.screens.first!

        // Fixed window size to avoid dynamic resizing race conditions
        let windowSize = NSSize(width: 400, height: 60)

        // Create or reuse window
        if window == nil {
            window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: windowSize.width, height: windowSize.height),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            window?.isOpaque = false
            window?.backgroundColor = .clear
            window?.level = .floating
            window?.collectionBehavior = [.canJoinAllSpaces, .stationary]
            window?.ignoresMouseEvents = true
        }

        // Create content view with fixed frame - avoid dynamic sizing
        let contentView = AlertContentView(message: message)
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = NSRect(origin: .zero, size: windowSize)
        window?.contentView = hostingView
        window?.setContentSize(windowSize)

        // Position at center-top of the target screen
        let screenFrame = targetScreen.frame
        let x = screenFrame.midX - windowSize.width / 2
        let y = screenFrame.maxY - windowSize.height - 100

        window?.setFrameOrigin(NSPoint(x: x, y: y))

        // Show with animation
        window?.alphaValue = 0
        window?.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.1
            window?.animator().alphaValue = 1
        }

        // Schedule hide
        hideTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.hideAlert()
        }
    }

    private func hideAlert() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            window?.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.window?.orderOut(nil)
        })
    }

    private func getFocusedWindowScreen() -> NSScreen? {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            return nil
        }

        let appElement = AXUIElementCreateApplication(frontmostApp.processIdentifier)
        var focusedWindow: CFTypeRef?

        let result = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindow)

        if result == .success, let window = focusedWindow {
            var positionRef: CFTypeRef?
            let posResult = AXUIElementCopyAttributeValue(window as! AXUIElement, kAXPositionAttribute as CFString, &positionRef)

            if posResult == .success, let positionValue = positionRef {
                var position = CGPoint.zero
                AXValueGetValue(positionValue as! AXValue, .cgPoint, &position)

                // Find which screen contains this position
                for screen in NSScreen.screens {
                    if screen.frame.contains(CGPoint(x: position.x + 10, y: position.y + 10)) {
                        return screen
                    }
                }
            }
        }

        return nil
    }
}

/// SwiftUI view for alert content - uses fixed frame to avoid layout race conditions
struct AlertContentView: View {
    let message: String

    var body: some View {
        // Use GeometryReader-free layout with fixed frame to prevent SwiftUI/AppKit conflicts
        Text(message)
            .font(.system(size: 18, weight: .medium, design: .rounded))
            .foregroundColor(.white)
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.75))
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
