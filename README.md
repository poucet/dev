# simply/dev

A reusable way of running agent work on a repo — roles, the documents they share,
and the rules that keep them from stepping on each other.

**[extension/AGENTS.md](extension/AGENTS.md) is the system.** Read that. This file is only how to
install and adopt it.

## Requires Jujutsu (jj) and pi

The system assumes **[jj](https://jj-vcs.github.io/jj/latest/)** as the
version-control front end: every lane works in its own `jj workspace`,
landing moves a bookmark, and the roles' commands (`jj commit`, `jj rebase`,
`jj workspace add`) are jj's. It runs on top of an ordinary git repo
(colocated), so GitHub, CI and plain `git` users see a normal git history.

    brew install jj                        # or see the install page:
    # https://jj-vcs.github.io/jj/latest/install-and-setup/
    cd <project> && jj git init --colocate # an existing git repo becomes a jj repo too

The harness is **[pi](https://pi.dev)**, with the `subagent` tool from
simply-pi (it reads the roles from this package's `pi.personas`).

## Install it, once per machine

This repo is a pi package:

    pi install <path to this repo>

A local path is loaded in place, so edits here reach every session on the next
start or `/reload`. The package brings:

- **the rules**: an extension puts `extension/default-agent.md` and the
  system, [extension/AGENTS.md](extension/AGENTS.md), in front of every
  session, then each directory's own `AGENTS.md` from the outermost down to the
  working directory, each followed by its local `.pi/AGENTS.md`. The more
  specific comes later and wins. It also gives a repo's `.pi/` its
  `.gitignore` of `*`;
- **the eight roles** (`agents/`), as subagent personas, through `pi.personas`;
- **the skills** (`skills/`).

Nothing is linked into a repo, and no project trust or `projectPersonas` setting
is needed for any of it.

To keep pi's sessions with the repo they belong to, set in
`~/.pi/agent/settings.json`:

    "sessionDir": ".pi/sessions"

(relative paths resolve from the directory pi starts in, so start pi at the repo
root). The agent tree already lives in `<repo>/.pi/subagents`.

## Adopt it in a project

    <path to this repo>/adopt.sh <project>                   # file mode
    <path to this repo>/adopt.sh <project> --tracker linear  # plan in Linear
    <path to this repo>/adopt.sh <project> --theirs          # a shared repo you don't own

It is idempotent and never overwrites anything that already exists. It gives
the repo a starter `AGENTS.md` for its own rules (build, gates, branches,
paths; tracked, or local if the root `.gitignore` has `/AGENTS.md`), a local
`.pi/AGENTS.md` for the private ones (the tracker, standing rules), a tracked
`CHANGELOG.md` and, in file mode, `ROADMAP.md`, and
the self-ignoring local directories `.pi/`, `.workspaces/` and `.trash/`. It
lists what an older setup left behind (`AGENTS.md` links, `.pi/agents`,
`docs/ops/`, `changelog.d/`).

**A repo can keep its plan in Linear** (AGENTS.md §2, *Linear mode*): the
**`linear` skill** (`skills/linear/`) sets up the initiative and projects,
backfills, and cuts over.

For a repo that already has its own `AGENTS.md`, changelog, todo files or an old
`docs/ops/`, use the **`adopt` skill** (`skills/adopt/`): it runs the installer
and moves what the repo had to where it belongs.

The role files' frontmatter omits `tools`, so a role inherits every tool;
per-model or per-role tool restrictions are set by the harness config, not the
role files.

## Layout

    package.json  the pi package manifest: extension, skills, personas
    extension/    the extension that loads the rules; AGENTS.md (the system),
                  default-agent.md
    adopt.sh      the installer: starter AGENTS.md files, self-ignoring dirs
    templates/    the starter files adopt.sh copies
    agents/       the eight role definitions (subagent personas)
    skills/       adopt (bring a repo onto the system), linear (keep a repo's
                  plan in Linear), lane (lane workspaces), brainstorm (the
                  co-developer's own method), rust-build-speed

## The eight roles

`coder` · `researcher` · `tech-lead` · `designer` build in their own workspaces
and never move trunk. `integrator` works in the default workspace and is the only
one that lands. `scribe` keeps a Linear-based repo's issues true, never at the
same time as `integrator`. `foreman` drives a whole track. `co-developer` holds
the conversation and the briefs.
