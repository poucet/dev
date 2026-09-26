# simply/dev

A reusable way of running agent work on a repo — roles, the documents they share,
and the rules that keep them from stepping on each other.

**[AGENTS.md](AGENTS.md) is the system.** Read that. This file is only how to
adopt it.

## Adopt it in a project

Run the installer:

    ~/projects/simply/dev/adopt.sh <project>

It is idempotent and never overwrites anything that already exists. It
copies `AGENTS.md` and symlinks the role definitions, lays out the doc web of §3
(ops skeletons, `docs/scratch/`, the human channel, `.workspaces/`,
`.screenshots/`), and appends the gitignore entries those need.

**The role definitions go in the directory your coding harness reads them
from — pick the one that matches the harness.** The script auto-detects
(`--harness pi|claude|both` to override):

    # Claude Code — agents from .claude/agents
    # pi.dev — personas from .pi/agents
    #   (also needs `projectPersonas: true` in ~/.pi/agent/subagents.json,
    #    and the project must be trusted — pi prompts on launch)

The links' targets are absolute machine-specific paths, so they are gitignored;
the project's own `AGENTS.md` records the commands that recreate them (a fresh
clone runs the installer again).

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
    adopt.sh      the installer: symlinks + doc-web skeleton + gitignore, idempotent
    agents/       the eight role definitions, symlinked into each project
                  (.claude/agents for Claude Code, .pi/agents for pi.dev)

## The eight roles

`coder` · `researcher` · `tech-lead` · `designer` build in their own workspaces
and never move trunk. `integrator` works in the default workspace and is the only
one that lands. `scribe` keeps `BOARD.md` true, also in the default workspace and never at the
same time as `integrator`. `co-developer` holds the conversation and the briefs.
