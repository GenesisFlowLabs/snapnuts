# SnapNuts 🥜

**The number = the division.** Window management that teaches itself.

A free, open source window management system for macOS that uses your numpad as an intuitive controller. Press ⌘+4 for fourths. Press ⌘+8 for eighths. The shortcut IS the lesson.

<p align="center">
  <img src="logo.png" alt="SnapNuts Logo" width="300">
</p>

---

## The System

| Shortcut | Action | What it does |
|----------|--------|--------------|
| ⌘ + Numpad 0 | Tile All | Organize all windows instantly |
| ⌘ + Numpad 1 | Maximize | Full screen (toggle) |
| ⌘ + Numpad 2 | Halves | Cycles left ↔ right |
| ⌘ + Numpad 3 | Thirds | Cycles left → center → right |
| ⌘ + Numpad 4 | Fourths + Corners | 8 positions (see below) |
| ⌘ + Numpad 5 | Center | Centered on screen |
| ⌘ + Numpad 6 | Sixths | Cycles all 6 positions |
| ⌘ + Numpad 7 | Almost Maximize | 90% screen with breathing room |
| ⌘ + Numpad 8 | Eighths | Cycles all 8 positions |
| ⌘ + Numpad 9 | Ninths | 3×3 grid, cycles all 9 |
| ⌘ + Shift + Numpad 4 | **Sixteenths** | 4×4 grid, cycles all 16 |

### The Special Sauce: ⌘+4

Unlike other window managers, SnapNuts gives you **8 positions** on a single key:

```
Presses 1-4 (Fourths):        Presses 5-8 (Corners):
┌───┬───┬───┬───┐             ┌───────┬───────┐
│ 1 │ 2 │ 3 │ 4 │             │  TL   │  TR   │
└───┴───┴───┴───┘             ├───────┼───────┤
                              │  BL   │  BR   │
                              └───────┴───────┘
```

### Power User Mode: ⌘+Shift+4

Need even more precision? **4² = 16 positions** in a 4×4 grid:

```
┌────┬────┬────┬────┐
│  1 │  2 │  3 │  4 │
├────┼────┼────┼────┤
│  5 │  6 │  7 │  8 │
├────┼────┼────┼────┤
│  9 │ 10 │ 11 │ 12 │
├────┼────┼────┼────┤
│ 13 │ 14 │ 15 │ 16 │
└────┴────┴────┴────┘
```

Press repeatedly to cycle through all 16 positions. Perfect for ultra-wide monitors or multi-window workflows.

---

## Requirements

