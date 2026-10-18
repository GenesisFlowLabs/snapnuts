# SnapNuts - Next Steps

*Last updated: 2026-10-17, evening*

Done today: pushed to both remotes, GitHub releases 2.0.0 and 2.1.0 (2.1.0 is Latest, `SnapNuts.spoon.zip` attached), CI green on the first run, website retired, name stays SnapNuts.

1. **Use it for a week** (Shafen, through about 2026-10-24). New in 2.1: Cmd+pad. sends the window to the next screen, Cmd+Opt+pad. to the previous one. Stash hides properly on the three-screen rig. If a chord feels wrong, change `defaultHotkeys` in `SnapNuts.spoon/init.lua`, rerun the tests, and ship it as 2.1.1.
2. **Record the GIF** (Shafen at the keyboard, about 20 seconds, shot list in `docs/private/ANNOUNCE.md`). An agent should not screen-record this Mac while client sessions are open. Hand the .mov to a session and it becomes the GIF for the README, the release notes and the post.
3. **Post once**, after 1 and 2. Drafts for X and LinkedIn are in `docs/private/ANNOUNCE.md`. Nothing posted yet.
4. **Website repo** (`website/`, its own repo): the retire note is committed locally (9d7410c) and not pushed. Push it or leave it; nothing depends on it.

## 2.2 ideas

- Grid overlay on each press: a half-second outline of the cells with the active one lit, on the target screen (`hs.canvas`).
- Workspace restore that launches missing apps and places their windows as they appear.
- Hover-to-peek for stashed windows (claimed by the old website changelog, never built).
- Display-triggered layouts: restore a workspace automatically when a named monitor connects.
- Per-app memory ("Safari always opens in the right half").
