# SnapNuts

## Quick Context
SnapNuts is a free, open source window management app for macOS. The core idea: **the number = the division**. Press Cmd+4 for fourths, Cmd+8 for eighths. The shortcut teaches itself.

**Project Location:** `/Users/shafenkhan/projects/snapnuts/`

**GitHub (PUBLIC):** https://github.com/GenesisFlowLabs/snapnuts

## Current State (Jan 7, 2026)

Native macOS app built with Swift/SwiftUI. Fully functional, publicly released.

### Architecture

The app is a standalone native macOS menu bar application:

```
SnapNutsApp/
├── Package.swift              # Swift Package Manager config
├── build.sh                   # Build script
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
    ├── Info.plist             # App metadata
    └── SnapNuts.entitlements  # Accessibility permissions
```

### Tech Stack

| Component | Technology |
|-----------|------------|
| UI Framework | SwiftUI |
| Window Management | AppKit + Accessibility API (AXUIElement) |
| Hotkey Registration | Carbon Event Manager |
| Settings Storage | UserDefaults |
| Distribution | DMG installer |

### Shortcuts

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

### Building

```bash
cd SnapNutsApp
./build.sh
open build/SnapNuts.app
```

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
