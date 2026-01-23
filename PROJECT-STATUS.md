# SnapNuts - Project Status

**Last Updated:** January 22, 2026
**Status:** ACTIVE - Native Swift app, investigating crash

---

## Latest Update (Jan 22, 2026)

### Crash Investigation

**Crash Date:** 2026-01-22 23:02 CST
**Uptime Before Crash:** ~3 days (launched Jan 19)

**Root Cause:** SwiftUI/AppKit window layout race condition

In `SettingsView.swift`, a 1-second timer constantly checks accessibility permission:
```swift
.frame(width: 520, height: hasAccessibility ? 480 : 540)
.onReceive(timer) { _ in
    hasAccessibility = AXIsProcessTrusted()
}
```

When `hasAccessibility` changes, the window height jumps 60px. After running for days, this triggered a race condition:
1. Timer fires, state changes
2. SwiftUI requests frame resize
3. AppKit display cycle updates constraints
4. `NSHostingView.invalidateSafeAreaInsets()` conflicts with resize
5. `SIGABRT` - exception during layout

**Fix Required:**
- Remove dynamic frame sizing tied to rapid state changes
- Use fixed frame or animate changes more carefully
- Reduce timer frequency or remove unnecessary polling

---

## Previous Update (Jan 2, 2026)

### What Got Done This Session
- [x] Added multi-monitor cycling to ALL shortcuts (1,3,4,5,6,7,8,9)
- [x] Added sixteenths mode (Cmd+Option+4) - 16 positions in 4x4 grid
- [x] Migrated most shortcuts from Rectangle to Hammerspoon
- [x] Only Rectangle handles: Tile All (0) and Halves (2)
- [x] Complete README overhaul with ASCII diagrams
- [x] Made GitHub repo PUBLIC
- [x] Added repo topics for discoverability
- [x] Softened origin story to properly credit Rectangle/Ryan
- [x] Removed emdashes and emojis (avoid AI-written appearance)
- [x] Added LICENSE (MIT)
- [x] Added init.lua to repo for direct download

### The System (FINAL)

| Shortcut | Action | Handler | Multi-Monitor |
|----------|--------|---------|---------------|
| Cmd+0 | Tile All | Rectangle | No |
| Cmd+1 | Maximize | Hammerspoon | Yes |
| Cmd+2 | Halves | Rectangle | No |
| Cmd+3 | Thirds (3 positions) | Hammerspoon | Yes |
| Cmd+4 | Fourths + Corners (8 positions) | Hammerspoon | Yes |
| Cmd+5 | Center | Hammerspoon | Yes |
| Cmd+6 | Sixths (6 positions) | Hammerspoon | Yes |
| Cmd+7 | Almost Maximize | Hammerspoon | Yes |
| Cmd+8 | Eighths (8 positions) | Hammerspoon | Yes |
| Cmd+9 | Ninths (9 positions) | Hammerspoon | Yes |
| Cmd+Option+4 | Sixteenths (16 positions) | Hammerspoon | Yes |

### GitHub
- **Repo:** https://github.com/GenesisFlowLabs/snapnuts
- **Visibility:** PUBLIC
- **Topics:** macos, window-management, hammerspoon, rectangle, productivity, numpad, keyboard-shortcuts

---

## What's Built

| Component | Status | Location |
|-----------|--------|----------|
| Hammerspoon config | Complete | `~/.hammerspoon/init.lua` and repo `init.lua` |
| README | Complete | `README.md` with full ASCII diagrams |
| Logo | Complete | `logo.png` |
| License | Complete | `LICENSE` (MIT) |
| Rectangle config | Minimal | Only Tile All and Halves |

---

## Installation (One-Liner)

```bash
brew install --cask rectangle hammerspoon
curl -fsSL https://raw.githubusercontent.com/GenesisFlowLabs/snapnuts/main/init.lua -o ~/.hammerspoon/init.lua
```

---

## Key Files

| File | Purpose |
|------|---------|
| `init.lua` | THE PRODUCT - Hammerspoon config with all shortcuts |
| `README.md` | Public documentation, install guide, visual diagrams |
| `logo.png` | SnapNuts logo |
| `LICENSE` | MIT License |
| `CLAUDE.md` | Quick context for AI pair programming |
| `PROJECT-STATUS.md` | This file |

---

## Future Ideas (Not Planned)

- [ ] One-line installer script (curl | bash)
- [ ] Hammerspoon Spoon format
- [ ] Homebrew cask
- [ ] Video content showing the system in action

---

## Credits

- **Name & Logo:** Skybehind & Magic Unicorn Tech
- **Rectangle:** rxhanson/Rectangle (the foundation)
- **Hammerspoon:** Hammerspoon/hammerspoon (the superpower)
- **Claude Code:** Pair programming

---

## Notes

- This started as "shortcut content" for video but evolved into a standalone tool
- The video content idea is paused but the tool itself is complete
- "Solve your own problems first, then share what you learn."
