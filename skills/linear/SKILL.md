---
name: linear
description: Run a repo's plan in Linear instead of docs/ops files — set a repo up (initiative, Backlog and milestone projects, the `## Tracker` block, the README link), backfill its board, roadmap, milestones, issues, ideas and decisions into Linear, cut over, and do the everyday recording (a lane's report, opening and closing issues, filing and closing decisions, promoting ideas, starting and finishing a milestone, the board query). Use when a repo's AGENTS.project.md has `## Tracker` saying `linear`, or the human asks to move a repo to Linear.
---

# Linear mode

What moves to Linear, what stays a file, and how the rest of the system reads in
Linear mode is stated once in `AGENTS.md` §2, *Linear mode*. This skill is the
how-to. It needs the Linear MCP server: an agent doing any of this is spawned with
`mcp_servers: ["linear"]` and calls the tools through codemode
(`await searchTools("linear")`, then `tools.mcp__linear__…`). The tools are
`mcp__linear__*`
(`list_issues`, `get_issue`, `save_issue`, `save_comment`, `list_projects`,
`save_project`, `list_initiatives`, `save_initiative`, `list_issue_statuses`,
`list_issue_labels`, …).

**Only the coordinator (or `scribe`) writes Linear.** Lanes never do, as they
never write `docs/ops/`: they report to their file and the coordinator records.

## The shape

| Linear | what it is | name |
|---|---|---|
| workspace | `simply-audio` (https://linear.app/simply-audio) | |
| team | `AUDIO` (simply-audio) for every repo, except where the repo's Tracker names its own (lumina: `LUMINA`; dev, the working system: `DEV`) | ids `AUDIO-123`, `LUMINA-12`, `DEV-4` |
| initiative | the repo | `<repo>` |
| project, per roadmap milestone | a milestone of the roadmap; its description is what the milestone means; **no version number in the name** | `<repo> · <title>` |
| project milestone, per release | a release inside the project it shipped from, `x.y.0` included; description what it brought, target date its ship date | `<x.y.z> · <title>` |
| project, backlog | unscheduled issues and ideas; exactly one per initiative | `<repo> · Backlog` |
| initiative `Ideas`, project `Ideas · Backlog` | ideas that fit no repo yet | |
| initiative `dev`, project `dev · Backlog` | changes to and decisions about the working system itself | |

**Every project is `<initiative> · <title>`**, and nothing else goes before the
`·`: not a version (`0.9`), a horizon (`H7`) or a word like `next`. A version
is set at the cut, so naming a project after one means renumbering it when
plans move; the version lives in the release milestones instead. A project
from before this rule whose version shows nowhere else carries it on the first
line of its description (`**Version:** 0.7`, `**Planned version:** 0.9`).
An initiative's projects are its Backlog and its milestones, nothing else: a
standing theme ("cross-cutting", "alongside the milestones") is issues in the
Backlog, not a project. Titles are sentence case (`Load & hear`, not `Load &
Hear`). A project takes its initiative's colour and icon, so a view or a
roadmap reads by repo at a glance; a project in two initiatives takes the one
its name starts with.

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
| label | Bug (defect) · Improvement (rough edge) · Feature · Idea · Decision |
| priority | P1 → High · P2 → Medium · P3 → Low; none → No priority |
| title | what is wrong, or what you get; a roadmap row keeps its word label first: `DEST-MIX · Mix to any destination` |
| comment | the lane on it, a finer mark (triaged, partly shipped, paused), the verdict on close |

Project states: Planned (next), In Progress (being built), Completed (shipped),
Canceled. A completed project with its issues is what `MILESTONES.md` was.

**A release is a project milestone, never a project.** Each release is a
**project milestone** in the project it shipped from, `0.9.3 · A tidier
tree…`; a project with a single release still gets its milestone. An issue
that ships in a release carries that release's milestone. Each shipped release
also gets a project status update on its project: `<x.y.z> · <title> —
shipped <date>`, then what it brought.

**A decision is an issue labelled Decision** (what was `DECIDE.md` and
`DECISIONS.md`):

| field | value |
|---|---|
| assignee | whoever decides: today always the `Owner` |
| project | the one it concerns: a milestone project, `<repo> · Backlog` when none fits, `dev · Backlog` for the system itself |
| title | the question in plain words |
| description | what a `DECIDE.md` row held (AGENTS.md *A `DECIDE.md` row answers itself*): what is being decided, in one plain sentence; the options, each with what it changes; the recommendation first; what it blocks |
| relations | **blocks** each issue that waits on it, so nothing is started on an open question |
| state | open (Todo) while it waits; Done when answered; Canceled when moot |
| last comment | on Done: the answer and its rationale, with the change id of the commit that folds it in once there is one |

**Every initiative has a project view `Outstanding`** (projects not completed
or canceled) **and every project an issue view `Outstanding`** (issues not
done, canceled or duplicate), shared, in its initiative's icon and colour. The
MCP has no view tools: a new initiative or project gets its view from dev's
`docs/ops/drafts/linear-views.py` (idempotent; needs a personal API key) or by
hand.

Two saved views make it a channel (made once in Linear's UI, if the tools
can't): **Decisions open** (label Decision, not Done or Canceled), what waits
on the human beside `ASKS.md`; and **Decisions** (label Decision, Done, newest
first), the log `DECISIONS.md` was.

## The `## Tracker` block

In the repo's `AGENTS.project.md`, which is untracked (AGENTS.md, *A project's
own rules*): writing the block commits nothing. `adopt.sh --tracker linear` appends it from
`tracker.md` beside this file, with `<repo>` filled in and the `Owner`
defaulted; fill in the two URLs
once setup has made them. The block is the switch: without it the repo is in
file mode.

The block can name the private workspace and its URLs because the file never
reaches a clone. Issue ids still don't go in it: they go stale, and the plan is
in Linear, not here.

## Setup

Idempotent: look before creating, every step. Search by exact name first
(`list_initiatives` with `fields`, `list_projects` with a name filter); create
only what is missing.

Steps 1–3 set the `Owner`: initiative owner, project lead.

1. **Initiative** `<repo>`: description one line on what the repo is, its GitHub
   URL if it has a remote, and a `Standing` heading (empty) for standing
   instructions.
2. **Backlog project** `<repo> · Backlog` in the Tracker's team, linked to the initiative.
3. **A project per roadmap milestone** still open, `<repo> · <title>`,
   description the milestone's paragraph from `ROADMAP.md`, state Planned (or
   In Progress for the one being built), linked to the initiative.
