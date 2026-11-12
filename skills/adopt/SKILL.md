---
name: adopt
description: Bring an existing repo onto the simply/dev working system by running dev's adopt.sh and reconciling what the repo already has (its own AGENTS.md, changelog, todo or board files, an old docs/ops/). Use when the human developer asks to adopt, onboard or "put dev on" a repo, or when a repo still carries the old links, AGENTS.project.md or docs/ops/.
---

# Adopt a repo onto the dev system

The system itself (its rules, the roles, the skills) is a pi package installed
once per machine (`pi install <dev repo>`); nothing of it goes into a repo.
`adopt.sh` lays down the repo's own small part; this skill is the judgement
around it: what the repo already has, what moves where, what gets committed.
It is safe to re-run (`adopt.sh` is idempotent and never overwrites).

## What adoption gives a repo

| path | what | tracked? |
|---|---|---|
| `AGENTS.md` | this repo's own rules: build, gates, branches, paths, quirks; a subdirectory may add its own | yes by default; local when the root `.gitignore` has `/AGENTS.md` (repos adopted before this layout) |
| `.pi/AGENTS.md` | the private rules: the `## Tracker`, standing instructions | no: inside `.pi/` |
| `CHANGELOG.md` | user-facing, at the root | yes |
| `ROADMAP.md` | what comes next, by version, at the root; cites no ops ids (file mode only) | yes |
| `.pi/` | local state: `reports/`, `drafts/`, `changelog.d/`, pi's sessions, the agent tree | no: its own `.gitignore` holds `*` |
| `docs/{design,research,guides,reference}/` | the tracked doc web; not made empty, a folder appears with its first file | yes |
| `.workspaces/`, `.trash/` | lane workspaces, discarded files | no: each has its own `.gitignore` holding `*` |

The starter files come from dev's `templates/`, each only where the repo has
no file of that name; a changelog the repo already keeps gets no template
beside it.

**A repo whose plan lives in Linear** (AGENTS.md §2, *Linear mode*; opt-in,
the human's call per repo) is adopted with `--tracker linear`: no `ROADMAP.md`,
and `.pi/AGENTS.md` gains a `## Tracker` section to fill in. A re-run keeps
Linear mode on its own once that section exists. Setting up the initiative and
projects and backfilling are the `linear` skill.

**A shared repo you don't own** is adopted with `--theirs`: nothing a teammate
could see, so no root `AGENTS.md` and no tracked file; the rules go in
`.pi/AGENTS.md` and lanes in `.pi/workspaces/` (AGENTS.md §2, *A repo
you don't own*).

## Steps

1. **Look before touching.** Read the repo's README, any existing `AGENTS.md`,
   `CLAUDE.md`, `CHANGELOG*`, `TODO*`, `docs/` (an old `docs/ops/` above all),
   and its build (`Cargo.toml`, `package.json`, …). Note the VCS: `jj st` (or
   `git status`). **Never adopt over uncommitted work you don't own**: if the
   working copy is dirty, ask the human developer first.
2. **Run the installer:**
   ```sh
   <dev repo>/adopt.sh <repo>                   # file mode
   <dev repo>/adopt.sh <repo> --tracker linear  # plan in Linear
   <dev repo>/adopt.sh <repo> --theirs          # a shared repo you don't own
   ```
   (`<dev repo>` is the directory this skill's `skills/` folder sits in.) It
   creates only what is missing, and lists what the old setup left behind.
3. **Reconcile what the repo had:**
   - an existing `AGENTS.md` / `CLAUDE.md` with project rules → their
     **project-specific** parts stay in the repo's `AGENTS.md` (private ones
     move to `.pi/AGENTS.md`); anything generic
     that the system lacks is reported to the human as a backport
     candidate (don't edit dev's file from here); the old file to `.trash/`
     and its tracking removed (`jj file untrack`), unless the team uses it;
   - **the old links** (`AGENTS.md` → dev's, `.pi/agents`, `.pi/skills`,
     `.claude/agents`) → `.trash/`; their root `.gitignore` lines go, except
     `/AGENTS.md` where the root `AGENTS.md` is to stay local. `adopt.sh` removes
     an `AGENTS.md` link and moves `AGENTS.project.md` into place itself;
   - **an old `docs/ops/`**: there is no plan on disk any more (AGENTS.md §2,
     *No plan on disk*). Its standing rules go into `.pi/AGENTS.md`; its
     settled decisions into what they govern (a design doc, an `AGENTS.md`);
     its open decisions, open issues and ideas to the human in one round of
     questions (Linear mode: the `linear` skill's backfill); its
     `reports/` and `drafts/` into `.pi/reports/` and `.pi/drafts/`; then the
     directory to `.trash/`;
   - `changelog.d/` fragments → `.pi/changelog.d/`, the directory to `.trash/`;
   - an existing changelog anywhere else → `CHANGELOG.md` at the root, history
     kept;
   - todo, board or issue files → as an old `docs/ops/`;
   - design or research notes → the matching `docs/` folder.
4. **Write the repo's `AGENTS.md`** if it is still the template: how to build and
   test (the gates, as exact commands), branches and remotes, what never to run
   (GUIs, real devices, pushes), paths, and the default workspace's absolute
   path (lanes write their reports into its `.pi/` by it; private, so in
   `.pi/AGENTS.md`). Short; facts only. A tracked `AGENTS.md` is public in a
   public repo: nothing private goes in it.
5. **Verify:**
   - `git check-ignore --no-index .pi/AGENTS.md .pi/reports/x.md` both print;
   - `jj file list .pi` prints nothing, and no tracked `AGENTS.md` holds the
     `## Tracker` or other private rules;
   - `jj st` / `git status` shows no machine-specific path as added;
   - `pi list` shows the dev package (tell the human if it is missing:
     `pi install <dev repo>`).
6. **Commit only the tracked parts**, one commit, plain words, e.g.
   `Adopt the dev working system: changelog and roadmap at the root, the
   project's own rules file kept untracked` (no internal ids). Commit the
   files by path (`.gitignore`, `CHANGELOG.md`, `ROADMAP.md`, and whatever
   `adopt.sh` says it untracked), so nobody else's uncommitted edits ride
   along. Don't push.
7. **Report:** what was created, what moved where, what was left for the human
   (backport candidates, anything ambiguous).

## Rules that still apply

- Architecture is the human's: if the repo's layout or rules conflict with the
  system in a way that needs a choice, ask; don't pick.
- Never `rm`: discarded files go to the repo's `.trash/`.
