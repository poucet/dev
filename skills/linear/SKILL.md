---
name: linear
description: Run a repo's plan in Linear — set a repo up (initiative, Backlog and milestone projects, the `## Tracker` block, the README link), backfill its roadmap and any old docs/ops/ files into Linear, cut over, and do the everyday recording (a lane's report, opening and closing issues, filing and closing decisions, promoting ideas, starting and finishing a milestone, the board query, publishing design and research documents and working the human's comments on them, mirroring the changelog into Linear with the `changelog-sync` script). Use when a repo's AGENTS.md files (the nearest `## Tracker` up from the working directory) say `linear`, or the human asks to move a repo to Linear.
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
`list_issue_labels`, `list_documents`, `get_document`, `save_document`,
`list_comments`, `prepare_file_upload`, …). Read a tool's schema before its
first use in a session; names and fields move.

**Tech-lead and researcher lanes write their own Linear Documents** (AGENTS.md
*Linear Documents*, *The boundaries hold*); issues, Decision issues, state
changes and the attach-and-comment step stay the coordinator's (or `scribe`'s).
Every other role never writes Linear: they report to their file in
`.pi/reports/` and the coordinator records, bar the integrator's changelog
sync (*Changelog mirror*, below).

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
| document | a proposal, open design or research (AGENTS.md *Linear Documents*); in the project it serves, an issue when it serves one only, the initiative when it spans projects; icon its status emoji | what it is about, sentence case: `Mixing to any destination` |

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
its name starts with. So **each initiative's colour is its own**: pick one no
other initiative has (list them first).

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

**A decision is an issue labelled Decision**:

| field | value |
|---|---|
| assignee | whoever decides: today always the `Owner` |
| project | the one it concerns: a milestone project, `<repo> · Backlog` when none fits, `dev · Backlog` for the system itself |
| title | the question in plain words |
| description | a question that answers itself (AGENTS.md *Asking the human*): what is being decided, in one plain sentence; the options, each with what it changes; the recommendation first; what it blocks |
| relations | **blocks** each issue that waits on it, so nothing is started on an open question |
| state | open (Todo) while it waits; Done when answered; Canceled when moot |
| last comment | on Done: the answer and its rationale, with the change id of the commit that folds it in once there is one |

**Every initiative has a project view `Outstanding`** (projects not completed
or canceled) **and every open project an issue view `Outstanding`** (issues not
done, canceled or duplicate), shared, in its initiative's icon and colour. The
tab is made by hand in Linear's UI: neither the MCP nor the public GraphQL API
can add a tab to a project or initiative (`customViewCreate` with `projectId`
makes a view attached to nothing, which appears nowhere). Workspace views the
API can make, with a personal API key the human provides.

**Every Backlog project has a workspace issue view `<initiative> · backlog`**
(lower-case `backlog`, so it reads apart from the project; `Ideas · backlog`
for `Ideas · Backlog`), listed under https://linear.app/simply-audio/views/issues:
shared, the initiative's icon and colour, description `<initiative> · Backlog
issues not done, canceled or duplicate`, layout list ordered by priority (the
default). Its filter, by project id:
`{"and":[{"project":{"id":{"eq":"<project id>"}}},{"state":{"type":{"nin":["completed","canceled","duplicate"]}}}]}`.
The MCP has no view tool: make it with GraphQL `customViewCreate` (`name`,
`description`, `icon`, `color`, `shared: true`, `filterData`) and the
`LINEAR_API_KEY` from the environment, after checking `customViews` for the
name.

Two saved views make it a channel (made once in Linear's UI, if the tools
can't): **Decisions open** (label Decision, not Done or Canceled), what waits
on the human; and **Decisions** (label Decision, Done, newest first), the
log.

## The `## Tracker` block

In the repo's local `.pi/AGENTS.md` (untracked; AGENTS.md, *A project's own
rules*), or a root `AGENTS.md` the repo keeps local: writing the block commits
nothing. A subdirectory's own `.pi/AGENTS.md` may carry its own block: the
nearest one up from where you work applies, so one repo can feed several
initiatives, teams or projects. Start it from `tracker.md` beside this file, with `<repo>` filled in and the
`Owner` defaulted; fill in the two URLs
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
2. **Backlog project** `<repo> · Backlog` in the Tracker's team, linked to the
   initiative, and its workspace view `<repo> · backlog` (above).
