---
name: rust-build-speed
description: Put the build-speed and editor settings tussen uses onto a Rust repo with the `apply` script beside this file — dev/test profiles in Cargo.toml, kache's incremental pass-through in .cargo/config.toml, and a rust-analyzer that never competes with agents' builds. Merges, never overwrites; idempotent; `--dry-run`. Use when a Rust repo builds slowly under many lanes, has no `[profile.dev]` tuning, or its editor runs cargo on every save.
---

# Rust build speed

One script, beside this file: `apply`. It merges `templates/` into a repo.

```sh
<skill dir>/apply --dry-run <repo>               # print the diff, write nothing
<skill dir>/apply --only cargo <repo-or-lane>    # Cargo.toml + .cargo/config.toml (tracked; a lane commits them)
<skill dir>/apply --only editor <repo-root>      # .vscode/settings.json (local, untracked)
<skill dir>/apply <repo>                         # all three
```

Needs Python 3.11+ (`tomllib`).

## What it sets, and why

| file | what | why |
|---|---|---|
| `Cargo.toml` `[profile.dev]` | `debug = "line-tables-only"`, `split-debuginfo = "unpacked"`, `incremental = true` | smaller objects and faster links; backtraces keep line numbers |
| `[profile.dev.package."*"]` | dependencies at `opt-level = 1`, no debug info | built once; tests that run through them go faster; most of what a test binary links |
| `[profile.dev.build-override]` | proc-macros and build scripts at `opt-level = 1`, no debug info | macros expand faster (serde, schemars, the repo's own macros) |
| `[profile.test]` | inherits dev | `cargo test` shares dev's dependency builds |
| `[profile.agent-test]` | test, without incremental state or strip | an agent's one-off full run after its final rebase writes no dep-graph state nobody reuses |
| `.cargo/config.toml` `[env]` | `KACHE_PRESERVE_INCREMENTAL = "1"` | with kache as rustc wrapper, workspace crates compile incrementally instead of from scratch and aren't stored; without kache it does nothing |
| `.vscode/settings.json` | rust-analyzer: no check on save, no build scripts, no proc macros, its own `targetDir`; `.workspaces`, `.trash`, `target` out of its index; `target`, `node_modules`, `.workspaces`, `.trash` out of the file watcher | agents build constantly; the editor only reads, and never waits on or invalidates their `target/` |

The numbers behind these are in tussen's `docs/research/technical/build-speed.md`.

## Rules the script keeps

- **Merge, never overwrite.** A missing table or key is added with its comment. A key the repo already sets is kept and reported as `kept … (template: …)`. Objects and arrays in settings.json gain only their missing entries; comments and the rest of the file are left as they were. It checks the result still parses and still holds every value the file had, and stops otherwise.
- **Idempotent.** A second run says `nothing to change`.
- **`[profile.release]` is never touched.** A deploy's release build behaves as before. Dev and test profiles don't reach a `cargo build --release`.
- **Editor settings are local, not tracked.** As in tussen, `.vscode/` stays gitignored; `--only editor` merges into the root's own `.vscode/settings.json` (creating it if missing) and keeps its theme and everything else. The script never edits `.gitignore`.

## Check before applying

- **A `kept` line is a decision, not an error.** E.g. an existing `debug = true` in `[profile.dev]` may be there for a reason (someone steps through code); leave it unless the human says otherwise.
- **Build scripts that do work.** With `buildScripts.enable = false`, rust-analyzer won't run them, so code they generate (`include!(concat!(env!("OUT_DIR"), …))`) won't resolve in the editor. If someone turns build scripts back on, check what they run (an npm build, say) and give rust-analyzer the env var that skips it (`rust-analyzer.cargo.extraEnv`).
- **A linker** (`ld64.lld`, mold) is not part of this: unmeasured on tussen, and a repo whose release builds in Linux Docker would need it scoped to the host target.

## After applying

A changed `[profile.dev.package."*"]` rebuilds every dependency once. Commit `Cargo.toml` and `.cargo/config.toml` from a lane and run the repo's gates; the editor settings need no commit.
