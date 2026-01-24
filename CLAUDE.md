# SnapNuts

## Quick Context
SnapNuts is a free, open source window management app for macOS. The core idea: **the number = the division**. Press Cmd+4 for fourths, Cmd+8 for eighths. The shortcut teaches itself.

**Project Location:** `/Users/shafenkhan/projects/snapnuts/`

**GitHub (PUBLIC):** https://github.com/GenesisFlowLabs/snapnuts

## Current State (Jan 23, 2026)

Native macOS app built with Swift/SwiftUI. Fully functional with advanced features including visual grid overlay, workspace layouts, drag-to-snap zones, and window stashing.

### Architecture

The app is a standalone native macOS menu bar application:

```
SnapNutsApp/
├── Package.swift              # Swift Package Manager config
├── build.sh                   # Build script (auto-installs to /Applications)
├── Frameworks/
│   └── Sparkle.framework      # Auto-update framework
├── Resources/
│   ├── AppIcon.appiconset/    # App icons (all sizes)
│   ├── StatusBarIcon.png      # Menu bar icon
│   └── StatusBarIcon@2x.png
└── Sources/SnapNuts/
    ├── SnapNutsApp.swift      # Main app entry point
    ├── WindowManager.swift    # Window positioning logic (Accessibility API)
    ├── HotkeyManager.swift    # Global keyboard shortcuts (Carbon Events)
    ├── SettingsView.swift     # SwiftUI settings UI with tabs
    ├── ShortcutRecorder.swift # "Learn" feature for custom shortcuts
    ├── AlertWindow.swift      # Visual feedback overlay
    ├── OnboardingView.swift   # First-run welcome screen
    ├── GridOverlay.swift      # Visual grid overlay for click-to-snap
    ├── WorkspaceManager.swift # Save/restore window arrangements
    ├── DragSnapController.swift    # Drag-to-edge snapping
    ├── WindowStashController.swift # Hide windows at screen edges
    ├── Info.plist             # App metadata
    └── SnapNuts.entitlements  # Accessibility permissions
```

### Tech Stack

| Component | Technology |
|-----------|------------|
| UI Framework | SwiftUI |
| Window Management | AppKit + Accessibility API (AXUIElement) |
| Hotkey Registration | Carbon Event Manager |
| Mouse Event Monitoring | CGEventTap (for drag-to-snap) |
| Settings Storage | UserDefaults + JSON (for workspaces) |
| Auto-Updates | Sparkle Framework |
| Distribution | DMG installer, auto-install to /Applications |

### Shortcuts

#### Window Divisions (the number = the division)

| Shortcut | Division | Positions |
|:--------:|:--------:|:----------|
| Cmd + 0 | Tile All | Organizes all visible windows |
| Cmd + 1 | Maximize | Full screen, cycles monitors |
| Cmd + 2 | Halves | Left / Right |
| Cmd + 3 | Thirds | Left / Center / Right |
| Cmd + 4 | Fourths | 4 strips + 4 corners (8 total) |
| Cmd + 5 | Center | 80% centered |
| Cmd + 6 | Sixths | 3x2 grid |
| Cmd + 7 | Almost Max | 90% centered |
| Cmd + 8 | Eighths | 4x2 grid |
| Cmd + 9 | Ninths | 3x3 grid |
| Cmd + Opt + 4 | Sixteenths | 4x4 grid |

**No numpad?** Use `Cmd + Ctrl + Number` instead (e.g., `Cmd + Ctrl + 3` for thirds).

#### Advanced Features

| Shortcut | Action | Description |
|:--------:|:------:|:------------|
| Cmd + G | Grid Overlay | Shows visual grid, click to snap |
| Cmd + Shift + S | Save Workspace | Save current window arrangement |
| Cmd + Shift + 1-9 | Restore Workspace | Restore saved layout |
| Cmd + Shift + ← | Stash Left | Hide window at left edge |
| Cmd + Shift + → | Stash Right | Hide window at right edge |
| Cmd + Shift + U | Unstash All | Reveal all stashed windows |
| Cmd + Shift + Z | Undo | Undo last window snap (10 levels) |

### Building

```bash
cd SnapNutsApp
./build.sh
# Automatically installs to /Applications/SnapNuts.app
open /Applications/SnapNuts.app
```

### Settings (General Tab)

| Setting | Description |
|---------|-------------|
| Launch at Login | Start automatically when you log in |
| Drag to Screen Edge | Snap windows by dragging to edges |
| Window Stashing | Enable stash shortcuts (Cmd+Shift+←/→) |
| Window Gap | Spacing between snapped windows (0-16px) |
| Show Position Alerts | Display feedback when snapping |
| Alert Duration | How long alerts are visible (0.2-2.0s) |

## Project History

### Phase 1: Concept & Hammerspoon (Dec 25, 2025)
- **Creator:** Shafen Khan / Genesis Flow Labs
- **AI Assistance:** Claude (Anthropic)
- Filed feature request on Rectangle (#1681), maintainer pointed to Rectangle Pro
- Built proof-of-concept using Hammerspoon + Rectangle
- Core insight: "the number = the division"

### Phase 2: Native Swift App (Jan 7, 2026)
- **Developer:** Aaron / Magic Unicorn Tech
- **AI Assistance:** Claude (Anthropic)
- Converted Hammerspoon config to standalone native macOS app
- Added SwiftUI settings UI with customizable shortcuts
- Added "Learn" feature to record custom key combinations
- Added visual feedback alerts

### Phase 3: Advanced Features (Jan 23, 2026)
- **AI Assistance:** Claude Opus 4.5 (Anthropic)
- **Visual Grid Overlay** - Click-to-snap interface (Cmd+G)
- **Workspace Layouts** - Save/restore window arrangements (Cmd+Shift+S, Cmd+Shift+1-9)
- **Drag-to-Snap Zones** - Drag windows to screen edges with preview
- **Window Stashing** - Hide windows at screen edges with hover-to-reveal
- **Undo System** - 10-level undo history (Cmd+Shift+Z)
- **Window Gaps** - Configurable spacing between windows (0-16px)
- **Sparkle Auto-Updates** - Automatic update checking
- Fixed multi-monitor window sizing issues

## AI Transparency

This project was built with significant AI assistance. We believe in being transparent about this:

- **Concept & Direction:** Human (Shafen Khan)
- **Code Generation:** Claude (Anthropic) - both Hammerspoon and Swift versions
- **Refinement & Native App:** Human (Aaron) + Claude

This is "vibe-coded" software - the humans provided the vision, problem definition, and guidance while AI assisted with implementation. We're proud of what we built together and believe in honest attribution.

## Credits

| Role | Credit |
|------|--------|
| Created by | Genesis Flow Labs |
| Refined by | Magic Unicorn Tech |
| Logo | Skybehind |
| AI Assistance | Claude (Anthropic) |

## Origin Story

"Solve your own problems first, then share what you learn."

Created December 25, 2025 when Shafen wanted numpad-based window management. Rectangle couldn't do it natively, so we built it ourselves - first with Hammerspoon, then as a proper native app. Now it's free for everyone.