4. **The `## Tracker` block** in `AGENTS.project.md` (untracked; re-run
   `adopt.sh` first if the root `.gitignore` lacks `/AGENTS.project.md`).
5. **The README links the initiative** where it used to point at `ROADMAP.md`
   ("What comes next: <initiative URL>").
6. **Backfill** (below), then **cutover** (below).

## Backfill

Everything comes over (open rows open, fixed and shipped Done, declined
Canceled), so the old ids stay findable.

- **Every issue's description starts with an origin line**:
  `Origin: <repo> <file> <old id>`, e.g. `Origin: tussen ISSUES.md I-007`, or
  `Origin: tussen ROADMAP.md DEST-MIX`, or `Origin: tussen DECISIONS.md D-042`.
  Then the row's text, then its notes.
- **The map**: `docs/ops/drafts/linear-map-<repo>.tsv` in the repo's default
  workspace (untracked; a backfill run from elsewhere says where it put it),
  one line per row:
  `<old id>\t<file>\t<linear id>\t<state>` (header `old_id source_file linear-id state`). Write it as you go, so a crash costs
  nothing.
- **Reruns are idempotent.** Before creating, look the old id up in the map; if
  it is missing there, list the initiative's issues and match its origin line
  (`Origin: <repo> <file> <old id>`) yourself: `list_issues`' query doesn't
  search descriptions. Found → update, never duplicate.
