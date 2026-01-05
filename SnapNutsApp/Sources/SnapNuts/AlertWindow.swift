import AppKit
import SwiftUI

/// Displays temporary alert messages for position feedback
class AlertWindow {
    private var window: NSWindow?
    private var hideTimer: Timer?

    func showAlert(_ message: String, duration: TimeInterval = 0.5) {
        DispatchQueue.main.async { [weak self] in
            self?.displayAlert(message, duration: duration)
        }
    }

    private func displayAlert(_ message: String, duration: TimeInterval) {
        // Cancel any existing timer
        hideTimer?.invalidate()

        // Get the screen with the focused window or main screen
        let targetScreen = getFocusedWindowScreen() ?? NSScreen.main ?? NSScreen.screens.first!

        // Create or reuse window
        if window == nil {
            window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 300, height: 60),
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

        // Create content view
        let contentView = AlertContentView(message: message)
        window?.contentView = NSHostingView(rootView: contentView)

        // Size to fit content
        let hostingView = window?.contentView as? NSHostingView<AlertContentView>
        hostingView?.frame.size = hostingView?.fittingSize ?? NSSize(width: 300, height: 60)
        window?.setContentSize(hostingView?.fittingSize ?? NSSize(width: 300, height: 60))

        // Position at center-top of the target screen
        let screenFrame = targetScreen.frame
        let windowSize = window?.frame.size ?? NSSize(width: 300, height: 60)
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

/// SwiftUI view for alert content
struct AlertContentView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 18, weight: .medium, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.75))
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
            )
    }
}
