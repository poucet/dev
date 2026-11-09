---
name: lane
description: Make or retire a lane's jj workspace with the `lane` script beside this file, which clones the repo root's cargo `target/` into the new workspace by APFS copy-on-write (instant, no disk), links the system's local files into it (AGENTS.md, AGENTS.project.md, the agent directories), and deletes a retired one. Use whenever a lane starts (before spawning its agent) or finishes (after it has landed or been bookmarked), instead of `jj workspace add` / `forget` by hand.
---

# Lane workspaces

One script, beside this file: `lane`. Run it from the repo root (the default workspace).

```sh
<skill dir>/lane new <name> [rev]   # .workspaces/<name> on rev (default main), target/ cloned from ./target, links made
<skill dir>/lane link <name>        # (re)make the links in an existing workspace; idempotent
<skill dir>/lane retire <name>      # refuses on uncommitted changes; else forget + delete the directory
```

## Why the clone

A lane's disk is almost all `target/`. `cp -c` makes an APFS clone: every block is shared with the root's `target/` until cargo rewrites that file, so dependencies are stored once however many lanes run, and a lane pays only for what it rebuilds. Measured on tussen: 15 GB cloned in 4 s, free space unchanged. `du` counts each clone in full; check real use with `df`.

## The links

`AGENTS.md`, `AGENTS.project.md` and the agent directories (`.claude/agents`, `.pi/agents`) are local links, untracked in every repo (AGENTS.md, the intro). The root's are relative or point into this machine, so inside `.workspaces/<name>` they would dangle; `lane new` gives the workspace **absolute** symlinks to what the root's resolve to: dev's `AGENTS.md`, the root's own `AGENTS.project.md`, dev's `agents/`. Only what the root has is linked.

A link is made only where it can't show in the lane's working copy: the path must be ignored by the lane's own `.gitignore` files (a harness directory the lane lacks is created ignoring itself) and not tracked in the lane's commit. A real file is never replaced. Otherwise `lane` says why and what to do: a lane based before its repo untracked the links has them tracked, or not ignored, until it rebases onto trunk; run `lane link <name>` after that rebase, while the lane is idle.

## Keeping the base warm

The root's `target/` is the base every new lane clones. Integrators gate in the default workspace **without** `CARGO_TARGET_DIR`, so each landing leaves the base built on trunk. Don't hand caches from lane to lane, and don't keep spares: a retired lane's cache is deleted with it.

Rebuilds leave superseded artifacts behind in every `target/`; where the project has a prune command (tussen: `cargo xtask prune`), run it after a lane's final gate run and in the default workspace after landing, so the base stays lean and clones start small.

## Order of operations

- **Start**: `lane new <name> [rev]`, then spawn the agent with `cwd` = `.workspaces/<name>`. Spawn after the script returns, never in the same parallel batch (the directory must exist).
- **Finish**: bookmark the chain tip if it hasn't landed (`jj bookmark create wip-<name> -r <tip>`), then `lane retire <name>`. Forgetting the workspace removes the only thing keeping an unlanded chain visible.
- **Fork from a lane**: `lane new <new> <its change>` (AGENTS.md, *Fork, don't pile on*).

## What it doesn't do

- Touch the links at the repo root: those are `adopt.sh`'s.
- Delete anything but a retired workspace's own directory: its commits stay in the repo, so nothing of the lane's work is lost (bookmark an unlanded tip first).
- Rebase, land or move bookmarks: that stays the integrator's.
- Non-APFS filesystems: `cp -c` fails there; the script then needs a plain copy or a cold build (not handled yet).
