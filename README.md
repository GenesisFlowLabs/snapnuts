# SnapNuts

**The number = the division.** Window management that teaches itself.

```
    ┌─────────────────────────────────────────────────────────┐
    │                                                         │
    │   ⌘ + 4  =  Split screen into 4ths                     │
    │   ⌘ + 8  =  Split screen into 8ths                     │
    │   ⌘ + 9  =  Split screen into 9ths                     │
    │                                                         │
    │   The shortcut IS the lesson.                          │
    │                                                         │
    └─────────────────────────────────────────────────────────┘
```

A free, open source window management system for macOS that turns your numpad into an intuitive window controller. No memorization needed. The number tells you exactly what it does.

<p align="center">
  <img src="logo.png" alt="SnapNuts Logo" width="300">
</p>

---

## Native macOS App (New!)

SnapNuts is now available as a **native macOS app** built with Swift and SwiftUI. No dependencies required.

<p align="center">
  <img src="screenshots/settings-general.png" alt="General Settings" width="280">
  <img src="screenshots/settings-shortcuts.png" alt="Customizable Shortcuts" width="280">
  <img src="screenshots/settings-about.png" alt="About" width="280">
</p>

### Features
- **Native Performance** - Built with Swift, runs as a lightweight menu bar app
- **Customizable Shortcuts** - Click "Learn" to record any key combination
- **Visual Feedback** - On-screen alerts show which position you've snapped to
- **Multi-Monitor Support** - Automatically cycles through all your displays
- **No Dependencies** - Just download and run

### Download & Build

```bash
# Clone the repo
git clone https://github.com/GenesisFlowLabs/snapnuts.git
cd snapnuts/SnapNutsApp

# Build the app
./build.sh

# Run it
open build/SnapNuts.app
```

The app lives in your menu bar. Click the squirrel icon to access Settings or Quit.

---

## Hammerspoon Version (Original)

Prefer a Lua-based setup with Rectangle integration? The original Hammerspoon config is still available and fully supported.

## Quick Start (Hammerspoon)

```bash
# Install dependencies
brew install --cask rectangle hammerspoon

# Download and install SnapNuts config
curl -fsSL https://raw.githubusercontent.com/GenesisFlowLabs/snapnuts/main/init.lua -o ~/.hammerspoon/init.lua

# Grant Hammerspoon accessibility permissions when prompted
open -a Hammerspoon
```

That's it. Start pressing ⌘ + numpad keys.

---

## The Complete System

Every shortcut cycles through positions, then **automatically moves to the next monitor**.

| Shortcut | Division | Positions | What Happens |
|:--------:|:--------:|:---------:|:-------------|
| ⌘ + 0 | Tile All | - | Organizes all visible windows |
| ⌘ + 1 | **Maximize** | 1 | Full screen → next monitor |
| ⌘ + 2 | **Halves** | 2 | Left ↔ Right → next monitor |
| ⌘ + 3 | **Thirds** | 3 | Left → Center → Right → next monitor |
| ⌘ + 4 | **Fourths + Corners** | 8 | See below |
| ⌘ + 5 | **Center** | 1 | 80% centered → next monitor |
| ⌘ + 6 | **Sixths** | 6 | 3×2 grid → next monitor |
| ⌘ + 7 | **Almost Max** | 1 | 90% centered → next monitor |
| ⌘ + 8 | **Eighths** | 8 | 4×2 grid → next monitor |
| ⌘ + 9 | **Ninths** | 9 | 3×3 grid → next monitor |
| ⌘ + ⌥ + 4 | **Sixteenths** | 16 | 4×4 grid → next monitor |

---

## Visual Guide

### ⌘ + 2: Halves
```
┌───────────┬───────────┐
│           │           │
│     1     │     2     │
│           │           │
└───────────┴───────────┘
```

### ⌘ + 3: Thirds
```
┌───────┬───────┬───────┐
│       │       │       │
│   1   │   2   │   3   │
│       │       │       │
└───────┴───────┴───────┘
```

### ⌘ + 4: Fourths + Corners (The Special One)

Unlike other window managers, **one key gives you 8 positions**:

