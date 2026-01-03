# The Rectangle Numpad System Journey

**Date:** December 25, 2025
**Author:** Shafen Khan
**Status:** In Progress

---

## The Origin Story

It started with a simple problem: managing windows on macOS was clunky. I had just uninstalled BetterSnapTool (paid) and installed Rectangle (free, open source) when something clicked.

### The Breakthrough Moment

While setting up keyboard shortcuts, I noticed a pattern:
- I put "Tile All" on `⌘+Numpad 0` because 0 = "zero mess"
- I put "Eighths" on `⌘+Numpad 8` because... 8 = eighths

Wait. **The number could BE the meaning.**

### The Eureka

What if EVERY numpad key told you exactly what it did?

```
0 = organize all (zero mess)
1 = one window (full screen)
2 = two halves
3 = three thirds
4 = four quarters
5 = center (center of numpad = center of screen)
6 = six sixths
7 = ? (special)
8 = eight eighths
9 = nine ninths (3x3 grid)
```

This wasn't just a shortcut system. This was a **mnemonic system** - the shortcuts teach themselves.

---

## The Implementation

### Phase 1: Basic Setup
- Installed Rectangle via Homebrew
- Set up initial shortcuts using `defaults write` commands
- Discovered Rectangle's cycling behavior (repeat = next position)

### Phase 2: Refinement
- Realized `topLeft` ≠ cycling, need `firstFourth` for quarters
- Tested each shortcut with "3-press test"
- Documented correct Rectangle command names

### Phase 3: The Innovation
- Wanted `⌘+4` to cycle through BOTH horizontal fourths AND 2x2 corners
- Discovered Rectangle doesn't support this natively
- Filed feature request: https://github.com/rxhanson/Rectangle/issues/1681
- Pivoted to Hammerspoon for custom implementation

---

## Technical Details

### Rectangle Commands Used
| Key | Command | Cycles Through |
|-----|---------|----------------|
| 0 | `tileAll` | N/A |
| 1 | `maximize` | Toggle |
| 2 | `leftHalf` | L ↔ R |
| 3 | `firstThird` | L → C → R |
| 4 | `firstFourth` | Horizontal strips |
| 5 | `center` | Centered |
| 6 | `topLeftSixth` | 6 positions |
| 7 | `almostMaximize` | 90% screen |
| 8 | `topLeftEighth` | 8 positions |
| 9 | `topLeftNinth` | 9 positions |

### Numpad Key Codes
```
7=89  8=91  9=92
4=86  5=87  6=88
1=83  2=84  3=85
    0=82
```

### Modifier Flags
- Command = 1048576

---

## The Extended Vision

### What Rectangle Can't Do (Yet)
Single key cycling through multiple layout TYPES:
```
⌘+4 press sequence:
1 → 2 → 3 → 4 → TL → TR → BL → BR
    fourths        corners
```

### Solution: Hammerspoon
Free, open source macOS automation. Can intercept shortcuts and run custom Lua logic to achieve ANY cycling pattern we want.

---

## Tools Used

| Tool | Type | Purpose |
|------|------|---------|
| Rectangle | Free, Open Source | Window management |
| Hammerspoon | Free, Open Source (MIT) | Custom automation |
| GitHub | Free | Version control, feature requests |

---

## What This Could Become

1. **Viral content** - Short videos teaching the system
2. **Downloadable config** - One script installs the whole system
3. **Community standard** - Rectangle could adopt this pattern
4. **Brand foundation** - "Shortcut Content" project

---

## Key Lessons

1. **Patterns matter** - The number = the meaning is immediately learnable
2. **Test everything** - 3-press test caught the cycling bug
3. **Open source enables innovation** - Could file feature request, explore alternatives
4. **Document the journey** - This file exists because the process is as valuable as the product

---

## Links

- Rectangle: https://rectangleapp.com
- Rectangle GitHub: https://github.com/rxhanson/Rectangle
- Hammerspoon: https://hammerspoon.org
- Our Feature Request: https://github.com/rxhanson/Rectangle/issues/1681
- Project Repo: https://github.com/shafenkhan/shortcut-content

---

## Timeline

| Time | Event |
|------|-------|
| Dec 25, 2025 ~morning | Uninstalled Flux, installed Hidden Bar |
| Dec 25, 2025 | Replaced BetterSnapTool with Rectangle |
| Dec 25, 2025 | Discovered numpad = meaning pattern |
| Dec 25, 2025 | Built full 0-9 system |
| Dec 25, 2025 | Filed feature request on Rectangle |
| Dec 25, 2025 | Installed Hammerspoon for custom cycling |
| Dec 25, 2025 | Documented journey |

---

## People Involved

- **Shafen Khan** - Creator, Visionary
- **CJ** - Future Integrator (content execution)
- **Claude Code** - AI pair programmer
- **ChatGPT** - Social media content coaching (handoff pending)
- **UC-1 (192.168.0.222)** - Local LLM for future automation

---

## Next Steps

1. Build Hammerspoon config for extended cycling
2. Create ELI5 explanation for content creation
3. Hand off to ChatGPT thread for social media strategy
4. Explore UC-1 integration for automated content bot
