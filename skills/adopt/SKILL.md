---
name: adopt
description: Bring an existing repo onto the simply/dev working system by running dev's adopt.sh and reconciling what the repo already has (its own AGENTS.md, changelog, todo or board files). Use when the human developer asks to adopt, onboard or "put dev on" a repo, or when a repo has no AGENTS.md / docs/ops yet.
---

# Adopt a repo onto the dev system

`adopt.sh` lays the system down; this skill is the judgement around it: what
the repo already has, what moves where, what gets committed. It is safe to
re-run on a repo that was adopted before (`adopt.sh` is idempotent and never
overwrites).

## What adoption gives a repo

| path | what | tracked? |
|---|---|---|
| `AGENTS.md` | relative symlink to the dev repo's `AGENTS.md` (the system) | the symlink, yes |
| `AGENTS.project.md` | this repo's own rules: build, gates, branches, paths, quirks | yes |
| `.pi/agents` / `.claude/agents` | symlink to `dev/agents` (the roles) | no (machine path) |
| `CHANGELOG.md` | user-facing, at the root | yes |
| `ROADMAP.md` | what comes next, by version, at the root; cites no ops ids | yes |
| `changelog.d/` | lanes' changelog fragments until folded in, in the default workspace | no: its own `.gitignore` holds `*` |
| `docs/{design,research,guides,reference}/` | the tracked doc web; not made empty, a folder appears with its first file | yes |
| `docs/ops/` | working state: BOARD, DECIDE, ASKS (the human's view); ISSUES, FIXED, DECISIONS, IDEAS (the record); `reports/` (lanes' final reports); `drafts/` (appears with the first draft) | no: its own `.gitignore` holds `*` |
| `.workspaces/`, `.trash/` | lane workspaces, discarded files | no: each has its own `.gitignore` holding `*` |

The starter files (`AGENTS.project.md`, `CHANGELOG.md`, `ROADMAP.md`,
`docs/ops/*.md`) are copied from dev's `templates/`, each only where the repo
has no file of that name.

**A repo adopted under the older layout** keeps its files: `adopt.sh` deletes
nothing. Bring it in line by hand: `docs/ops/ROADMAP.md` moves to the root and
is committed, with ops ids taken out (`adopt.sh` warns while it is there);
`docs/ops/STATUS.md`'s live rows fold into `BOARD.md`, any standing rule in it
goes to `AGENTS.project.md`, and the file goes to `.trash/`; closed rows in
`ISSUES.md` move to `FIXED.md`; fragments already tracked in `changelog.d/`
are folded or untracked (`jj file untrack`).

## Steps

1. **Look before touching.** Read the repo's README, any existing `AGENTS.md`,
   `CLAUDE.md`, `CHANGELOG*`, `TODO*`, `docs/`, and its build (`Cargo.toml`,
   `package.json`, …). Note the VCS: `jj st` (or `git status`). **Never adopt
   over uncommitted work you don't own**: if the working copy is dirty, ask
   the human developer first.
2. **Run the installer:**
   ```sh
   <dev repo>/adopt.sh <repo> --harness auto   # pi | claude | both
   ```
   (`<dev repo>` is wherever this system is cloned: the directory this skill's
   `skills/` folder sits in.)
   It creates only what is missing.
3. **Reconcile what the repo had:**
   - an existing `AGENTS.md` / `CLAUDE.md` with project rules → their
     **project-specific** parts go into `AGENTS.project.md`; anything generic
     that `dev/AGENTS.md` lacks is reported to the human as a backport candidate
     (don't edit dev's file from here); then `AGENTS.md` becomes the symlink;
   - an existing changelog anywhere else → `CHANGELOG.md` at the root, history
     kept;
   - todo, board or issue files → their content into `docs/ops/` (untracked),
     the old files to `.trash/`;
   - a `docs/scratch/` from before → its files into `docs/ops/`, the empty
     folder to `.trash/`;
   - design or research notes → the matching `docs/` folder.
4. **Write `AGENTS.project.md`** if there isn't one: how to build and test (the
   gates, as exact commands), branches and remotes, what never to run (GUIs,
   real devices, pushes), paths. Short; facts only.
5. **Verify:**
   - `git check-ignore docs/ops/BOARD.md changelog.d/x.md` both print;
   - `jj st` / `git status` shows no machine-specific path (the harness
     symlinks) as added;
   - the harness sees the roles (pi: `"projectPersonas": true` in
     `~/.pi/agent/subagents.json`, and the project trusted on next launch: tell
     the human if either is missing).
6. **Commit only the tracked parts**, one commit, plain words, e.g.
   `Adopt the dev working system: AGENTS.md from dev, project rules in
   AGENTS.project.md, changelog and roadmap at the root` (no internal ids). Commit the
   files by path, so nobody else's uncommitted edits ride along. Don't push.
7. **Report:** what was created, what moved where, what was left for the human
   (backport candidates, settings they must flip, anything ambiguous).

## Rules that still apply

- Architecture is the human's: if the repo's layout or rules conflict with the
  system in a way that needs a choice, ask; don't pick.
- Never `rm`: discarded files go to the repo's `.trash/`.
- A repo you don't own (a shared work repo): don't adopt inside it; see
  *A repo you don't own* in `dev/AGENTS.md`.
