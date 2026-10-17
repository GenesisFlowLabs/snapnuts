# SnapNuts Launch Plan

**Created:** January 23, 2026
**Goal:** Make SnapNuts the go-to window manager for macOS

---

## Distribution Strategy Decision

### Option A: App Store
- Pros: Discoverability, trust, easy install
- Cons: 30% cut, sandboxing limits Accessibility API, $99/year fee, review delays
- Reality: Most serious window managers AREN'T on App Store (Rectangle, Amethyst) because of sandboxing

### Option B: Open Source + Pro (RECOMMENDED)
- **SnapNuts** (Free, Open Source) - Full-featured, GitHub distribution
- **SnapNuts Pro** (Paid, $9.99) - Advanced features, sold via website
- This is exactly what Rectangle does - and they're the #1 window manager

### Decision: **Hybrid Model**
- Core app stays free and open source forever
- Pro features for power users who want to support development
- Distribute via: GitHub, Website, Homebrew Cask
- No App Store (keeps full Accessibility API access)

---

## The "Killer Feature" Stack

To go viral, we need 5 features that make people say "holy shit":

| # | Feature | Status | Wow Factor |
|---|---------|--------|------------|
| 1 | "Number = Division" shortcuts | ✅ Done | Intuitive, teachable |
| 2 | Cmd+0 Tile All | ✅ Done | Unique, powerful |
| 3 | Visual Grid Overlay | 🔲 TODO | Demo gold, looks amazing |
| 4 | Workspace Layouts | 🔲 TODO | Power feature, sticky |
| 5 | Window Stashing | 🔲 TODO | Unique, delightful |

**Bonus features for polish:**
- Drag-to-snap zones
- Undo last snap
- Gaps/padding options
- Display-triggered layouts

---

## Development Priority

### Sprint 1: Visual Grid Overlay (HIGH IMPACT)
*Why first: This is DEMO GOLD. Every screenshot, video, tweet will show this.*

- Hold modifier key (e.g., Cmd+Shift) to show grid overlay on screen
- Grid shows all available zones (halves, thirds, quarters, etc.)
- Click any zone to snap current window there
- Overlay follows mouse to show which zone is selected
- Works on all monitors

**Technical approach:**
- Create transparent overlay window covering screen
- Draw grid zones with NSBezierPath
- Track mouse position to highlight zones
- On click, snap window and dismiss overlay

### Sprint 2: Workspace Layouts (STICKY FEATURE)
*Why second: This is what makes users NEED SnapNuts, not just like it.*

- Save current window arrangement as named layout
- Assign shortcuts: Cmd+Shift+1 through Cmd+Shift+9
- Restore layout instantly
- Store in UserDefaults/JSON file
- Settings UI to manage layouts

**Layouts to demo:**
- "Coding Mode" - Terminal left, Editor center, Browser right
- "Writing Mode" - Notes left, Document center
- "Meeting Mode" - Zoom maximized, Notes in corner

### Sprint 3: Drag-to-Snap (TABLE STAKES)
*Why third: Expected feature, needed for parity with Rectangle.*

- Drag window to screen edge
- Show preview zone
- Release to snap
- Support all existing positions

**Technical approach:**
- CGEventTap to monitor mouse events
- Detect when window is being dragged (via Accessibility API)
- Show preview overlay at screen edges
- On release, snap to target zone

### Sprint 4: Window Stashing (UNIQUE)
*Why fourth: Cool factor, differentiator.*

- Drag window to screen edge to "stash" it
- Window slides off-screen, leaving small tab
- Hover tab to reveal window
- Click elsewhere to re-hide

### Sprint 5: Polish & Pro Features
- Undo last snap (Cmd+Z)
- Gaps/padding settings
- Display-triggered layouts
- Per-app memory
- Menu bar quick actions

---

## Launch Checklist

### Pre-Launch (Build Phase)
- [ ] Implement Visual Grid Overlay
- [ ] Implement Workspace Layouts
- [ ] Implement Drag-to-Snap
- [ ] Implement Window Stashing
- [ ] Create landing page website
- [ ] Record demo video (60-90 seconds)
- [ ] Create screenshots/GIFs
- [ ] Write compelling README
- [ ] Set up Homebrew Cask formula
- [ ] Prepare ProductHunt assets

### Launch Channels
1. **ProductHunt** - Primary launch, aim for #1 of the day
2. **Hacker News** - "Show HN: SnapNuts - Window management where the number = the division"
3. **Reddit** - r/macapps, r/mac, r/productivity, r/opensource
4. **Twitter/X** - Demo videos, GIFs
5. **YouTube** - Tutorial/review outreach
6. **GitHub** - Trending page goal

### Post-Launch
- [ ] Respond to all feedback
- [ ] Ship fixes quickly (shows active development)
- [ ] Collect testimonials
- [ ] Create comparison page (vs Rectangle, Magnet, etc.)
- [ ] Build email list for updates

---

## Metrics for Success

### Phase 1 (First Month)
- 1,000 GitHub stars
- 5,000 downloads
- Top 5 on ProductHunt
- Featured in 2+ tech blogs

### Phase 2 (First Quarter)
- 5,000 GitHub stars
- 25,000 downloads
- Homebrew Cask available
- Community contributors

### Phase 3 (First Year)
- 10,000+ GitHub stars
- 100,000+ users
- Recognized as top-tier window manager
- Sustainable via Pro version or sponsorships

---

## Competitive Positioning

### Tagline Options
- "The number = the division" (current, strong)
- "Window management that makes sense"
- "Finally, shortcuts you can remember"

### Key Messages
1. **Intuitive**: "Cmd+4 for fourths. Cmd+3 for thirds. It teaches itself."
2. **Powerful**: "Tile all windows, save workspaces, stash windows at the edge."
3. **Free**: "Open source, no subscriptions, no tracking."
4. **Beautiful**: "Visual grid overlay, smooth animations, native macOS feel."

### vs Rectangle
"Rectangle is great. SnapNuts is intuitive. One look at our shortcuts and you'll never forget them."

### vs Magnet
"Magnet costs $8 and does less. SnapNuts is free and does more."

---

## Timeline

| Week | Focus | Deliverable |
|------|-------|-------------|
| 1 | Visual Grid Overlay | Working feature |
| 2 | Workspace Layouts | Working feature |
| 3 | Drag-to-Snap | Working feature |
| 4 | Window Stashing | Working feature |
| 5 | Polish & Bug Fixes | Stable release |
| 6 | Website & Assets | Landing page, demo video |
| 7 | Soft Launch | GitHub release, Homebrew |
| 8 | ProductHunt Launch | Full marketing push |

---

## Notes

*"We're not building another window manager. We're building the one that makes all others feel broken."*

---

**Let's fucking go.**
