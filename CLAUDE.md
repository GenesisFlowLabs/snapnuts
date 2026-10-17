# SnapNuts

## Quick Context
SnapNuts is a free, open source window manager for macOS. The core idea: **the number = the division**. Press Cmd+4 for fourths, Cmd+8 for eighths. The shortcut teaches itself.

**Project Location:** `~/projects/tools/snapnuts/`
**GitHub (PUBLIC):** https://github.com/GenesisFlowLabs/snapnuts (mirror: git.unicorncommander.ai/GenesisFlowLabs/snapnuts)

## Current State (2026-10-17)

### STATUS: 2.1.0, a Hammerspoon Spoon. Live on this Mac.

| File | Purpose |
|------|---------|
| `SnapNuts.spoon/init.lua` | **THE PRODUCT**: hotkeys, windows, undo, workspaces, stash, send-to-screen |
| `SnapNuts.spoon/core.lua` | Pure geometry, no `hs.*`. Grid, frames, matching, orientation, tiling, desktop union, stash frame |
| `tests/core_test.lua` | 38 unit tests. `lua tests/core_test.lua`, also runs inside Hammerspoon (Lua 5.4) |
| `tests/hs_test.lua` | 31-check integration suite, runs inside Hammerspoon (below) |
| `.github/workflows/tests.yml` | CI: unit tests + syntax check on Lua 5.4 for every push |
| `install.sh` | Symlinks the Spoon into `~/.hammerspoon/Spoons/`, adds the two loader lines |
| `init.lua.example` | What a user's own `init.lua` needs |
| `docs/archive/` | 0.1 and 1.x planning docs, history only. `docs/private/` is ignored |
| `appcast.xml` | Sparkle feed polled by installed 1.x Swift apps. Stays at the root (raw URL on `main`) |
| `website/` | Product page, its own Gitea-only repo (snapnuts-website), ignored here. Still describes the Swift app, not deployed |

The Swift app is on the **`swift-app` branch** (paused since 2026-01-25 over code signing). Not on `main`.

**On this Mac:** `~/.hammerspoon/Spoons/SnapNuts.spoon` is a **symlink to this repo**, so an edit here is live after Reload Config, and the repo can never drift from the installed copy again. `~/.hammerspoon/init.lua` holds the two loader lines plus Shafen's macro-pad bindings (F18/F19), which are personal and not part of the product. Backups: `~/.hammerspoon/init.lua.bak-2026-10-07` (last 1.x), `.bak-2026-10-15` (just before 2.0).

### How to verify a change

```bash
lua tests/core_test.lua                      # local Lua (5.5 here)
hs -t 3 -c 'hs.reload()'; sleep 5            # the CLI errors out during a reload, that is normal
hs -t 30 -c 'dofile(os.getenv("HOME") .. "/projects/tools/snapnuts/tests/core_test.lua")'   # same tests on Lua 5.4
hs -t 90 -c 'dofile(os.getenv("HOME") .. "/projects/tools/snapnuts/tests/hs_test.lua")'
```

The integration suite moves the Hammerspoon console window around for a few seconds and puts it back.

⛔ **The `hs` CLI is fragile. Treat it gently.** `-t` is not a guarantee: on 2026-10-15 a plain `hs -c` fired right after `hs.reload()` hung for 13 h 43 m while Hammerspoon itself was fine. On 2026-10-17, killing hung clients made it worse: Hammerspoon then blocked for minutes trying to reply to the dead client, so every following call hung too (IPC and AppleScript both) until it timed out on its own. Rules: wait at least 5 s after `hs.reload()`; one call at a time, a few seconds apart; a watchdog of `-t` plus 30 s before killing a client; if calls start hanging, stop and wait two minutes instead of retrying; never poll `hs -c` while a long command runs (hs.ipc refuses re-entrant requests and floods the console).

### Shortcut map (2.1)

Divisions: Cmd+pad0-9 / Cmd+Ctrl+0-9. Sixteenths: Cmd+Opt+pad4 / Cmd+Ctrl+Opt+4. Tile all apps: Cmd+Opt+pad0 / Cmd+Ctrl+Opt+0.
Utilities: undo Cmd+pad- / Cmd+Ctrl+Z; save Cmd+pad+ / Cmd+Ctrl+S; restore list Cmd+pad/ / Cmd+Ctrl+W; restore slot N Cmd+Shift+padN (numpad only); send next/previous screen Cmd+pad. / Cmd+Opt+pad. (Cmd+Ctrl+Opt+Right/Left); stash Cmd+Ctrl+Shift+Left/Right; unstash Cmd+Ctrl+Shift+U.

⛔ **Never bind Cmd+Shift+anything on the main keyboard.** 1.x did, and it took Redo, Save As, select-to-line-end and the macOS screenshot keys from every app for nine months. Cmd+Ctrl+Shift+3/4 are also taken (screenshot to clipboard). Cmd+Ctrl+Left/Right is Xcode's back/forward, hence three modifiers for send-to-screen. **Ctrl+Opt+1-3 are reserved by macOS**: `hs.hotkey.systemAssigned({"ctrl","alt"}, "1")` returns a system assignment with `enabled = false`, and `RegisterEventHotKey` still refuses it. Not a third-party app.

### Known macOS quirks handled in `setFrameOn`
- An app may refuse a frame on a screen the window is not on yet: move it there first.
- A secondary display refuses to shrink a full-height window by less than the menu bar height (~31 px): set a clearly smaller frame first, then the real one. Found on the K3-1 above the primary.
- Hammerspoon hides its own windows from `hs.window.visibleWindows()`, which is why the integration test injects the console's workspace record instead of saving it.
- Stash must park off the edge of the **whole desktop** (`core.stashFrame`), not the current screen: on this rig the HP Z23i sits to the right of the primary, and a screen-edge stash put the window on it.

## History

- **2025-12-25**: Concept, Hammerspoon + Rectangle prototype
- **2026-01-07**: Native Swift app (Aaron, Magic Unicorn Tech)
- **2026-01-23**: Swift v1.1.0 with grid overlay, workspaces, stash, undo
- **2026-01-25**: Swift paused; Hammerspoon config gets every feature
- **2026-02-01**: Laptop fallback shortcuts
- **2026-10-15**: 2.0.0 as a Spoon: per-window cycling, portrait awareness, persistent workspaces, undo everywhere, conflict-free chords, tests. Pushed and tagged 2026-10-17
- **2026-10-17**: 2.1.0: send-to-screen, desktop-edge stash, hardening, CI, repo cleanup, Swift app to its own branch

## Credits

| Role | Credit |
|------|--------|
| Created by | Genesis Flow Labs |
| Refined by | Magic Unicorn Tech |
| Logo | Skybehind |
| AI Assistance | Claude (Anthropic) |

---
*"The number = the division."*
