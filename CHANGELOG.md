# Changelog

## 2.1.0 - 2026-10-17

### Added
- **Send to the next or previous screen.** Cmd+pad. and Cmd+Opt+pad. (Cmd+Ctrl+Opt+Right/Left on a laptop). A window SnapNuts placed keeps its cell, oriented for the new screen; any other window keeps its frame relative to the screen.
- **`mouseFollows` setting.** Moves the pointer along when a window changes screens. Off by default.
- **Continuous integration.** The unit tests run on Lua 5.4 (the Lua inside Hammerspoon) for every push. The test file also runs inside Hammerspoon itself.

### Fixed
- **Stash on a multi-monitor rig.** Stash parked the window at the edge of the current screen, so with a screen beyond that edge the window landed on it in plain view (885 of 900 pixels visible on the portrait HP when stashing right from the primary). It now parks off the edge of the whole desktop, keeping its height and sliding only as far as needed to stay reachable.
- **Undo and unstash across screens** go through the same frame-setting path as snapping, so apps that refuse a frame on another screen are handled.
- **Native full-screen windows** get a message instead of silently doing nothing, and Tile All skips them.
- **A window on no screen** no longer errors; it is treated as being on the main screen.

### Changed
- The Swift app moved to the `swift-app` branch. Planning documents from 0.1 and 1.x moved to `docs/archive/`.
- Tests: 38 unit, 31 integration.

## 2.0.0 - 2026-10-15

SnapNuts is now a Hammerspoon Spoon. Install with `./install.sh`, load with two lines, keep your own `init.lua`.

### Fixed
- **Shortcuts no longer hijack the apps you are in.** 1.x bound fourteen Cmd+Shift chords globally, which took Redo (Cmd+Shift+Z), Save As (Cmd+Shift+S), select-to-line-end (Cmd+Shift+Left/Right) and the macOS screenshot keys (Cmd+Shift+3/4/5) away from every app. Utilities now live on the numpad operators and under Cmd+Ctrl on the laptop set.
- **Cycling is per window.** Each press reads which piece the window is in and moves to the next. Pressing Cmd+4 on one window no longer continues the count another window left behind.
- **Undo covers everything.** Tile All and Stash used to bypass it. A tile now undoes as a single step.
- **Workspaces persist.** Saved layouts survive a Hammerspoon reload or a reboot, restore onto the screen they came from by name, and scale onto a different screen if that one is gone.
- **Tile All past 12 windows** used to run off the bottom of the screen. The grid keeps growing.
- **Thirds and sixths no longer have a one-pixel seam** from hand-typed 0.333/0.334 fractions. Cells are generated and edges are rounded so neighbors meet exactly.
- **A full-height window on a second display** that macOS refused to shrink by a few pixels now gets there via a smaller frame first.
- **Shortcuts that cannot be bound** (already taken by macOS or another app) are counted and announced at start instead of silently missing.

### Added
- **Portrait awareness.** On a screen taller than it is wide, divisions turn 90 degrees: thirds are three bands, not three thin strips.
- **Tile every window on the screen**, all apps: Cmd+Opt+pad0 or Cmd+Ctrl+Opt+0. Cmd+pad0 tiles the current app, as documented all along (1.x only had pad*; both work now).
- **Workspace list.** Cmd+pad/ or Cmd+Ctrl+W shows what is in each slot before you restore it.
- **Gap setting** for snapped windows, and a separate one for tiling.
- **Configurable shortcuts** via `bindHotkeys`.
- **Tests.** 30 unit tests on the geometry (plain Lua) and a 23-check integration suite that drives the real thing inside Hammerspoon.

### Changed
- Cmd+Shift+pad1 to pad9 restore slots directly on the numpad. There is no laptop default for direct restore; use the list or bind your own.
- The repo's single `init.lua` is gone. The product is `SnapNuts.spoon/`; `init.lua.example` shows the two lines your own config needs.

## 1.1.0 - 2026-01-23

Native Swift app release: grid overlay, workspaces, drag-to-snap, window stashing, undo, gaps. Development paused on 2026-01-25 over code signing; see README.

## 1.0.x - 2026-01

Native Swift app, converted from the Hammerspoon prototype by Magic Unicorn Tech.

## 0.1.0 - 2025-12-25

The Christmas hack. Hammerspoon plus Rectangle, numpad digits as divisions.