- **Where each row goes**:

  | from | to |
  |---|---|
  | `ROADMAP.md` row | issue in its milestone's project; 🔄 In Progress, 🎯 Todo, 📋 ⬜ ⏸️ Backlog (⏸️ with a "paused" comment), 🔶 open with a "partly shipped" comment; label Feature |
  | `ROADMAP.md` *Deferred by decision* | issue in `<repo> · Backlog`, a comment naming the decision |
  | `MILESTONES.md` milestone | a Completed project `<repo> · <title>`; each release in it (`0.9.3`) is a project milestone, not a project, with a status update carrying its account; its ✅ rows Done issues carrying that milestone, 🔶 rows Done with a comment, the remainder an open issue in the next project or Backlog |
  | `CHANGELOG.md` release with no milestone row | a project milestone in the project it shipped from, and a status update with what it brought |
  | `ISSUES.md` | Backlog, label Bug (🐛) or Improvement (🔧); 🔬 adds a "triaged" comment, 🔄 In Progress |
  | `FIXED.md` | the same, Done (✅) or Canceled (🗑️), the verdict as a comment (in a backfill, the description may carry it instead) |
  | `IDEAS.md` Inbox | Backlog, label Idea; 🎯 Todo; 🔬 / 🔶 as a comment |
  | `IDEAS.md` In-flight | into the milestone project its board row belongs to, label Idea or Feature |
  | `IDEAS.md` Done | Done (✅) or Canceled (🗑️), the answer as a comment |
  | `BOARD.md` running · next | the matching issue In Progress (a lane comment) · Todo; a row with no issue gets one |
  | `DECIDE.md` *Open now* | an open Decision issue (shape above) in the project it concerns; its *blocks* become blocking relations on the second pass |
  | `DECIDE.md` *Taken without you* | a Decision issue created Done, the call and its alternative in the description, a comment "Taken without you; reopen to reverse" |
  | `DECISIONS.md` | a Done Decision issue: the decision as the title, the rationale as its last comment with the row's clock and change id; ♻️ superseded adds a comment naming the issue that superseded it, ❓ reopened stays open |
  | `ASKS.md` | stays a file; not backfilled |

