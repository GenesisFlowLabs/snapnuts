# SnapNuts - Project Status

**Last Updated:** January 25, 2026
**Status:** PAUSED - Using Hammerspoon version, Swift app on hold

---

## Current State (Jan 25, 2026)

### Decision: Back to Hammerspoon

The Swift app had persistent issues with accessibility permissions (ad-hoc signing requires re-granting permission after each rebuild). Rather than fighting this, we've updated the Hammerspoon `init.lua` with all the features from the Swift app and are using that instead.

**Active config:** `~/.hammerspoon/init.lua` (copied from this repo's `init.lua`)

### What's Working (Hammerspoon)

| Shortcut | Action |
|----------|--------|
| Cmd+0 | Tile All Windows |
| Cmd+1 | Maximize |
| Cmd+2 | Halves (left/right) |
| Cmd+3 | Thirds |
| Cmd+4 | Fourths + Corners (8 positions) |
| Cmd+5 | Center (80%) |
| Cmd+6 | Sixths (3x2 grid) |
| Cmd+7 | Almost Max (90%) |
| Cmd+8 | Eighths (4x2 grid) |
| Cmd+9 | Ninths (3x3 grid) |
| Cmd+Opt+4 | Sixteenths (4x4 grid) |
| Cmd+Shift+Z | Undo last snap (10 levels) |
| Cmd+Shift+S | Save workspace (chooser for slot 1-9) |
| Cmd+Shift+1-9 | Restore workspace |
| Cmd+Shift+Left | Stash window left |
| Cmd+Shift+Right | Stash window right |
| Cmd+Shift+U | Unstash all windows |

### Swift App Features NOT in Hammerspoon

These are paused/skipped for now:
- **Cmd+G Grid Overlay** - Visual click-to-snap interface
- **Drag-to-snap zones** - Drag windows to screen edges
- **Window gaps** - Configurable spacing between windows
- **Settings UI** - Native macOS preferences panel

---

## Swift App Status

The Swift app code is preserved in `SnapNutsApp/` but development is paused due to:
1. Accessibility permission hassle with ad-hoc signing
2. Screen cycling bug was fixed but not tested
3. Hammerspoon provides same core functionality without the friction

### If Resuming Swift Development

1. The screen cycling bug fix is in `WindowManager.swift` (Jan 25, 2026)
2. Would need proper code signing for distribution
3. Consider using Sparkle for auto-updates
4. The website at genesisflowlabs.com/snapnuts may need updating

---

## Installation (Hammerspoon)

```bash
# One-time setup
brew install --cask hammerspoon

# Install/update SnapNuts config
cp /Users/shafenkhan/projects/snapnuts/init.lua ~/.hammerspoon/init.lua
```

Then reload Hammerspoon (menu bar icon → Reload Config).

---

## Files

| File | Purpose |
|------|---------|
| `init.lua` | **THE PRODUCT** - Hammerspoon config with all shortcuts |
| `SnapNutsApp/` | Swift app (paused) |
| `website/` | Product page (may need update) |
| `README.md` | Public documentation |
| `CLAUDE.md` | AI context |

---

## History

- **Dec 25, 2025**: Created concept, built Hammerspoon proof-of-concept
- **Jan 7, 2026**: Converted to native Swift app
- **Jan 23, 2026**: Added advanced features (grid, workspaces, stashing, undo)
- **Jan 25, 2026**: Fixed Swift screen cycling bug, updated Hammerspoon with all features, **paused Swift development**

---

*"The number = the division."*