3. **A project per roadmap milestone** still open, `<repo> · <title>`,
   description the milestone's paragraph from `ROADMAP.md`, state Planned (or
   In Progress for the one being built), linked to the initiative.
4. **The `## Tracker` block** in `.pi/AGENTS.md` (untracked).
5. **The README links the initiative** where it used to point at `ROADMAP.md`
   ("What comes next: <initiative URL>").
6. **Backfill** (below), then **cutover** (below).
7. **The first changelog sync**: `changelog-sync` from the repo (*Changelog
   mirror*, below) creates the initiative's `Changelog` document.

## Backfill

Everything comes over (open rows open, fixed and shipped Done, declined
Canceled), so the old ids stay findable.

- **Every issue's description starts with an origin line**:
  `Origin: <repo> <file> <old id>`, e.g. `Origin: tussen ISSUES.md I-007`, or
  `Origin: tussen ROADMAP.md DEST-MIX`, or `Origin: tussen DECISIONS.md D-042`.
  Then the row's text, then its notes.
- **The map**: `.pi/drafts/linear-map-<repo>.tsv` in the repo's default
  workspace (untracked; a backfill run from elsewhere says where it put it),
  one line per row:
  `<old id>\t<file>\t<linear id>\t<state>` (header `old_id source_file linear-id state`). Write it as you go, so a crash costs
  nothing.
- **Reruns are idempotent.** Before creating, look the old id up in the map; if
  it is missing there, list the initiative's issues and match its origin line
  (`Origin: <repo> <file> <old id>`) yourself: `list_issues`' query doesn't
  search descriptions. Found → update, never duplicate.
- **Where each row goes** (the files other than `ROADMAP.md` and
  `CHANGELOG.md` are an old `docs/ops/`, from before AGENTS.md §2's *No plan on
  disk*):

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
  | `ASKS.md` | not backfilled: what is still open goes to the human, in `.pi/drafts/` |

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
- [ ] The backfill map is in the repo's own `.pi/drafts/`.
- [ ] The `## Tracker` block is in a local file: `jj file list` does not
      list the file holding it.
- [ ] `## Tracker` block in `.pi/AGENTS.md` (untracked: nothing to
      commit); README links the initiative.
- [ ] Old ids left in the local `AGENTS.md` files and `.pi/drafts/` (`D-042`,
      `I-007`) rewritten to their Linear ids from the map.
- [ ] Moved to `.trash/linear-cutover-<date>/`: what is left of an old
      `docs/ops/` (untracked: just `mv`; its `reports/` and `drafts/` go to
      `.pi/` first), and `ROADMAP.md` from the root (tracked: `mv`, then the
      commit below records it gone).
- [ ] **One docs-only commit with explicit paths**, the trunk loop in AGENTS.md
      §4: `jj commit README.md ROADMAP.md -m "Keep the plan in Linear: the
      roadmap leaves the repo, the README links it"`. No Linear ids in the
      message. Move trunk to it only if trunk is its parent, and not while an
      integrator holds the workspace.
- [ ] No `docs/ops/` is left.
- [ ] The board query (below) shows what runs and what's next; the
      open-decisions view shows every open question.

## Everyday

**The board** is a query, read at every session start and before every status
answer: the initiative's issues in In Progress (running) and Todo (next),
`list_issues` filtered by the initiative's projects and those states. What
waits on the human is the open-decisions view. Standing
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
`Lane <name> · <clock>`, in the same turn as the spawn. No issue yet → file
one first (docs before eng). This holds for every spawned agent doing work,
research and design rounds included.

**A lane's report arrives** (`.pi/reports/<lane>.md`): for each line,
- issue closed → Done, comment with the one-line verdict and the change id;
- found and not fixed → a new issue in `<repo> · Backlog`, labelled, priority
  from the report, what is wrong first;
- follow-up work → a new issue, Backlog or the milestone it belongs to;
- question for the human → an open Decision issue (above);
- decision taken, small and contained → a Decision issue created Done, saying
  so;
- then the report moves to `.trash/`.

**Landed**: the lane's issue goes Done the same day, verdict comment naming the
changelog entry's heading and change id. The fragment fold is unchanged; after
it, the integrator syncs the changelog mirror (below).

## Changelog mirror

The rule is AGENTS.md *The changelog mirror*: trunk's `CHANGELOG.md` is copied
into a document titled `Changelog` on the initiative, generated and never
edited in Linear. The script beside this file does it:

    changelog-sync [--dry-run] [repo-dir]     # repo-dir defaults to .