```
Presses 1-4 (Vertical Strips):       Presses 5-8 (Corners):
┌─────┬─────┬─────┬─────┐            ┌───────────┬───────────┐
│     │     │     │     │            │           │           │
│  1  │  2  │  3  │  4  │            │   5 (TL)  │   6 (TR)  │
│     │     │     │     │            │           │           │
│     │     │     │     │            ├───────────┼───────────┤
│     │     │     │     │            │           │           │
└─────┴─────┴─────┴─────┘            │   7 (BL)  │   8 (BR)  │
                                     │           │           │
                                     └───────────┴───────────┘
```

### ⌘ + 6: Sixths (3×2)
```
┌───────┬───────┬───────┐
│   1   │   2   │   3   │
├───────┼───────┼───────┤
│   4   │   5   │   6   │
└───────┴───────┴───────┘
```

### ⌘ + 8: Eighths (4×2)
```
┌─────┬─────┬─────┬─────┐
│  1  │  2  │  3  │  4  │
├─────┼─────┼─────┼─────┤
│  5  │  6  │  7  │  8  │
└─────┴─────┴─────┴─────┘
```

### ⌘ + 9: Ninths (3×3)
```
┌───────┬───────┬───────┐
│   1   │   2   │   3   │
├───────┼───────┼───────┤
│   4   │   5   │   6   │
├───────┼───────┼───────┤
│   7   │   8   │   9   │
└───────┴───────┴───────┘
```

### ⌘ + ⌥ + 4: Sixteenths (4×4) - Power User Mode
```
┌─────┬─────┬─────┬─────┐
│  1  │  2  │  3  │  4  │
├─────┼─────┼─────┼─────┤
│  5  │  6  │  7  │  8  │
├─────┼─────┼─────┼─────┤
│  9  │ 10  │ 11  │ 12  │
├─────┼─────┼─────┼─────┤
│ 13  │ 14  │ 15  │ 16  │
└─────┴─────┴─────┴─────┘
```

Perfect for ultra-wide monitors or precision window placement.

---

## Multi-Monitor Magic

Every shortcut automatically cycles across your displays:

```
Monitor 1                    Monitor 2
┌─────────────────┐          ┌─────────────────┐
│                 │          │                 │
│  Positions 1-8  │    →     │  Positions 1-8  │    →    (back to Monitor 1)
│                 │          │                 │
└─────────────────┘          └─────────────────┘

Alert shows: [1/2]           Alert shows: [2/2]
```

No extra shortcuts needed. Just keep pressing. It flows naturally.

---

## The Philosophy

Most keyboard shortcuts are arbitrary. `⌘+Shift+Option+Left`? Good luck remembering that.

SnapNuts is different:

| Want this? | Press this |
|:-----------|:-----------|
| **2** pieces | ⌘ + **2** |
| **3** pieces | ⌘ + **3** |
| **4** pieces | ⌘ + **4** |
| **8** pieces | ⌘ + **8** |
| **9** pieces | ⌘ + **9** |

**The number IS the meaning.** You'll never forget it because there's nothing to forget.

---

## Installation

