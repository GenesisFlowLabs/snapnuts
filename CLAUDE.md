# SnapNuts

## Quick Context
SnapNuts is a free, open source window manager for macOS. The core idea: **the number = the division**. Press Cmd+4 for fourths, Cmd+8 for eighths. The shortcut teaches itself.

**Project Location:** `~/projects/tools/snapnuts/`
**GitHub (PUBLIC):** https://github.com/GenesisFlowLabs/snapnuts (mirror: git.unicorncommander.ai/GenesisFlowLabs/snapnuts)

## Current State (2026-10-15)

### STATUS: 2.0.0, a Hammerspoon Spoon. Live on this Mac.

| File | Purpose |
|------|---------|
| `SnapNuts.spoon/init.lua` | **THE PRODUCT**: hotkeys, windows, undo, workspaces, stash |
| `SnapNuts.spoon/core.lua` | Pure geometry, no `hs.*`. Grid, frames, matching, orientation, tiling |
| `tests/core_test.lua` | 30 unit tests, `lua tests/core_test.lua` |
| `tests/hs_test.lua` | 23-check integration suite, runs inside Hammerspoon (below) |
| `install.sh` | Symlinks the Spoon into `~/.hammerspoon/Spoons/`, adds the two loader lines |
| `init.lua.example` | What a user's own `init.lua` needs |
| `SnapNutsApp/` | Swift app, paused since 2026-01-25 (code signing) |
| `website/` | Product page, its own repo (snapnuts-website), ignored here. Describes the Swift app |

**On this Mac:** `~/.hammerspoon/Spoons/SnapNuts.spoon` is a **symlink to this repo**, so an edit here is live after Reload Config, and the repo can never drift from the installed copy again. `~/.hammerspoon/init.lua` holds the two loader lines plus Shafen's macro-pad bindings (F18/F19), which are personal and not part of the product. Backups: `~/.hammerspoon/init.lua.bak-2026-10-07` (last 1.x), `.bak-2026-10-15` (just before 2.0).

### How to verify a change

```bash
lua tests/core_test.lua
hs -c 'hs.reload()'; sleep 2
hs -t 90 -c 'dofile(os.getenv("HOME") .. "/projects/tools/snapnuts/tests/hs_test.lua")'
```

The integration suite moves the Hammerspoon console window around for a few seconds and puts it back. Default `hs` CLI timeout is 4 s, hence `-t`. Do not poll `hs -c` in a tight loop while a long command runs: hs.ipc refuses re-entrant requests and floods the console.

### Shortcut map (2.0)

Divisions: Cmd+pad0-9 / Cmd+Ctrl+0-9. Sixteenths: Cmd+Opt+pad4 / Cmd+Ctrl+Opt+4. Tile all apps: Cmd+Opt+pad0 / Cmd+Ctrl+Opt+0.
Utilities: undo Cmd+pad- / Cmd+Ctrl+Z; save Cmd+pad+ / Cmd+Ctrl+S; restore list Cmd+pad/ / Cmd+Ctrl+W; restore slot N Cmd+Shift+padN (numpad only); stash Cmd+Ctrl+Shift+Left/Right; unstash Cmd+Ctrl+Shift+U.

⛔ **Never bind Cmd+Shift+anything on the main keyboard.** 1.x did, and it took Redo, Save As, select-to-line-end and the macOS screenshot keys from every app for nine months. Cmd+Ctrl+Shift+3/4 are also taken (screenshot to clipboard). Ctrl+Opt+1-3 are registered by something else on this Mac (owner unknown, not a macOS symbolic hotkey).

### Known macOS quirks handled in `setFrameOn`
- An app may refuse a frame on a screen the window is not on yet: move it there first.
- A secondary display refuses to shrink a full-height window by less than the menu bar height (~31 px): set a clearly smaller frame first, then the real one. Found on the K3-1 above the primary.
- Hammerspoon hides its own windows from `hs.window.visibleWindows()`, which is why the integration test injects the console's workspace record instead of saving it.

## Swift App (Paused)

4,106 lines in `SnapNutsApp/Sources/SnapNuts/`. Paused 2026-01-25: ad-hoc signing loses Accessibility permission on every rebuild, and public distribution needs Developer ID + notarization. Last release v1.1.0 (zip, 4 downloads). The website in `website/` still describes this app.

## History

- **2025-12-25**: Concept, Hammerspoon + Rectangle prototype
- **2026-01-07**: Native Swift app (Aaron, Magic Unicorn Tech)
- **2026-01-23**: Swift v1.1.0 with grid overlay, workspaces, stash, undo
- **2026-01-25**: Swift paused; Hammerspoon config gets every feature
- **2026-02-01**: Laptop fallback shortcuts
- **2026-10-15**: 2.0.0 as a Spoon: per-window cycling, portrait awareness, persistent workspaces, undo everywhere, conflict-free chords, tests

## Credits

| Role | Credit |
|------|--------|
| Created by | Genesis Flow Labs |
| Refined by | Magic Unicorn Tech |
| Logo | Skybehind |
| AI Assistance | Claude (Anthropic) |

---
*"The number = the division."*
