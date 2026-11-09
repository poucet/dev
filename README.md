# simply/dev

A reusable way of running agent work on a repo — roles, the documents they share,
and the rules that keep them from stepping on each other.

**[AGENTS.md](AGENTS.md) is the system.** Read that. This file is only how to
adopt it.

## Requires Jujutsu (jj)

The system assumes **[jj](https://jj-vcs.github.io/jj/latest/)** as the
version-control front end: every lane works in its own `jj workspace`,
landing moves a bookmark, and the roles' commands (`jj commit`, `jj rebase`,
`jj workspace add`) are jj's. It runs on top of an ordinary git repo
(colocated), so GitHub, CI and plain `git` users see a normal git history.

    brew install jj                        # or see the install page:
    # https://jj-vcs.github.io/jj/latest/install-and-setup/
    cd <project> && jj git init --colocate # an existing git repo becomes a jj repo too

## Adopt it in a project

Run the installer:

    <path to this repo>/adopt.sh <project>

(Run it from wherever you cloned this repo; it finds its own templates and
roles relative to itself.)

It is idempotent and never overwrites anything that already exists. It:

- **links `AGENTS.md`** to this repo's (a relative symlink), and starts an
  `AGENTS.project.md` for the project's own rules: build, gates, branches,
  paths. Where the two disagree, the project file wins for that project. Both
  are **untracked**, as are the agent links below (a line each in the root
  `.gitignore`; a tracked one is untracked): they are local setup, the link
  dangles in a lane's workspace and a public clone, and the project file can
  name private infrastructure. A real `AGENTS.md` (an old copy of the
  system) is left in place and reported; `--replace-agents-md` moves it to
  `.trash/` and makes the link;
- **symlinks the role definitions** for the harness (below);
- lays out the doc web of §3 from `templates/`: `CHANGELOG.md` at the root
  (tracked), and `docs/ops/`, the one **untracked** directory of working
  state (board, decisions for the human, things for the human to run,
  issues, decisions, ideas, roadmap, status, drafts);
- makes each untracked directory (`docs/ops/`, `.workspaces/`, `.trash/`, …)
  ignore itself with its own `.gitignore` holding `*`.

**A repo can keep its plan in Linear instead** (board, roadmap, milestones,
issues, ideas, decisions; AGENTS.md §2, *Linear mode*): `adopt.sh <project>
--tracker linear` skips those files and adds a `## Tracker` section to
`AGENTS.project.md`. The **`linear` skill** (`skills/linear/`) sets up the
initiative and projects, backfills, and cuts over.

For a repo that already has its own `AGENTS.md`, changelog or todo files, use
the **`adopt` skill** (`skills/adopt/`): it runs the installer and moves what
the repo had to where it belongs.

**The role definitions go in the directory your coding harness reads them
from — pick the one that matches the harness.** The script auto-detects
(`--harness pi|claude|both` to override):

    # Claude Code — agents from .claude/agents
    # pi.dev — personas from .pi/agents
    #   (also needs `projectPersonas: true` in ~/.pi/agent/subagents.json,
    #    and the project must be trusted — pi prompts on launch)

The links are gitignored: their targets are machine-specific. A fresh clone runs
the installer again; a lane's workspace gets absolute links from `lane new`
(`skills/lane/`), and `lane link <name>` remakes them in an existing one.

The role files are shared verbatim between harnesses, so their frontmatter must
stay valid for every harness that reads them: **omit `tools`** (both harnesses
then allow all tools — Claude Code by inheritance, pi because it has no
allow-all token and treats a `tools:` list as literal names). Per-model or
per-role tool restrictions are set by the harness config, not the role files.

Lay the project out per the default structure in §3.

## A repo you don't own

For a shared repo you don't control (a work repo, reviewed by people who never
opted into any of this), don't run the installer inside it. Run it into a
sibling `ops/` directory instead, next to a plain clone of the shared repo —
see *A repo you don't own* in [AGENTS.md](AGENTS.md) §2. Nothing of this
system ever enters the shared repo except code, its tests, and a `CHANGELOG.md`
if the team already keeps one.

## Layout

    AGENTS.md     the system: roles, the doc web, the directory structure, the rules
    adopt.sh      the installer: links, templates, self-ignoring dirs; idempotent
    templates/    the starter files adopt.sh copies (CHANGELOG.md,
                  AGENTS.project.md, docs/ops/*.md)
    agents/       the eight role definitions, symlinked into each project
                  (.claude/agents for Claude Code, .pi/agents for pi.dev)
    skills/       adopt (bring an existing repo onto the system),
                  linear (keep a repo's plan in Linear),
                  lane (lane workspaces), brainstorm (the co-developer's
                  own method)

## The eight roles

`coder` · `researcher` · `tech-lead` · `designer` build in their own workspaces
and never move trunk. `integrator` works in the default workspace and is the only
one that lands. `scribe` keeps `BOARD.md` true, also in the default workspace and never at the
same time as `integrator`. `co-developer` holds the conversation and the briefs.
