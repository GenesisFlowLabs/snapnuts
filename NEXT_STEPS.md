# SnapNuts - Next Steps

*Last updated: 2026-10-15*

1. **Push `main` to `origin` and `gitea`, then tag `v2.0.0`.** Confirm branch and remote first (house rule).
2. **Use it for a week.** The chord changes are the only thing that needs a human: undo is now Cmd+pad-, save Cmd+pad+, restore list Cmd+pad/, slots Cmd+Shift+padN. If any of them feels wrong, change the default in `SnapNuts.spoon/init.lua` (`defaultHotkeys`) and rerun the tests.
3. **Website.** `website/index.html` describes the Swift app and links a download that does not exist. Rewrite around the Spoon (install is three commands) or leave it undeployed.
4. **Swift app.** Decide: Developer ID signing and resume, or archive. Until then the README says paused.

## Ideas not started

- Hover-to-peek for stashed windows (claimed by the old website changelog, never built).
- Display-triggered layouts: restore a workspace automatically when a named monitor connects.
- Per-app memory ("Safari always opens in the right half").
