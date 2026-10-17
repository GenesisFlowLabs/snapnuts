# SnapNuts - Project Status

**Last Updated:** 2026-10-17
**Status:** 2.1.0 built, tested and live on the Mac Studio. 2.0.0 is pushed and tagged on both remotes; the 2.1 commits await the push.

---

## Where it stands

SnapNuts is a Hammerspoon Spoon (`SnapNuts.spoon/`). The Swift app lives on the `swift-app` branch, paused.

### 2.1.0 (2026-10-17)

| Finding | Change |
|---|---|
| Stash Right from the primary dropped the window onto the portrait HP (885 of 900 px visible) | Stash parks off the edge of the whole desktop |
| No way to throw a window to another monitor without resizing it | Send to next / previous screen; snapped windows keep their cell |
| Undo and unstash set frames directly, bypassing the cross-screen fixes | Both go through `setFrameOn` |
| Full-screen windows silently ignored every chord | Message shown; Tile All skips them |
| Unit tests only ever ran on Lua 5.5 locally; Hammerspoon is 5.4 | GitHub Actions runs them on 5.4; the file also runs inside Hammerspoon |
| Nine 0.1/1.x planning docs and a 271 MB Swift tree at the repo root | `docs/archive/`, `docs/private/` (ignored), `swift-app` branch |
| Ctrl+Opt+1-3 "owner unknown" | Resolved: macOS system-assigned (disabled but reserved); `hs.hotkey.systemAssigned` confirms |

Tests: 38 unit, 31 integration, all green on the three-screen rig.

### 2.0.0 (2026-10-15)

Per-window cycling, portrait awareness, persistent workspaces, undo everywhere, conflict-free chords, Spoon packaging, first tests. See CHANGELOG.md.

## Open

- **Push and tag 2.1.0.** Commits on `main` after v2.0.0 are local. Remotes: `origin` (GitHub) and `gitea`. Also push the new `swift-app` branch.
- **Name: stays SnapNuts.** Decided by Shafen on 2026-10-17 after seeing the alternatives. Closed, do not reopen.
- **Announcement.** Not yet. Website first (it still sells the Swift app), then a GitHub release with a short GIF.
- **Website** (`website/`, separate Gitea-only repo, not deployed). Rewrite around the Spoon or take it down.
- **2.2 ideas:** grid overlay on each press (hs.canvas), workspace restore that launches missing apps.

## Files

See CLAUDE.md for the file table and the verification commands.

---

*"The number = the division."*