- **Skips, exit 0**, a repo whose nearest `## Tracker` doesn't say `linear`
  (`skipped: no linear tracker`), or that has no changelog on trunk. It looks
  for `CHANGELOG.md`, then `docs/CHANGELOG.md`, then `docs/ops/CHANGELOG.md`.
- **The initiative** comes from the Tracker's `Initiative:` line, by the slug
  in its URL, else by its name, else the repo directory's name.
- **Idempotent**: the banner carries a hash of what was generated; the same
  hash means `unchanged` and no write. A changed changelog overwrites the
  whole document; a missing one is created, icon 📜.
- **Size**: Linear refuses document content over 250,000 characters. A longer
  changelog keeps its newest entries, cut at a heading, and ends with a line
  naming the file that holds the rest.
- `--dry-run` prints the initiative, whether the document exists, the size and
  whether it changed, and writes nothing. It needs `$LINEAR_API_KEY` (GraphQL,
  no `Bearer` prefix), not the MCP server.

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

## Documents

The rules are AGENTS.md *Linear Documents*: status in two marks, where a
document attaches. **Tech-lead and researcher lanes write documents directly**;
the coordinator records their issues and attaches them.

**A tech-lead or researcher lane** creates or revises its Linear Document:
`list_documents` for the title first, so a rerun updates rather than
duplicates; then `save_document` with the title, the markdown, the icon (the
status emoji) and the project (or the issue, or the initiative). First line is
the banner, one sentence: `🎯 Proposed: waiting on the encoder decision.` It
@mentions each issue it covers by bare id in the body, uploads figures with
`prepare_file_upload` and embeds them (Mermaid stays inline, Linear renders
it), and puts the document's link in its report. The coordinator records: for
each issue the lane lists, save_comment on that issue naming the document, so
the link shows on both sides; then attach the document to the project with
save_document's `projectIds` (or `issueIds`, or `initiativeId`).

**Publish a designer's draft** (`.pi/drafts/<lane>.md`, named in its report):
designers still draft because their docs are figures and before/after, not text.
Same flow as above: list_documents, save_document, upload figures,
attach, comment each issue, move the draft to `.trash/`, and the human gets the
link in chat.

**Change a status**: icon and banner together, in one `save_document`. The
banner says what the status rests on:

- 🧪 → 🎯: the Decision issues it waits on, filed first and @mentioned;
- 🎯 → 🔨: the decisions answered and folded into the text; the issues building
  it;
- 🔨 → ✅: the repo paths that now describe it (below);
- any → 🪦: why, and the document that replaces it, @mentioned or linked.

**"Address my comments"**: `list_comments` with the document's id; an inline
comment carries `quotedText`, the passage it is about. Read every open thread
before changing anything, then revise with `save_document`, preferring a
`patch` to a whole-body rewrite so the human's other anchors survive. Reply in
each thread (`save_comment` with `parentId` set to the thread's root) with
what changed (or why not, which is a question back to him, not a refusal).
Then resolve the thread. The MCP has no tool for it, so it is one GraphQL
call with `$LINEAR_API_KEY` (no `Bearer` prefix):

    curl -s https://api.linear.app/graphql -H "Authorization: $LINEAR_API_KEY" \
      -H 'Content-Type: application/json' \
      -d '{"query":"mutation($id:String!){commentResolve(id:$id){success}}","variables":{"id":"<root comment id>"}}'

Leave a thread open when your reply asks him something. A comment that settles what the design decides
is his decision: fold it in. One that opens a question he must answer goes
back to him as a Decision issue, @mentioned where the question sits. A revision big enough to need a tech-lead
goes to one as a `followup`, the thread texts in the brief; its revised draft
comes back and you save, reply and resolve.

**A design is built**: the building lane's report says which repo docs now
describe it (`docs/design/` as built, guides, reference), or a docs-only commit
writes them; then the document goes ✅, its banner naming those paths, and
its issues are Done as usual. Nothing in the repo links back.

**An old in-repo doc is touched**: whatever describes the system as it is now
stays in, or moves into, the repo's docs; the rest (proposals, open questions,
research) becomes a document with a status, and the file's moved parts go in
the same docs-only commit. One doc at a time, as work reaches it; never a bulk
migration.

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
- **No ids in commits, code or tracked docs**, Linear ids and document links
  included: the workspace is private and a clone can't follow them. A document
  names repo files by path; the repo never names a document.
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
