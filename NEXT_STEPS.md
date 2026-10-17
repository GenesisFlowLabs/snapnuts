# SnapNuts - Next Steps

*Last updated: 2026-10-17*

1. **Push `main` and the `swift-app` branch to `origin` and `gitea`, then tag `v2.1.0`.** Confirm branch and remote first (house rule). The CI badge in the README goes live with the first push.
2. **The name stays SnapNuts** (decided 2026-10-17). Nothing to do.
3. **Use it for a week.** New in 2.1: Cmd+pad. sends the window to the next screen, Cmd+Opt+pad. to the previous one. Stash now hides properly on the three-screen rig. If a chord feels wrong, change `defaultHotkeys` in `SnapNuts.spoon/init.lua` and rerun the tests.
4. **Website.** `website/` (its own repo) still describes the Swift app. Rewrite around the Spoon or leave it undeployed. Do this before any announcement.
5. **Announce** only after 1 and 4: a GitHub release for the tag with notes from CHANGELOG.md, a 20-second GIF of the number keys, one post.

## 2.2 ideas

- Grid overlay on each press: a half-second outline of the cells with the active one lit, on the target screen (`hs.canvas`).
- Workspace restore that launches missing apps and places their windows as they appear.
- Hover-to-peek for stashed windows (claimed by the old website changelog, never built).
- Display-triggered layouts: restore a workspace automatically when a named monitor connects.
- Per-app memory ("Safari always opens in the right half").
