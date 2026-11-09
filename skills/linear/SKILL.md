---
name: linear
description: Run a repo's plan in Linear instead of docs/ops files — set a repo up (initiative, Backlog and milestone projects, the `## Tracker` block, the README link), backfill its board, roadmap, milestones, issues and ideas into Linear, cut over, and do the everyday recording (a lane's report, opening and closing issues, promoting ideas, starting and finishing a milestone, the board query). Use when a repo's AGENTS.project.md has `## Tracker` saying `linear`, or the human asks to move a repo to Linear.
---

# Linear mode

What moves to Linear, what stays a file, and how the rest of the system reads in
Linear mode is stated once in `AGENTS.md` §2, *Linear mode*. This skill is the
how-to. It needs the Linear MCP server: an agent doing any of this is spawned
with `mcp_servers: ["linear"]`, and the tools are `mcp__linear__*`
(`list_issues`, `get_issue`, `save_issue`, `save_comment`, `list_projects`,
`save_project`, `list_initiatives`, `save_initiative`, `list_issue_statuses`,
`list_issue_labels`, …).

**Only the coordinator (or `scribe`) writes Linear.** Lanes never do, as they
never write `docs/ops/`: they report to their file and the coordinator records.

## The shape

| Linear | what it is | name |
|---|---|---|
| workspace | `simply-audio` (https://linear.app/simply-audio) | |
| team | one for every repo: `SIM` | ids `SIM-123` |
| initiative | the repo | `<repo>` |
| project, per milestone | a roadmap version; its description is what the version means | `<repo> <version> · <title>` |
| project, backlog | unscheduled issues and ideas | `<repo> · Backlog` |
| initiative + project `Ideas` | ideas that fit no repo yet | `Ideas` |

**Everything has an owner: `simply.chris.rl@gmail.com`**, the `Owner` in the
repo's `## Tracker` block. Every issue's assignee, every project's lead and
every initiative's owner is set to it whenever the coordinator creates or
records something, backfill included, so the human's "my issues" view is the
whole plan. A record found without it gets it on the next touch. The human's
second account, `christophe.poucet@gmail.com`, is for managing the workspace
only: never an assignee, lead or owner, and never the default.

| Issue field | values |
|---|---|
| assignee | the `Owner` (above); the lane is a comment, never the assignee |
| state | Backlog · Todo · In Progress · Done · Canceled · Duplicate |
| label | Bug (defect) · Improvement (rough edge) · Feature · Idea |
| priority | P1 → High · P2 → Medium · P3 → Low; none → No priority |
| title | what is wrong, or what you get; a roadmap row keeps its word label first: `DEST-MIX · Mix to any destination` |
| comment | the lane on it, a finer mark (triaged, partly shipped, paused), the verdict on close |

Project states: Planned (next), In Progress (being built), Completed (shipped),
Canceled. A completed project with its issues is what `MILESTONES.md` was.

## The `## Tracker` block

In the repo's `AGENTS.project.md`. `adopt.sh --tracker linear` appends it from
`tracker.md` beside this file, with `<repo>` filled in and the `Owner`
defaulted; fill in the two URLs
once setup has made them. The block is the switch: without it the repo is in
file mode.

URLs here are fine: `AGENTS.project.md` is tracked but a URL is a link, not an
ops id. Issue ids never go in it.

## Setup

Idempotent: look before creating, every step. Search by exact name first
(`list_initiatives` with `fields`, `list_projects` with a name filter); create
only what is missing.

Steps 1–3 set the `Owner`: initiative owner, project lead.

1. **Initiative** `<repo>`: description one line on what the repo is, its GitHub
   URL if it has a remote, and a `Standing` heading (empty) for standing
   instructions.
2. **Backlog project** `<repo> · Backlog` in team `SIM`, linked to the initiative.
3. **A project per roadmap milestone** still open, `<repo> <version> · <title>`,
   description the milestone's paragraph from `ROADMAP.md`, state Planned (or
   In Progress for the one being built), linked to the initiative.
4. **The `## Tracker` block** in `AGENTS.project.md`.
5. **The README links the initiative** where it used to point at `ROADMAP.md`
   ("What comes next: <initiative URL>").
6. **Backfill** (below), then **cutover** (below).

## Backfill

Everything comes over (open rows open, fixed and shipped Done, declined
Canceled), so the old ids stay findable.

- **Every issue's description starts with an origin line**:
  `Origin: <repo> <file> <old id>`, e.g. `Origin: tussen ISSUES.md I-007`, or
  `Origin: tussen ROADMAP.md DEST-MIX`. Then the row's text, then its notes.
- **The map**: `docs/ops/drafts/linear-map-<repo>.tsv` in the repo's default
  workspace (untracked; a backfill run from elsewhere says where it put it),
  one line per row:
  `<old id>\t<SIM id>\t<file>\t<state>`. Write it as you go, so a crash costs
  nothing.
- **Reruns are idempotent.** Before creating, look the old id up in the map; if
  it is missing there, search the initiative's issues for its origin line
  (`list_issues` with a query on `Origin: <repo> <file> <old id>`). Found →
  update, never duplicate.
