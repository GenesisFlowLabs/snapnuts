# SnapNuts

## Quick Context
SnapNuts is a free, open source window management tool for macOS. The core idea: **the number = the division**. Press Cmd+4 for fourths, Cmd+8 for eighths. The shortcut teaches itself.

**Project Location:** `/Users/shafenkhan/projects/snapnuts/`
**GitHub (PUBLIC):** https://github.com/GenesisFlowLabs/snapnuts

## Current State (Feb 1, 2026)

### STATUS: PAUSED - Using Hammerspoon

Swift app development paused due to accessibility permission hassles with ad-hoc signing. Now using **Hammerspoon version** with all features.

**Active config:** `~/.hammerspoon/init.lua` (copied from `init.lua` in this repo)

### What's Working (Hammerspoon)

**Numpad (external keyboard):**

| Shortcut | Action |
|----------|--------|
| Cmd+pad0 | Tile All (current app windows) |
| Cmd+pad1 | Maximize |
| Cmd+pad2 | Halves (left/right) |
| Cmd+pad3 | Thirds |
| Cmd+pad4 | Fourths + Corners (8 positions) |
| Cmd+pad5 | Center (80%) |
| Cmd+pad6 | Sixths (3x2 grid) |
| Cmd+pad7 | Almost Max (90%) |
| Cmd+pad8 | Eighths (4x2 grid) |
| Cmd+pad9 | Ninths (3x3 grid) |
| Cmd+Opt+pad4 | Sixteenths (4x4 grid) |

**Laptop fallback (no numpad):**

| Shortcut | Action |
|----------|--------|
| Cmd+Ctrl+0 | Tile All (current app windows) |
| Cmd+Ctrl+1 | Maximize |
| Cmd+Ctrl+2 | Halves (left/right) |
| Cmd+Ctrl+3 | Thirds |
| Cmd+Ctrl+4 | Fourths + Corners (8 positions) |
| Cmd+Ctrl+5 | Center (80%) |
| Cmd+Ctrl+6 | Sixths (3x2 grid) |
| Cmd+Ctrl+7 | Almost Max (90%) |
| Cmd+Ctrl+8 | Eighths (4x2 grid) |
| Cmd+Ctrl+9 | Ninths (3x3 grid) |
| Cmd+Ctrl+Opt+4 | Sixteenths (4x4 grid) |

**Utilities (both keyboards):**

| Shortcut | Action |
|----------|--------|
| Cmd+Shift+Z | Undo last snap (10 levels) |
| Cmd+Shift+S | Save workspace |
| Cmd+Shift+1-9 | Restore workspace |
| Cmd+Shift+Left | Stash window left |
| Cmd+Shift+Right | Stash window right |
| Cmd+Shift+U | Unstash all |

### Swift-Only Features (NOT in Hammerspoon)

- Cmd+G Grid Overlay (visual click-to-snap)
- Drag-to-snap zones
- Window gaps setting
- Settings UI

## Installation

```bash
# One-time: install Hammerspoon
brew install --cask hammerspoon

# Install/update SnapNuts
cp /Users/shafenkhan/projects/snapnuts/init.lua ~/.hammerspoon/init.lua
# Then: Hammerspoon menu bar → Reload Config
```

## Key Files

| File | Purpose |
|------|---------|
| `init.lua` | **THE PRODUCT** - Hammerspoon config |
| `SnapNutsApp/` | Swift app (paused) |
| `PROJECT-STATUS.md` | Detailed status |
| `NEXT_STEPS.md` | What's next |

## Swift App (Paused)

The Swift app code is preserved but development is paused:
- Screen cycling bug was fixed in `WindowManager.swift` (Jan 25)
- Would need proper code signing for distribution
- Accessibility permission is painful with ad-hoc signing

## History

- **Dec 25, 2025**: Created concept with Hammerspoon
- **Jan 7, 2026**: Converted to Swift app
- **Jan 23, 2026**: Added advanced features
- **Jan 25, 2026**: Fixed Swift bugs, updated Hammerspoon with all features, **paused Swift development**
- **Feb 1, 2026**: Added laptop fallback shortcuts (Cmd+Ctrl+numbers) for MacBooks without numpad

## Credits

| Role | Credit |
|------|--------|
| Created by | Genesis Flow Labs |
| Refined by | Magic Unicorn Tech |
| Logo | Skybehind |
| AI Assistance | Claude (Anthropic) |

---
*"The number = the division."*
