# SnapNuts - Project Status

**Last Updated:** 2026-10-15
**Status:** 2.0.0 built, tested and live on the Mac Studio. Not yet pushed or tagged.

---

## Where it stands

SnapNuts is a Hammerspoon Spoon (`SnapNuts.spoon/`). The Swift app is paused.

Done on 2026-10-15, all committed on `main`:

| Problem in 1.x | 2.0 |
|---|---|
| 14 Cmd+Shift chords stole Redo, Save As, select-to-line-end and the screenshot keys from every app | Utilities on numpad operators and Cmd+Ctrl; nothing collides |
| One global counter per division, so windows continued each other's cycle | Each press reads the window's current cell and advances from it |
| Undo skipped Tile All and Stash | Undo covers everything; a tile undoes as one step |
| Workspaces lost on reload; restore matched on titles; screen id unused | JSON on disk; restore by screen name or scaled onto another screen |
| Thirds and fourths were vertical strips on the portrait HP Z23i | Divisions turn 90 degrees on portrait screens |
| 600 of 961 lines copy-pasted; Tile All duplicated in full | Grid generator + one bind helper; core logic in a pure module |
| No tests | 30 unit + 23 integration checks |
| Installed copy drifted from the repo (Oct 7 macro-pad block) | Spoon is symlinked from the repo; personal bindings live outside it |
| README download link 404; docs said pad0, code said pad*; "all windows" meant current app | README rewritten; both keys work; all-apps tile added |

## Open

- **Push and tag.** Five commits on `main` are local. Remotes: `origin` (GitHub) and `gitea`. Tag `v2.0.0` after the push.
- **Website** (`website/`, separate repo) still sells the Swift app with a dead Download button. Either rewrite it around the Spoon or take it down. Not deployed anywhere today.
- **Swift app decision.** Resume (needs an Apple Developer account for Developer ID signing) or archive it formally. The README calls it paused.
- **Ctrl+Opt+1-3** are registered by something on this Mac; owner unknown. Only matters if a laptop direct-restore default is ever wanted.

## Files

See CLAUDE.md for the file table and the verification commands.

---

*"The number = the division."*
