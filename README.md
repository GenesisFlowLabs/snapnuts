# SnapNuts

<p align="center">
  <img src="logo.png" alt="SnapNuts Logo" width="200">
</p>

<p align="center">
  <strong>The number = the division.</strong><br>
  Window management that teaches itself.
</p>

<p align="center">
  <a href="https://github.com/GenesisFlowLabs/snapnuts/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="License"></a>
  <img src="https://img.shields.io/badge/platform-macOS-lightgrey?style=flat-square" alt="Platform">
  <img src="https://img.shields.io/badge/runs%20on-Hammerspoon-blue?style=flat-square" alt="Hammerspoon">
</p>

---

## The idea

Most keyboard shortcuts are arbitrary. `Cmd+Shift+Option+Left`? Good luck remembering that.

SnapNuts is different:

| Want this? | Press this |
|:-----------|:-----------|
| **2** pieces | Cmd + **2** |
| **3** pieces | Cmd + **3** |
| **4** pieces | Cmd + **4** |
| **8** pieces | Cmd + **8** |
| **9** pieces | Cmd + **9** |

**The number IS the meaning.** Press the same key again and the window moves to the next piece. After the last piece it moves to the next monitor.

---

## Install

SnapNuts runs on [Hammerspoon](https://www.hammerspoon.org), a free macOS automation tool.

```bash
brew install --cask hammerspoon        # once
git clone https://github.com/GenesisFlowLabs/snapnuts.git
cd snapnuts && ./install.sh            # links SnapNuts.spoon into ~/.hammerspoon/Spoons
```

Then open Hammerspoon, grant it Accessibility permission when asked, and reload the config from its menu bar icon. You will see "SnapNuts 2.0.0" flash on screen.

`./install.sh --copy` copies the Spoon instead of linking it. By hand: copy `SnapNuts.spoon` into `~/.hammerspoon/Spoons/` and add these two lines to `~/.hammerspoon/init.lua`:

```lua
hs.loadSpoon("SnapNuts")
spoon.SnapNuts:start()
```

---

## The shortcuts

Every action has a numpad chord and a laptop chord. Both are always active.

### Divisions

| Key | Numpad | Laptop | Pieces, in press order |
|:---:|:------:|:------:|:-----------------------|
| **0** | Cmd + pad0 | Cmd + Ctrl + 0 | Tile every window of this app |
| **1** | Cmd + pad1 | Cmd + Ctrl + 1 | Full screen, then the next monitor |
| **2** | Cmd + pad2 | Cmd + Ctrl + 2 | Left, right, top, bottom |
| **3** | Cmd + pad3 | Cmd + Ctrl + 3 | Left, center, right |
| **4** | Cmd + pad4 | Cmd + Ctrl + 4 | Four columns, then four corners |
| **5** | Cmd + pad5 | Cmd + Ctrl + 5 | Centered, 80% of the screen |
| **6** | Cmd + pad6 | Cmd + Ctrl + 6 | 3 x 2 grid |
| **7** | Cmd + pad7 | Cmd + Ctrl + 7 | Centered, 90% of the screen |
| **8** | Cmd + pad8 | Cmd + Ctrl + 8 | 4 x 2 grid |
| **9** | Cmd + pad9 | Cmd + Ctrl + 9 | 3 x 3 grid |
| **4 x 4** | Cmd + Opt + pad4 | Cmd + Ctrl + Opt + 4 | Sixteenths, for ultrawides |
| **All** | Cmd + Opt + pad0 | Cmd + Ctrl + Opt + 0 | Tile every window on this screen, all apps |

Cmd + pad* also tiles the app, for keyboards where pad0 is awkward.

### Utilities

| Action | Numpad | Laptop |
|:-------|:------:|:------:|
| Undo the last move (10 levels, a tile undoes as one) | Cmd + pad- | Cmd + Ctrl + Z |
| Save the current layout to a slot | Cmd + pad+ | Cmd + Ctrl + S |
| Restore a saved layout (pick from a list) | Cmd + pad/ | Cmd + Ctrl + W |
| Restore slot 1 to 9 directly | Cmd + Shift + pad1 to pad9 | see below |
| Stash the window off the left or right edge | Cmd + Ctrl + Shift + Left / Right | same |
| Bring every stashed window back | Cmd + Ctrl + Shift + U | same |

None of these touch a macOS or common app shortcut. Redo, Save As, select-to-line-end and the screenshot keys all still work. Direct slot restore has no laptop default because every spare digit chord is either a screenshot key or already taken on too many Macs; bind your own (see below) or use the list.

---

## How it behaves

**It reads where the window is.** Each press looks at which piece the window occupies now and moves it to the next one. Switch to another window and press the same key: that window starts from wherever *it* is, not from where the last one left off.

**Portrait monitors get the division turned.** On a screen that is taller than wide, thirds are three bands and fourths are four bands. The number still equals the division.

**Workspaces survive a reload.** Saved layouts live in `~/.hammerspoon/snapnuts-workspaces.json`. They restore onto the screen they were saved on, found by name, and scale onto a screen of a different size if that one is gone.

**Tile All keeps growing.** One window fills the screen, two go side by side, and the grid keeps getting squarer however many windows you throw at it.

---

## Customize

Settings go between `loadSpoon` and `start()`. Defaults shown:

```lua
hs.loadSpoon("SnapNuts")
spoon.SnapNuts.gap = 0              -- pixels between snapped windows and the screen edge
spoon.SnapNuts.tileGap = 4          -- pixels between tiled windows
spoon.SnapNuts.portraitAware = true -- turn divisions on portrait screens
spoon.SnapNuts.undoLevels = 10
spoon.SnapNuts:start()
```

Any shortcut can be changed. One chord, or a list of chords per action:

```lua
spoon.SnapNuts:bindHotkeys({
  undo     = {{"cmd", "ctrl"}, "z"},
  restore1 = {{{"cmd", "shift"}, "pad1"}, {{"cmd", "ctrl", "alt"}, "1"}},
})
```

Action names: `maximize halves thirds fourths center sixths almostMax eighths ninths sixteenths tileApp tileAll undo saveWorkspace restoreWorkspace restore1` to `restore9 stashLeft stashRight unstash`.

If a chord is already registered by macOS or another app, SnapNuts says so when it starts and lists the chord in the Hammerspoon console, instead of leaving a key silently dead.

---

## Tests

The geometry is plain Lua and needs no Hammerspoon:

```bash
lua tests/core_test.lua
```

The integration suite runs inside Hammerspoon and pushes the Hammerspoon console window through every path on whatever screens are attached, then puts it back:

```bash
hs -t 60 -c 'dofile(os.getenv("HOME") .. "/path/to/snapnuts/tests/hs_test.lua")'
```

---

## Native app

The native Swift version, with a settings window, a visual grid overlay and drag-to-snap, lives on the [`swift-app` branch](https://github.com/GenesisFlowLabs/snapnuts/tree/swift-app). It is paused: distributing it needs Apple Developer ID signing, and without that every rebuild loses its Accessibility permission. The last build is on the [releases page](https://github.com/GenesisFlowLabs/snapnuts/releases). The Hammerspoon version above is the one that is maintained.

---

## Credits

| | |
|:--|:--|
| **Created by** | [Genesis Flow Labs](https://genesisflowlabs.com) |
| **Refined by** | [Magic Unicorn Tech](https://magicunicorn.tech) |
| **Logo** | [Skybehind](https://github.com/skybehind) |
| **Built with** | [Claude](https://claude.ai) (Anthropic) |

This project was built with AI assistance. The humans provided the vision and direction, Claude helped with implementation.

## License

MIT. Do whatever you want with it.

---

<p align="center">
  <strong>A Genesis Flow Labs Project</strong><br>
  <em>"The number = the division."</em>
</p>