- **A row cross-referencing another** (`see I-012`, a decision's *blocks*) is
  rewritten to the Linear id once both exist, and a decision's blocks become
  relations; a second pass over the map does it.
- **Dates**: put the row's date in the description (`Found 2026-10-03`); Linear's
  own created date is the backfill's.
- Backfill reads the repo; it writes nothing in it but the map.

## Cutover checklist

- [ ] Initiative, Backlog project and open milestone projects exist (setup 1–3).
- [ ] Backfill ran clean; a rerun creates nothing; the map has a line for every
      row of every moved file. Count rows per file against issues per origin.
- [ ] Completed projects for every milestone in `MILESTONES.md`, with a
      project milestone and a status update per release in it, and no project
      per release.
- [ ] The backfill map moved from wherever the backfill wrote it (the first
      runs: dev's `docs/ops/drafts/linear-map-<repo>.tsv`) into the repo's own
      `docs/ops/drafts/`.
- [ ] `AGENTS.md`, `AGENTS.project.md` and the agent links are untracked:
      `jj file list AGENTS.md AGENTS.project.md .pi/agents .claude/agents`
      prints nothing (else run `adopt.sh` and commit what it names first; a
      real `AGENTS.md`, an old copy, moves its rules into `AGENTS.project.md`
      and is replaced with `adopt.sh --replace-agents-md`).
- [ ] `## Tracker` block in `AGENTS.project.md` (untracked: nothing to
      commit); README links the initiative.
- [ ] Old ids left in `AGENTS.project.md` and `docs/ops/drafts/` (`D-042`,
      `I-007`) rewritten to their Linear ids from the map.
- [ ] Moved files to `.trash/linear-cutover-<date>/`: `docs/ops/BOARD.md`,
      `MILESTONES.md`, `ISSUES.md`, `FIXED.md`, `IDEAS.md`, `DECIDE.md`,
      `DECISIONS.md` (untracked: just `mv`), and `ROADMAP.md` from the root
      (tracked: `mv`, then the commit below records it gone).
- [ ] **One docs-only commit with explicit paths**, the trunk loop in AGENTS.md
      §4: `jj commit README.md ROADMAP.md -m "Keep the plan in Linear: the
      roadmap leaves the repo, the README links it"`. No Linear ids in the
      message. Move trunk to it only if trunk is its parent, and not while an
      integrator holds the workspace.
- [ ] `docs/ops/` now holds ASKS.md, drafts/, reports/ only.
- [ ] The board query (below) shows what `BOARD.md` showed; the open-decisions
      view shows what `DECIDE.md` *Open now* showed.

## Everyday

**The board** is a query, read at every session start and before every status
answer: the initiative's issues in In Progress (running) and Todo (next),
`list_issues` filtered by the initiative's projects and those states. What
waits on the human is the open-decisions view and `ASKS.md`. Standing
instructions are in the initiative's description, under *Standing*.

**File a decision** (a lane asked, a design doc left a question open, a call is
expensive to reverse): a Decision issue, shape above, before chat mentions it.
Link it as **blocking** every issue that waits on it, and leave those issues
where they are: the relation is what stops a lane being started on them. The
lane's report holds its question; the issue is yours to write, a lane never
files one.

**A decision is answered**: the answer and its rationale go in a comment, the
issue goes Done (the blocked issues are free), and the *what* is folded into
the design doc, AGENTS.md or the skill text in the next commit, as in file
mode. A call taken without the human is a Decision issue created Done, its
description saying so with the alternative; he reverses it by reopening.

**A lane starts**: its issue goes In Progress, with a comment
`Lane <name> · <clock>`. No issue yet → file one first (docs before eng).

**A lane's report arrives** (`docs/ops/reports/<lane>.md`): for each line,
- issue closed → Done, comment with the one-line verdict and the change id;
- found and not fixed → a new issue in `<repo> · Backlog`, labelled, priority
  from the report, what is wrong first;
- follow-up work → a new issue, Backlog or the milestone it belongs to;
- question for the human → an open Decision issue (above);
- decision taken, small and contained → a Decision issue created Done, saying
  so;
- then the report moves to `.trash/`.

**Landed**: the lane's issue goes Done the same day, verdict comment naming the
changelog entry's heading and change id. The fragment fold is unchanged.

**Won't fix / superseded**: Canceled, or Duplicate of the issue that replaced it,
with a one-line comment. Never delete an issue.

**Promote an idea**: move the issue from `<repo> · Backlog` (or `Ideas · Backlog`) into a
milestone project; relabel Feature if it is now scheduled work. An `Ideas` issue
that earns a repo moves to that repo's project.

**Start a milestone**: its project goes In Progress; the next one is
Planned.

**Ship a release** (`x.y.z`): a project milestone `<x.y.z> · <title>` in the
project it shipped from, target date the ship date; the issues that shipped in it carry
it; a status update `<x.y.z> · <title> — shipped <date>` says what it brought.
Never a project of its own.

**Finish a milestone**: every issue Done, Canceled or moved on; the project goes
Completed. That is the milestone's record; the changelog has the account. The
integrator still does not run into a version (AGENTS.md §4).

## Gotchas

- **The free plan caps a workspace at 250 issues**, Done and Canceled ones
  included. A backfill of a mature repo goes past it, and the next create
  fails partway. Check the plan and count the rows before a backfill.
- **Bulk writes run concurrently, never one call at a time.** A backfill or a
  re-sort is hundreds of saves; a serial loop spends most of an hour waiting on
  round trips. Run about eight at once (a thread pool, or `Promise.allSettled`
  in chunks), check every result, and back off and retry on a rate-limit
  error. Linear caps requests per user per hour, so pace a very large job
  rather than firing it all at once.
- **Inside Linear, name another issue by its bare id** (`AUDIO-123`) in a
  description or comment, never `[AUDIO-123](https://…)`: Linear renders the
  bare id as a live reference with the issue's title and status, a URL link as
  dead text. URLs are for chat and files (AGENTS.md *Referring to the human's
  points*).
- **`list_issues`' `query` matches titles, not descriptions.** To find an
  issue by its origin line, list the initiative's issues and match the line
  yourself; a rerun that relies on the query creates duplicates.
- **`list_initiatives` with `includeProjects` exceeds Linear's complexity
  limit.** Ask for `fields` instead, or list projects by initiative separately.
- **States and labels by id.** Fetch them once (`list_issue_statuses`,
  `list_issue_labels` for the team) and reuse; names are not unique across
  teams.
- **Agents are not Linear users.** The lane goes in a comment; the assignee is
  always the `Owner`. Pass it on every create, and set it on update when it is
  missing.
- **No ids in commits, code or tracked docs**, Linear ids included: the
  workspace is private and a clone can't follow them.
- **The Linear tools live behind codemode.** They are not in the direct tool
  list, for the coordinator or a child spawned with `mcp_servers:
  ["linear"]`: call `await searchTools("linear")`, then `tools.mcp__linear__…`
  inside codemode. Never read OAuth tokens from `~/.pi/agent/mcp-auth.json` or
  call the server by hand.
- **Lanes without the MCP server can't read Linear.** Give a lane its issue's
  text in the brief rather than the server, unless it must browse.
- **Don't close an issue you didn't see closed.** Record what the report says;
  if you can't tell whether something landed, say so in a comment and leave it
  open.
