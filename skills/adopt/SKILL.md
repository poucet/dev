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
| `AGENTS.md` | relative symlink to the dev repo's `AGENTS.md` (the system) | no: a `/AGENTS.md` line in the root `.gitignore` (the link dangles in a lane's workspace and in a public clone) |
| `AGENTS.project.md` | this repo's own rules: build, gates, branches, paths, quirks; default workspace only, `lane new` links it into each lane's workspace | no: a `/AGENTS.project.md` line in the root `.gitignore` (it can name private infrastructure, and some repos are public) |
| `.pi/agents` / `.claude/agents` | symlink to `dev/agents` (the roles) | no: a `/.pi/agents` or `/.claude/agents` line in the root `.gitignore` (machine path) |
| `CHANGELOG.md` | user-facing, at the root | yes |
| `ROADMAP.md` | what comes next, by version, at the root; cites no ops ids | yes |
| `changelog.d/` | lanes' changelog fragments until folded in, in the default workspace | no: its own `.gitignore` holds `*` |
| `docs/{design,research,guides,reference}/` | the tracked doc web; not made empty, a folder appears with its first file | yes |
| `docs/ops/` | working state: BOARD, DECIDE, ASKS (the human's view); ISSUES, FIXED, DECISIONS, IDEAS (the record); `reports/` (lanes' final reports); `drafts/` (appears with the first draft). Linear mode: ASKS, `reports/`, `drafts/` only | no: its own `.gitignore` holds `*` |
| `.workspaces/`, `.trash/` | lane workspaces, discarded files | no: each has its own `.gitignore` holding `*` |

The starter files (`AGENTS.project.md`, `CHANGELOG.md`, `ROADMAP.md`,
`docs/ops/*.md`) are copied from dev's `templates/`, each only where the repo
has no file of that name.

**A repo whose plan lives in Linear** (AGENTS.md §2, *Linear mode*; opt-in,
the human's call per repo) is adopted with `--tracker linear`: no `ROADMAP.md`
and no `docs/ops/` BOARD, MILESTONES, ISSUES, FIXED, IDEAS, DECIDE or DECISIONS
are made (decisions are Linear issues labelled Decision), and the untracked
`AGENTS.project.md` gains a `## Tracker` section to fill in. A re-run keeps
Linear mode on its own once that section exists. Setting up the initiative and
projects, backfilling an already-adopted repo and the cutover are the `linear`
skill; the existing files stay until that cutover, and `adopt.sh` warns about
each.

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
   <dev repo>/adopt.sh <repo> --tracker linear # a repo whose plan lives in Linear
   ```
   (`<dev repo>` is wherever this system is cloned: the directory this skill's
   `skills/` folder sits in.)
   It creates only what is missing.
3. **Reconcile what the repo had:**
   - an existing `AGENTS.md` / `CLAUDE.md` with project rules → their
     **project-specific** parts go into `AGENTS.project.md`; anything generic
     that `dev/AGENTS.md` lacks is reported to the human as a backport candidate
     (don't edit dev's file from here); then re-run `adopt.sh` with
     `--replace-agents-md`, which moves the old copy to `.trash/` and makes
     the link (without the flag a real `AGENTS.md` is reported and left
     tracked: replacing it changes what the repo's agents read);
   - an existing changelog anywhere else → `CHANGELOG.md` at the root, history
     kept;
   - todo, board or issue files → their content into `docs/ops/` (untracked),
     or into Linear in Linear mode (the `linear` skill's backfill), the old
     files to `.trash/`;
   - a `docs/scratch/` from before → its files into `docs/ops/`, the empty
     folder to `.trash/`;
   - design or research notes → the matching `docs/` folder.
4. **Write `AGENTS.project.md`** if there isn't one: how to build and test (the
   gates, as exact commands), branches and remotes, what never to run (GUIs,
   real devices, pushes), paths, and the default workspace's absolute path
   (lanes read `docs/ops/` by it). Short; facts only. It is
   untracked: if the repo had it tracked, `adopt.sh` untracked it and its old
   contents are still in history; say so in the report if the repo is public.
   The same holds for a tracked `AGENTS.md` link or agent link.
5. **Verify:**
   - `git check-ignore --no-index docs/ops/BOARD.md changelog.d/x.md
     AGENTS.md AGENTS.project.md` all print (the path need not exist, so this
     holds in Linear mode too);
   - `jj file list AGENTS.md AGENTS.project.md .pi/agents .claude/agents`
     prints nothing (a real `AGENTS.md` kept for now aside). A lane started
     before the untracking rebases past it before landing, or its tip tracks
     the file again; then `lane link <name>` gives it the links;
   - `jj st` / `git status` shows no machine-specific path (the harness
     symlinks) as added;
   - the harness sees the roles (pi: `"projectPersonas": true` in
     `~/.pi/agent/subagents.json`, and the project trusted on next launch: tell
     the human if either is missing).
6. **Commit only the tracked parts**, one commit, plain words, e.g.
   `Adopt the dev working system: changelog and roadmap at the root, the
   local links and the project's own rules file kept untracked` (no internal ids).
   Commit the files by path (`.gitignore`, `CHANGELOG.md`, `ROADMAP.md`, and
   whatever `adopt.sh` says it untracked), so nobody else's uncommitted edits
   ride along. Don't push.
7. **Report:** what was created, what moved where, what was left for the human
   (backport candidates, settings they must flip, anything ambiguous).

## Rules that still apply

- Architecture is the human's: if the repo's layout or rules conflict with the
  system in a way that needs a choice, ask; don't pick.
- Never `rm`: discarded files go to the repo's `.trash/`.
- A repo you don't own (a shared work repo): don't adopt inside it; see
  *A repo you don't own* in `dev/AGENTS.md`.
