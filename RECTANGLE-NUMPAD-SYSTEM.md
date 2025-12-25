# Rectangle Numpad System

**Created:** December 25, 2025
**Author:** Shafen Khan
**Status:** Design Complete - Ready for Implementation

---

## The Concept

**The number on the numpad = the number of divisions**

This is a mnemonic-based window management system where pressing ⌘ + any numpad key instantly tells you what kind of screen division you'll get.

---

## Visual Layout

```
┌───────────────────────────────────────────────┐
│  7 = SNAP       8 = EIGHTHS     9 = NINTHS    │
│  Positions      (4 top/4 bot)   (3×3 grid)    │
├───────────────────────────────────────────────┤
│  4 = QUARTERS   5 = CENTER      6 = SIXTHS    │
│  (2×2 corners)  (Focus mode)    (3 top/3 bot) │
├───────────────────────────────────────────────┤
│  1 = FULL       2 = HALVES      3 = THIRDS    │
│  (Maximize)     (Left/Right)    (L/C/R)       │
├───────────────────────────────────────────────┤
│                 0 = TILE ALL                  │
│              (Organize everything)            │
└───────────────────────────────────────────────┘
```

---

## Complete Shortcut Reference

| Shortcut | Action | Cycles Through | Memory Hook |
|----------|--------|----------------|-------------|
| ⌘ + Numpad 0 | Tile All | N/A | Zero mess |
| ⌘ + Numpad 1 | Maximize | Toggle on/off | One window, one focus |
| ⌘ + Numpad 2 | Halves | Left ↔ Right | Two halves |
| ⌘ + Numpad 3 | Thirds | Left → Center → Right | Three thirds |
| ⌘ + Numpad 4 | Quarters | TL → TR → BL → BR | Four corners |
| ⌘ + Numpad 5 | Center | Centered 60-70% | Center key = center screen |
| ⌘ + Numpad 6 | Sixths | All 6 positions | Six divisions |
| ⌘ + Numpad 7 | Snap Positions | Corners + halves | Lucky 7 smart snap |
| ⌘ + Numpad 8 | Eighths | All 8 positions | Eight divisions |
| ⌘ + Numpad 9 | Ninths | 3×3 grid (9 pos) | Nine squares |

---

## Rectangle Terminal Commands

### Numpad Key Codes
| Key | Code |
|-----|------|
| Numpad 0 | 82 |
| Numpad 1 | 83 |
| Numpad 2 | 84 |
| Numpad 3 | 85 |
| Numpad 4 | 86 |
| Numpad 5 | 87 |
| Numpad 6 | 88 |
| Numpad 7 | 89 |
| Numpad 8 | 91 |
| Numpad 9 | 92 |

### Modifier: Command Key = 1048576

### Rectangle Command Names
| Action | Command Name |
|--------|--------------|
| Tile All | `tileAll` |
| Maximize | `maximize` |
| Left Half | `leftHalf` |
| First Third | `firstThird` |
| Top Left Quarter | `topLeft` |
| Center | `center` |
| Top Left Sixth | `topLeftSixth` |
| Top Left Eighth | `topLeftEighth` |
| Top Left Ninth | `topLeftNinth` |

---

## Installation Script

```bash
#!/bin/bash
# Rectangle Numpad System Installer
# Created by Shafen Khan - December 2025

echo "Installing Rectangle Numpad System..."

# Kill Rectangle to apply settings
pkill -9 Rectangle

# 0 = Tile All (zero mess)
defaults write com.knollsoft.Rectangle tileAll -dict-add keyCode -float 82 modifierFlags -float 1048576

# 1 = Maximize (one window, one focus)
defaults write com.knollsoft.Rectangle maximize -dict-add keyCode -float 83 modifierFlags -float 1048576

# 2 = Halves (two halves)
defaults write com.knollsoft.Rectangle leftHalf -dict-add keyCode -float 84 modifierFlags -float 1048576

# 3 = Thirds (three thirds)
defaults write com.knollsoft.Rectangle firstThird -dict-add keyCode -float 85 modifierFlags -float 1048576

# 4 = Quarters (four corners)
defaults write com.knollsoft.Rectangle topLeft -dict-add keyCode -float 86 modifierFlags -float 1048576

# 5 = Center (center of numpad = center of screen)
defaults write com.knollsoft.Rectangle center -dict-add keyCode -float 87 modifierFlags -float 1048576

# 6 = Sixths (six divisions)
defaults write com.knollsoft.Rectangle topLeftSixth -dict-add keyCode -float 88 modifierFlags -float 1048576

# 7 = Almost Maximize (smart snap - fills most of screen)
defaults write com.knollsoft.Rectangle almostMaximize -dict-add keyCode -float 89 modifierFlags -float 1048576

# 8 = Eighths (eight divisions)
defaults write com.knollsoft.Rectangle topLeftEighth -dict-add keyCode -float 91 modifierFlags -float 1048576

# 9 = Ninths (3x3 grid)
defaults write com.knollsoft.Rectangle topLeftNinth -dict-add keyCode -float 92 modifierFlags -float 1048576

# Restart Rectangle
open /Applications/Rectangle.app

echo "Done! Rectangle Numpad System installed."
echo ""
echo "Your shortcuts:"
echo "  ⌘+0 = Tile All"
echo "  ⌘+1 = Maximize"
echo "  ⌘+2 = Halves"
echo "  ⌘+3 = Thirds"
echo "  ⌘+4 = Quarters"
echo "  ⌘+5 = Center"
echo "  ⌘+6 = Sixths"
echo "  ⌘+7 = Almost Maximize"
echo "  ⌘+8 = Eighths"
echo "  ⌘+9 = Ninths (3x3)"
```

---

## Why This System is Unique

1. **Mnemonic-first design** - The shortcut teaches itself
2. **Complete coverage** - Every practical window size from 1 to 9
3. **Numpad spatial logic** - Position on numpad relates to function
4. **One modifier** - Just ⌘, no complex combos
5. **Cycling built-in** - Repeat presses cycle through positions

---

## Content Potential

This system could be:
- A viral short-form video series
- A downloadable config/script for Rectangle users
- A template for other window managers
- Part of a larger "Keyboard Mastery" brand

---

## Credits

- **System Design:** Shafen Khan
- **App:** Rectangle (open source, github.com/rxhanson/Rectangle)
- **Concept Origin:** December 25, 2025 - "The number = the division"