- macOS
- [Rectangle](https://rectangleapp.com) (free, open source)
- [Hammerspoon](https://hammerspoon.org) (free, open source)

---

## Installation

### 1. Install the apps

```bash
brew install --cask rectangle hammerspoon
```

### 2. Configure Rectangle

Run this in Terminal:

```bash
# Kill Rectangle to apply settings
pkill -9 Rectangle

# 0 = Tile All
defaults write com.knollsoft.Rectangle tileAll -dict-add keyCode -float 82 modifierFlags -float 1048576

# 1 = Maximize
defaults write com.knollsoft.Rectangle maximize -dict-add keyCode -float 83 modifierFlags -float 1048576

# 2 = Halves
defaults write com.knollsoft.Rectangle leftHalf -dict-add keyCode -float 84 modifierFlags -float 1048576

# 3 = Thirds
defaults write com.knollsoft.Rectangle firstThird -dict-add keyCode -float 85 modifierFlags -float 1048576

# 5 = Center
defaults write com.knollsoft.Rectangle center -dict-add keyCode -float 87 modifierFlags -float 1048576

# 6 = Sixths
defaults write com.knollsoft.Rectangle topLeftSixth -dict-add keyCode -float 88 modifierFlags -float 1048576

# 7 = Almost Maximize
defaults write com.knollsoft.Rectangle almostMaximize -dict-add keyCode -float 89 modifierFlags -float 1048576

# 8 = Eighths
defaults write com.knollsoft.Rectangle topLeftEighth -dict-add keyCode -float 91 modifierFlags -float 1048576

# 9 = Ninths
defaults write com.knollsoft.Rectangle topLeftNinth -dict-add keyCode -float 92 modifierFlags -float 1048576

# Restart Rectangle
open /Applications/Rectangle.app
```

### 3. Configure Hammerspoon

Copy this to `~/.hammerspoon/init.lua`:

```lua
-- SnapNuts: Extended cycling for window management
-- ⌘+4: 8 positions (fourths + corners)
-- ⌘+Shift+4: 16 positions (4x4 grid)

-- Helper function to move window
local function moveToPosition(positions, index)
  local win = hs.window.focusedWindow()
  if not win then return end
  local screen = win:screen()
  local f = screen:frame()
  local pos = positions[index]
  win:setFrame({
    x = f.x + (f.w * pos.x),
    y = f.y + (f.h * pos.y),
    w = f.w * pos.w,
    h = f.h * pos.h
  })
end

-- ⌘+4: Fourths + Corners (8 positions)
local fourPositions = {
  {x = 0,    y = 0, w = 0.25, h = 1},     -- Fourth 1
  {x = 0.25, y = 0, w = 0.25, h = 1},     -- Fourth 2
  {x = 0.5,  y = 0, w = 0.25, h = 1},     -- Fourth 3
  {x = 0.75, y = 0, w = 0.25, h = 1},     -- Fourth 4
  {x = 0,   y = 0,   w = 0.5, h = 0.5},   -- Corner TL
  {x = 0.5, y = 0,   w = 0.5, h = 0.5},   -- Corner TR
  {x = 0,   y = 0.5, w = 0.5, h = 0.5},   -- Corner BL
  {x = 0.5, y = 0.5, w = 0.5, h = 0.5},   -- Corner BR
}
local currentFourIndex = 0

hs.hotkey.bind({"cmd"}, "pad4", function()
  currentFourIndex = (currentFourIndex % #fourPositions) + 1
  moveToPosition(fourPositions, currentFourIndex)
end)

-- ⌘+Shift+4: Sixteenths (4x4 grid = 16 positions)
local sixteenPositions = {
  {x = 0,    y = 0,    w = 0.25, h = 0.25},  -- Row 1
  {x = 0.25, y = 0,    w = 0.25, h = 0.25},
  {x = 0.5,  y = 0,    w = 0.25, h = 0.25},
  {x = 0.75, y = 0,    w = 0.25, h = 0.25},
  {x = 0,    y = 0.25, w = 0.25, h = 0.25},  -- Row 2
  {x = 0.25, y = 0.25, w = 0.25, h = 0.25},
  {x = 0.5,  y = 0.25, w = 0.25, h = 0.25},
  {x = 0.75, y = 0.25, w = 0.25, h = 0.25},
  {x = 0,    y = 0.5,  w = 0.25, h = 0.25},  -- Row 3
  {x = 0.25, y = 0.5,  w = 0.25, h = 0.25},
  {x = 0.5,  y = 0.5,  w = 0.25, h = 0.25},
  {x = 0.75, y = 0.5,  w = 0.25, h = 0.25},
  {x = 0,    y = 0.75, w = 0.25, h = 0.25},  -- Row 4
  {x = 0.25, y = 0.75, w = 0.25, h = 0.25},
  {x = 0.5,  y = 0.75, w = 0.25, h = 0.25},
  {x = 0.75, y = 0.75, w = 0.25, h = 0.25},
}
local currentSixteenIndex = 0

hs.hotkey.bind({"cmd", "shift"}, "pad4", function()
  currentSixteenIndex = (currentSixteenIndex % #sixteenPositions) + 1
  moveToPosition(sixteenPositions, currentSixteenIndex)
end)
```

### 4. Grant Permissions

- **Hammerspoon**: System Settings → Privacy & Security → Accessibility → Enable Hammerspoon
- Reload Hammerspoon (click menu bar icon → Reload Config)

---

## Why "The number = the division"?

Most keyboard shortcuts are arbitrary. You memorize them or you don't.

SnapNuts is different. The shortcut teaches itself:
- Want **2** pieces? Press **2**.
- Want **3** pieces? Press **3**.
- Want **8** pieces? Press **8**.

No manual needed. The number IS the meaning.

---

## Origin Story

Created on December 25, 2025 when setting up window management and realizing:

> "Wait... what if the number on the numpad told you exactly what it does?"

Built with Rectangle + Hammerspoon. Filed a feature request. Solved it ourselves. Shared it here.

---

## Acknowledgements

- **Name & Logo:** [Skybehind](https://github.com/skybehind) & [Magic Unicorn Tech](https://magicunicorn.tech)
- **Rectangle:** [rxhanson/Rectangle](https://github.com/rxhanson/Rectangle)
- **Hammerspoon:** [Hammerspoon/hammerspoon](https://github.com/Hammerspoon/hammerspoon)

---

## License

MIT License - Do whatever you want with it.

---

## A Genesis Flow Labs Release

Built by [Genesis Flow Labs](https://genesisflowlabs.com)

*"Solve your own problems first."*
