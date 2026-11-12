---
name: lane
description: Make or retire a lane's jj workspace with the `lane` script beside this file, which clones the repo root's cargo `target/` into the new workspace by APFS copy-on-write (instant, no disk), and deletes a retired one. Use whenever a lane starts (before spawning its agent) or finishes (after it has landed or been bookmarked), instead of `jj workspace add` / `forget` by hand.
---

# Lane workspaces

One script, beside this file: `lane`. Run it from the repo root (the default workspace).

```sh
<skill dir>/lane new <name> [rev]   # .workspaces/<name> on rev (default main), target/ cloned from ./target
<skill dir>/lane retire <name>      # refuses on uncommitted changes; else forget + delete the directory
```

## Why the clone

A lane's disk is almost all `target/`. `cp -c` makes an APFS clone: every block is shared with the root's `target/` until cargo rewrites that file, so dependencies are stored once however many lanes run, and a lane pays only for what it rebuilds. Measured on tussen: 15 GB cloned in 4 s, free space unchanged. `du` counts each clone in full; check real use with `df`.

## Nothing to link

A workspace needs no setup beyond its cache. The installed pi package brings the rules, the roles and the skills to every session, and finds the repo's `AGENTS.project.md` from any directory below the root, so a lane in `.workspaces/<name>` reads the same copy. In a repo you don't own (one with `.pi/AGENTS.project.md`), workspaces go in `.pi/workspaces/<name>`, where nothing shows outside `.pi/`.

## Keeping the base warm

The root's `target/` is the base every new lane clones. Integrators gate in the default workspace **without** `CARGO_TARGET_DIR`, so each landing leaves the base built on trunk. Don't hand caches from lane to lane, and don't keep spares: a retired lane's cache is deleted with it.

Rebuilds leave superseded artifacts behind in every `target/`; where the project has a prune command (tussen: `cargo xtask prune`), run it after a lane's final gate run and in the default workspace after landing, so the base stays lean and clones start small.

## Order of operations

- **Start**: `lane new <name> [rev]`, then spawn the agent with `cwd` = the workspace (`.workspaces/<name>`). Spawn after the script returns, never in the same parallel batch (the directory must exist).
- **Finish**: bookmark the chain tip if it hasn't landed (`jj bookmark create wip-<name> -r <tip>`), then `lane retire <name>`. Forgetting the workspace removes the only thing keeping an unlanded chain visible.
- **Fork from a lane**: `lane new <new> <its change>` (AGENTS.md, *Fork, don't pile on*).

## What it doesn't do

- Delete anything but a retired workspace's own directory: its commits stay in the repo, so nothing of the lane's work is lost (bookmark an unlanded tip first).
- Rebase, land or move bookmarks: that stays the integrator's.
- Non-APFS filesystems: `cp -c` fails there; the script then needs a plain copy or a cold build (not handled yet).
