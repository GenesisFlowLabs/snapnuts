# The Rectangle Numpad System - ELI5 Edition

**What is this?** A way to control your Mac windows using just the number pad.

**Why is it special?** The number you press = how many pieces you split your screen into.

---

## The Simple Version

Press Command + a number on your numpad:

| You Press | What Happens |
|-----------|--------------|
| ⌘ + 0 | All your windows get organized automatically |
| ⌘ + 1 | Window goes FULL SCREEN |
| ⌘ + 2 | Screen splits in HALF (left or right) |
| ⌘ + 3 | Screen splits in THIRDS |
| ⌘ + 4 | Screen splits in FOURTHS (4 pieces) |
| ⌘ + 5 | Window goes to CENTER |
| ⌘ + 6 | Screen splits in SIXTHS (6 pieces) |
| ⌘ + 7 | Window goes ALMOST full screen (with a little border) |
| ⌘ + 8 | Screen splits in EIGHTHS (8 pieces) |
| ⌘ + 9 | Screen splits in NINTHS (9 pieces, like a tic-tac-toe board) |

---

## The Magic: Cycling

If you keep pressing the same number, the window MOVES to the next position.

**Example with ⌘ + 2 (halves):**
- First press: Window goes to LEFT half
- Second press: Window goes to RIGHT half
- Third press: Back to LEFT half

**Example with ⌘ + 4 (fourths):**
- Presses 1-4: Window moves through 4 vertical strips
- Presses 5-8: Window moves through 4 corners (top-left, top-right, bottom-left, bottom-right)
- Then it starts over

---

## Why It's Easy to Remember

**The number = the number of pieces.**

- Want 2 pieces? Press 2.
- Want 3 pieces? Press 3.
- Want 8 pieces? Press 8.

No complicated keyboard combinations. No memorizing weird shortcuts. The number tells you what it does.

---

## The Special Numbers

- **0 (zero)** = Zero mess. Organize everything.
- **5 (five)** = It's in the CENTER of the numpad, so it puts your window in the CENTER of the screen.
- **7 (seven)** = "Almost maximize" - fills most of the screen but leaves a little breathing room.

---

## What You Need

1. **Rectangle** (free app) - Does the basic window management
2. **Hammerspoon** (free app) - Adds the fancy 8-position cycling for ⌘+4

Both are free. Both are open source.

---

## Installation (One Command)

```bash
# Paste this in Terminal to install everything
brew install --cask rectangle hammerspoon
```

Then download our config files and you're done.

---

## Who Made This?

**Shafen Khan** came up with the "number = meaning" pattern on December 25, 2025.

It was born from the simple idea: *What if the shortcut taught itself?*

---

## Handoff Notes for ChatGPT Content Thread

**Content angles:**
1. "The shortcut that teaches itself"
2. "I turned my numpad into a window controller"
3. "Stop dragging windows. Start pressing numbers."
4. "The only shortcut system you'll ever need"

**Key hook:** People waste hours dragging and resizing windows. This system = instant organization with muscle memory.

**Visual content idea:** Screen recording showing the cycling in action. 15-30 seconds. No talking needed. Just press. Watch. Magic.

**Target audience:** Mac power users, developers, productivity nerds, people with multiple monitors.
