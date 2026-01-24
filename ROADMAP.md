# SnapNuts Roadmap

**Last Updated:** January 23, 2026

## Vision

Make SnapNuts the most intuitive AND powerful window manager for macOS. The "number = division" system is our foundation - now we build the full house.

---

## Competitive Analysis (January 2026)

### Market Landscape

| App | Price | Strengths | Weaknesses |
|-----|-------|-----------|------------|
| **SnapNuts** | Free | Intuitive shortcuts, Tile All, open source | New, fewer features |
| Rectangle | Free | Popular, drag-to-snap, open source | Complex shortcuts |
| Rectangle Pro | $10 | Workspaces, stashing, snap areas | Paid |
| Magnet | $5-8 | Simple, App Store | Limited features |
| BetterSnapTool | $3 | Deep customization | Steep learning curve |
| BentoBox | $15 | Visual zones per Space | Expensive |
| Moom | $10 | Saved layouts | Dated UI |
| Amethyst | Free | Auto-tiling | Too nerdy for most |
| macOS Sequoia | Built-in | Native | Basic, clunky |

### SnapNuts Differentiators
1. **"The number = the division"** - Self-teaching shortcut system
2. **Cmd+0 Tile All** - Smart grid for all app windows (unique!)
3. **Free & open source** - Community-driven
4. **Multi-monitor cycling** - Built into every shortcut

---

## Feature Roadmap

### Phase 1: Core Polish (Current)
- [x] Multi-monitor support
- [x] Position cycling
- [x] Tile All Windows (Cmd+0)
- [x] Visual feedback alerts
- [x] Onboarding flow
- [x] Sparkle auto-updates
- [x] Customizable shortcuts
- [x] Settings UI

### Phase 2: Parity Features
Catch up with Rectangle/Magnet basics:

- [ ] **Drag-to-Snap Zones** - Drag window to screen edge/corner
  - Show visual preview of target zone
  - Support all existing positions (halves, thirds, quarters, etc.)

- [ ] **Undo Last Snap** - Cmd+Z to restore previous position/size
  - Remember last 5 positions per window

- [ ] **Gaps/Padding** - Configurable margins between windows
  - Settings slider: 0-20px
  - Per-monitor or global setting

### Phase 3: Power Features
Surpass the competition:

- [ ] **Application Layouts / Workspaces**
  - Save current window arrangement as named layout
  - Restore with single shortcut (Cmd+Shift+1, 2, 3...)
  - "Coding Mode", "Writing Mode", "Meeting Mode"
  - Export/import layouts

- [ ] **Display-Triggered Layouts**
  - Auto-apply layout when specific monitor connects
  - "Docked" vs "Mobile" configurations
  - Detect by display name/resolution

- [ ] **Window Stashing**
  - Hide windows at screen edge
  - Reveal on hover or shortcut
  - Great for reference windows

- [ ] **Always-on-Top Pin**
  - Pin any window to float above others
  - Toggle with shortcut
  - Visual indicator on pinned windows

### Phase 4: Delight Features
The cherry on top:

- [ ] **Visual Grid Overlay**
  - Hold modifier key to see available zones
  - Click zone to snap current window

- [ ] **Grow/Shrink Shortcuts**
  - Resize window by 10% increments
  - Cmd+Arrow keys or similar

- [ ] **Per-App Memory**
  - Remember preferred positions for specific apps
  - "Safari always opens in right half"

- [ ] **Trackpad Gestures**
  - Three-finger swipe to snap
  - Pinch to center/maximize

- [ ] **Menu Bar Quick Actions**
  - Click menu bar → dropdown with zone grid
  - Visual picker for current window

- [ ] **Keyboard-Driven Mode**
  - Vim-style: press leader key, then hjkl to move
  - For keyboard purists

### Phase 5: Pro/Advanced
Future considerations:

- [ ] **Scripting/Automation**
  - AppleScript support
  - Shortcuts.app integration

- [ ] **Window Groups**
  - Treat multiple windows as one unit
  - Move/resize together

- [ ] **Focus Mode Integration**
  - Different layouts per Focus mode

- [ ] **iCloud Sync**
  - Sync layouts and settings across Macs

---

## Why Build It All?

**January 23, 2026 - Shafen's Question: "Why not do it all?"**

The answer: **We will.**

SnapNuts has something the others don't - a foundation that makes sense. "Cmd+4 for fourths" is intuitive in a way that "Cmd+Option+Arrow" never will be.

We're not just building another window manager. We're building the one that:
1. You can teach your mom in 30 seconds
2. Power users will adopt for its depth
3. Stays free and open source forever

The roadmap above isn't a wishlist - it's a blueprint.

---

## Technical Notes

### Architecture Considerations
- Keep modular: each feature should be toggleable
- Performance matters: window operations must feel instant
- Accessibility API is our foundation - respect its limits
- Carbon Events for hotkeys (legacy but reliable)

### Known Challenges
- Drag-to-snap requires mouse event monitoring (CGEventTap)
- Stashing windows needs careful z-order management
- Display detection for auto-layouts requires IOKit
- Gesture support needs private APIs or Accessibility tricks

---

## Community Ideas

*Space for future community feature requests*

---

## Changelog

### January 23, 2026
- Created roadmap document
- Completed competitive analysis
- Defined 5-phase feature plan
- Fixed multi-monitor window sizing bug
- Added onboarding flow

### January 7, 2026
- Initial native Swift app release
- Ported from Hammerspoon proof-of-concept

### December 25, 2025
- Project conceived
- Hammerspoon prototype created

---

*"Solve your own problems first, then share what you learn."*