- **Where each row goes**:

  | from | to |
  |---|---|
  | `ROADMAP.md` row | issue in its milestone's project; 🔄 In Progress, 🎯 Todo, 📋 ⬜ ⏸️ Backlog (⏸️ with a "paused" comment), 🔶 open with a "partly shipped" comment; label Feature |
  | `ROADMAP.md` *Deferred by decision* | issue in `<repo> · Backlog`, a comment naming the decision |
  | `MILESTONES.md` milestone | a Completed project; its ✅ rows Done issues, 🔶 rows Done with a comment, the remainder an open issue in the next project or Backlog |
  | `ISSUES.md` | Backlog, label Bug (🐛) or Improvement (🔧); 🔬 adds a "triaged" comment, 🔄 In Progress |
  | `FIXED.md` | the same, Done (✅) or Canceled (🗑️), the verdict as a comment |
  | `IDEAS.md` Inbox | Backlog, label Idea; 🎯 Todo; 🔬 / 🔶 as a comment |
  | `IDEAS.md` In-flight | into the milestone project its board row belongs to, label Idea or Feature |
  | `IDEAS.md` Done | Done (✅) or Canceled (🗑️), the answer as a comment |
  | `BOARD.md` running · next | the matching issue In Progress (a lane comment) · Todo; a row with no issue gets one |
  | `DECIDE.md`, `ASKS.md`, `DECISIONS.md` | stay files; not backfilled |

- **A row cross-referencing another** (`see I-012`) is rewritten to the SIM id
  once both exist; a second pass over the map does it.
- **Dates**: put the row's date in the description (`Found 2026-10-03`); Linear's
  own created date is the backfill's.
- Backfill reads the repo; it writes nothing in it but the map.

## Cutover checklist

- [ ] Initiative, Backlog project and open milestone projects exist (setup 1–3).
- [ ] Backfill ran clean; a rerun creates nothing; the map has a line for every
      row of every moved file. Count rows per file against issues per origin.
- [ ] Completed projects for every milestone in `MILESTONES.md`.
- [ ] The backfill map moved from wherever the backfill wrote it (the first
      runs: dev's `docs/ops/drafts/linear-map-<repo>.tsv`) into the repo's own
      `docs/ops/drafts/`.
- [ ] `## Tracker` block in `AGENTS.project.md`; README links the initiative.
- [ ] Moved files to `.trash/linear-cutover-<date>/`: `docs/ops/BOARD.md`,
      `MILESTONES.md`, `ISSUES.md`, `FIXED.md`, `IDEAS.md` (untracked: just
      `mv`), and `ROADMAP.md` from the root (tracked: `mv`, then the commit
      below records it gone).
- [ ] **One docs-only commit with explicit paths**, the trunk loop in AGENTS.md
      §4: `jj commit AGENTS.project.md README.md ROADMAP.md -m "Keep the plan in
      Linear: the roadmap leaves the repo, the README links it"`. No Linear ids
      in the message. Move trunk to it only if trunk is its parent, and not
      while an integrator holds the workspace.
- [ ] `docs/ops/` now holds DECIDE, ASKS, DECISIONS, drafts/, reports/ only.
- [ ] The board query (below) shows what `BOARD.md` showed.

## Everyday

**The board** is a query, read at every session start and before every status
answer: the initiative's issues in In Progress (running) and Todo (next),
`list_issues` filtered by the initiative's projects and those states. What
waits on the human is `DECIDE.md` and `ASKS.md`, as in file mode. Standing
instructions are in the initiative's description, under *Standing*.

**A lane starts**: its issue goes In Progress, with a comment
`Lane <name> · <clock>`. No issue yet → file one first (docs before eng).

**A lane's report arrives** (`docs/ops/reports/<lane>.md`): for each line,
- issue closed → Done, comment with the one-line verdict and the change id;
- found and not fixed → a new issue in `<repo> · Backlog`, labelled, priority
  from the report, what is wrong first;
- follow-up work → a new issue, Backlog or the milestone it belongs to;
- decision taken → `DECIDE.md` *Taken without you* or `DECISIONS.md`, as in
  file mode;
- then the report moves to `.trash/`.

**Landed**: the lane's issue goes Done the same day, verdict comment naming the
changelog entry's heading and change id. The fragment fold is unchanged.

**Won't fix / superseded**: Canceled, or Duplicate of the issue that replaced it,
with a one-line comment. Never delete an issue.

**Promote an idea**: move the issue from `<repo> · Backlog` (or `Ideas`) into a
milestone project; relabel Feature if it is now scheduled work. An `Ideas` issue
that earns a repo moves to that repo's project.

**Start a milestone**: its project goes In Progress; the next one is Planned.

**Finish a milestone**: every issue Done, Canceled or moved on; the project goes
Completed. That is the version's record; the changelog has the account. The
integrator still does not run into a version (AGENTS.md §4).

## Gotchas

- **`list_initiatives` with `includeProjects` exceeds Linear's complexity
  limit.** Ask for `fields` instead, or list projects by initiative separately.
- **States and labels by id.** Fetch them once (`list_issue_statuses`,
  `list_issue_labels` for team `SIM`) and reuse; names are not unique across
  teams.
- **Agents are not Linear users.** The lane goes in a comment; the assignee is
  always the `Owner`. Pass it on every create, and set it on update when it is
  missing.
- **No ids in commits, code or tracked docs**, Linear ids included: the
  workspace is private and a clone can't follow them.
- **The Linear tools may not be in your tool list.** In this harness a child
  spawned with `mcp_servers: ["linear"]` can still be missing `mcp__linear__*`
  from its list; they are reachable through codemode: `await
  searchTools("linear")`, then call `tools.mcp__linear__…`. Use that. Never
  read OAuth tokens from `~/.pi/agent/mcp-auth.json` or call the server by
  hand: it works, but it reads the human's credential file.
- **Lanes without the MCP server can't read Linear.** Give a lane its issue's
  text in the brief rather than the server, unless it must browse.
- **Don't close an issue you didn't see closed.** Record what the report says;
  if you can't tell whether something landed, say so in a comment and leave it
  open.