### Prerequisites
- macOS
- A keyboard with a numpad (or use Karabiner to remap keys)
- [Homebrew](https://brew.sh) (for easy installation)

### Step 1: Install the Apps

```bash
brew install --cask rectangle hammerspoon
```

### Step 2: Install SnapNuts Config

```bash
# Backup existing config (if any)
[ -f ~/.hammerspoon/init.lua ] && cp ~/.hammerspoon/init.lua ~/.hammerspoon/init.lua.backup

# Download SnapNuts
curl -fsSL https://raw.githubusercontent.com/GenesisFlowLabs/snapnuts/main/init.lua -o ~/.hammerspoon/init.lua
```

### Step 3: Configure Rectangle

Only two shortcuts stay with Rectangle (Tile All and Halves):

```bash
# Kill Rectangle first
pkill -9 Rectangle 2>/dev/null

# Configure the two Rectangle shortcuts
defaults write com.knollsoft.Rectangle tileAll -dict-add keyCode -float 82 modifierFlags -float 1048576
defaults write com.knollsoft.Rectangle leftHalf -dict-add keyCode -float 84 modifierFlags -float 1048576

# Restart Rectangle
open -a Rectangle
```

### Step 4: Grant Permissions

1. Open **Hammerspoon** (it will prompt for accessibility permissions)
2. Go to **System Settings → Privacy & Security → Accessibility**
3. Enable **Hammerspoon**
4. Click the Hammerspoon menu bar icon → **Reload Config**

You should see: `"Hammerspoon: Rectangle Numpad System loaded"`

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        YOUR NUMPAD                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│    ⌘+7        ⌘+8        ⌘+9         (Almost/Eighths/Ninths)│
│    Almost     Eighths    Ninths                             │
│                                                             │
│    ⌘+4        ⌘+5        ⌘+6         (Fourths/Center/Sixths)│
│    Fourths    Center     Sixths                             │
│                                                             │
│    ⌘+1        ⌘+2        ⌘+3         (Max/Halves/Thirds)    │
│    Maximize   Halves     Thirds                             │
│                                                             │
│    ⌘+0                               (Tile All)             │
│    Tile All                                                 │
│                                                             │
└─────────────────────────────────────────────────────────────┘

┌──────────────┐          ┌──────────────┐
│  Rectangle   │          │ Hammerspoon  │
│              │          │              │
│  • Tile All  │          │  • Everything│
│  • Halves    │          │    else      │
│              │          │              │
│  (2 keys)    │          │  (9 keys)    │
└──────────────┘          └──────────────┘
```

**Why both?** Rectangle handles Tile All (complex multi-window logic) and Halves (simple, no multi-monitor needed). Hammerspoon handles everything else with our custom multi-monitor cycling.

---

## Troubleshooting

### Shortcut not working?

1. **Check Hammerspoon is running** (look for the hammer icon in menu bar)
2. **Reload config**: Click the Hammerspoon menu bar icon, then Reload Config
3. **Check permissions**: System Settings, Privacy & Security, Accessibility, enable Hammerspoon

### Using a laptop without numpad?

Use [Karabiner-Elements](https://karabiner-elements.pqrs.org/) to remap keys. For example, map `fn + 1-9` to numpad keys.

### Want to customize positions?

Edit `~/.hammerspoon/init.lua`. Each position is defined as:
```lua
{x = 0, y = 0, w = 0.5, h = 0.5}  -- x, y = position; w, h = size (as fraction of screen)
```

---

## Origin Story

**December 25, 2025.** Setting up a new Mac. Installing Rectangle (seriously, one of the best free tools on macOS). Configuring shortcuts.

Then a thought:

> "Wait... what if the number on the numpad told you exactly what it does?"

We filed a [feature request](https://github.com/rxhanson/Rectangle/issues/1681) asking about extended cycling. The maintainer (Ryan) kindly pointed out this exists in [Rectangle Pro](https://rectangleapp.com/pro), which is totally worth it if you want a polished, supported experience.

But we were curious. Could we build it ourselves? Christmas Day. Hammerspoon docs open. Claude Code running. A few hours of vibe coding later... SnapNuts was born.

**This isn't a replacement for Rectangle.** It's a love letter to it. Rectangle does the heavy lifting. We just added some numpad magic on top.

*"Solve your own problems first, then share what you learn."*

---

## Acknowledgements

- **Name & Logo:** [Skybehind](https://github.com/skybehind) & [Magic Unicorn Tech](https://magicunicorn.tech)
- **Rectangle:** [rxhanson/Rectangle](https://github.com/rxhanson/Rectangle)
- **Hammerspoon:** [Hammerspoon/hammerspoon](https://github.com/Hammerspoon/hammerspoon)
- **Claude Code:** For pair programming at 2am on Christmas

---

## License

MIT License. Do whatever you want with it.

---

## Contributing

Found a bug? Have an idea? PRs welcome.

```bash
# Clone the repo
git clone https://github.com/GenesisFlowLabs/snapnuts.git

# Edit init.lua
# Test locally by copying to ~/.hammerspoon/init.lua
# Submit a PR
```

---

<p align="center">
  <strong>A Genesis Flow Labs Release</strong><br>
  <a href="https://genesisflowlabs.com">genesisflowlabs.com</a><br><br>
  <em>"Solve your own problems first."</em>
</p>
