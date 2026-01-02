# SnapNuts

## Quick Context
SnapNuts is a free, open source window management system for macOS. The core idea: **the number = the division**. Press Cmd+4 for fourths, Cmd+8 for eighths. The shortcut teaches itself.

**Project Location:** `/Users/shafenkhan/projects/shortcut-content/`

**GitHub (PUBLIC):** https://github.com/GenesisFlowLabs/snapnuts

## Current State (Jan 2, 2026)

The system is COMPLETE and PUBLIC. All shortcuts work with multi-monitor cycling.

### Architecture

| Shortcut | Handler | Multi-Monitor |
|----------|---------|---------------|
| Cmd+0 | Rectangle | No (Tile All) |
| Cmd+1 | Hammerspoon | Yes |
| Cmd+2 | Rectangle | No (Halves) |
| Cmd+3 | Hammerspoon | Yes |
| Cmd+4 | Hammerspoon | Yes (8 positions: fourths + corners) |
| Cmd+5 | Hammerspoon | Yes |
| Cmd+6 | Hammerspoon | Yes |
| Cmd+7 | Hammerspoon | Yes |
| Cmd+8 | Hammerspoon | Yes |
| Cmd+9 | Hammerspoon | Yes |
| Cmd+Option+4 | Hammerspoon | Yes (16 positions: 4x4 grid) |

### Key Files

| File | Purpose |
|------|---------|
| `init.lua` | The Hammerspoon config (this IS the product) |
| `README.md` | Public-facing documentation with install instructions |
| `logo.png` | SnapNuts logo (by Skybehind/Magic Unicorn Tech) |
| `LICENSE` | MIT License |

### Installation (for users)

```bash
brew install --cask rectangle hammerspoon
curl -fsSL https://raw.githubusercontent.com/GenesisFlowLabs/snapnuts/main/init.lua -o ~/.hammerspoon/init.lua
```

### Local Development

The Hammerspoon config lives at `~/.hammerspoon/init.lua`. Edit there, then click the Hammerspoon menu bar icon and Reload Config to test changes. Copy back to repo when done.

## What Was Done This Session

1. Added multi-monitor cycling to ALL Hammerspoon shortcuts (1,3,4,5,6,7,8,9)
2. Added sixteenths (Cmd+Option+4) for 16-position 4x4 grid
3. Migrated most shortcuts from Rectangle to Hammerspoon
4. Created comprehensive README with ASCII diagrams
5. Made repo PUBLIC
6. Added topics: macos, window-management, hammerspoon, rectangle, productivity, numpad, keyboard-shortcuts
7. Softened origin story to properly credit Rectangle
8. Removed emdashes and emojis to avoid AI-written appearance

## Origin

Created December 25, 2025. Filed feature request on Rectangle (#1681), maintainer pointed to Rectangle Pro. Built it ourselves with Hammerspoon. Shared publicly.

"Solve your own problems first, then share what you learn."
