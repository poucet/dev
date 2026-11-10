# The working system

A reusable way of running agent work on a repo. Nothing here is specific to one
project. A project adopts it with `adopt.sh` (idempotent: it creates the starter
docs, links AGENTS.md relative to dev's, starts an untracked `AGENTS.project.md`
beside it, and symlinks the agents) or by hand. The role definitions go in the directory
the coding harness reads them from (Claude Code: `.claude/agents`; pi.dev:
`.pi/agents`):

    # either: ./adopt.sh <project>

**These links are local setup, untracked in every repo**: a tracked relative
link dangles inside a lane's workspace and in a public clone, an absolute one
leaks a home path, and the system's text doesn't belong in a repo that ships.
`lane new` gives each workspace its own absolute links.

Every rule below came from a real failure. Where a rule carries its reason or a
quote, keep it with the rule: a rule whose reason is stated gets followed.

**A project's own rules.** A project may keep its own rules in
`AGENTS.project.md` at its root. It is binding, read right after this file, and
wins where the two disagree. This file stays project-neutral: a project's names,
paths, commands, gates and decision ids belong in its own file.

**`AGENTS.project.md` is untracked, in every repo**, like `AGENTS.md`: a line
in the root `.gitignore` ignores it (a single file can't ignore itself the way a
directory does, §3). Some repos are public while the tracker is private, and
this file names private things: the tracker and its URLs, standing rules. It
lives only in the default workspace, and **`lane new` links it into each lane's
workspace** by absolute path, so a lane reads the one copy. It has no
history, so nothing irreplaceable lives only there; but it is where the human's
standing rules live, and **a rule he wrote there is his to keep**: no agent
rewrites the file wholesale. Edit it by hand, then re-read what you touched.

---

## 1. Roles

Roles are defined by **what they may write** and **whether they may move trunk**.
That is the whole model. Full definitions are in `agents/`.

| Role | Works in | Writes | Moves trunk? |
|---|---|---|---|
| `coder` | own workspace | production code, its tests, its changelog fragment | no |
| `researcher` | own workspace | `docs/research/` only; no production code | no |
| `tech-lead` | the default workspace | `docs/design/` only; its open decisions go to the decisions file | its own docs commits only |
| `designer` | own workspace | UI, plus rendered before/after evidence | no |
| `foreman` | own workspace, dispatches lanes | briefs and track state; little code | no |
| `scribe` | the default workspace | `BOARD.md`, and rows in the other ops docs (untracked); in Linear mode, the issues | no |
| `integrator` | the default workspace | conflict resolutions only | **yes — sole authority**, bar docs-only commits (§4) |
| `co-developer` | the conversation | the board, the briefs | via `integrator`; docs-only commits itself |

**Why per-role and not per-task.** An agent roster is read once at session start,
so a name invented for one task is always a session late. The eight roles are
permanent and always available.

**The human developer is not one of the eight.** They set direction and
priorities, review, and **edit the board and the ideas inbox freely at any
time**, so an agent re-reads those documents before acting on them rather than
trusting an earlier copy. They launch the application themselves (*Evidence*,
§4).

Two rules hold the model together.

**A lane rebases itself onto trunk and stops.** Its last act is to rebase, re-run
its gates *after* the rebase, and report. It does not land itself. One writer to
the bookmark, or N-way races on trunk leave conflicted commits inside the
repo's own history.

**Trunk holds still while lanes are rebasing onto it.** Moving it underneath a
running lane corrupts nothing, but it silently invalidates that lane's gate run:
green on a base nobody will integrate is not evidence, and the lane rebases
again and re-resolves the same conflicts. Batch integrator commits; land them
after lanes report.

**Anything over ~15 minutes of engineering leaves the conversation.** Long serial
work done inline by the coordinator is dead time for the human
([simply-chris](https://simplychris.ai): *"you're doing too much stuff in main
agent, I am blocked by you linearizing all this work"*). Spawn first, then do the
small residue.

**Architecture is the human's, and the test is the cost of reversing it**
([simply-chris](https://simplychris.ai): *"depends on cost of reversal and risk
of reversal. if it's a small contained thing, it's easy to change later."*).
Every call is one of three:

- **Expensive or risky to reverse → park it, never take it.** Anything that
  spreads:
  - a public API others build on; a wire, file, config or take format that
    reaches saved files or the network; an address scheme or protocol;
  - a crate, module or repo boundary, what a component owns, a new dependency;
  - a cross-component semantic: threading and locking, undo scope, sync vs
    async, what a mode or setting means;
  - a user-visible default, or removing or renaming something a user sees;
  - what a design doc decides (*`docs/design/`*, §2), and picking between two
    designs a lane, a review or a conflict puts in front of you.

  A lane that meets one **stops and asks** its coordinator, unless its brief
  settles it. The coordinator **puts it in the decisions file** (*The human
  channel*, §2) **and waits**. The work it blocks waits; nothing else does. When
  unsure what a reversal would cost, park it.
- **Small and contained → decide it, and list it** in the decisions file as
  *taken without you*, with the alternative, so the human can reverse it.
- **Routine → just do it.** Landing locally, a number inside the agreed scope,
  an internal name, cleanup: no question and no row; the lane's report says what
  it chose. Every needless question costs the human a turn and buries the ones
  that matter ([simply-chris](https://simplychris.ai): *"Please stop asking me
  questions and focus on finishing roadmap"*).

Bug fixes inside an existing design are not architecture.

---

## 2. The doc web

A project run this way keeps a small set of documents. Most of these rules exist
because something ended up in the wrong one, so each says what does **not**
belong as well as what does.

**These documents carry no policy of their own.** What belongs in each is stated
once, here; a document that restates it drifts and pollutes the content it
exists to hold ([simply-chris](https://simplychris.ai): *"the operational
sections at the top of what belongs in which doc … belong in AGENTS.md and
pollute those docs"*). Each opens with one pointer line and, where its rows carry
status marks, the legend: a key belongs beside its table, a policy does not.

**Working state or history.** The documents that decay (the board, the human
channel, the record, drafts) are **working state, not history**. They live in
one untracked directory in the default workspace, **`docs/ops/`**, which ignores
itself (§3): no commits, no rebase conflicts, one copy, always current. Two
decaying documents are tracked at the repo root, because a reader of a clone
needs them: **`CHANGELOG.md`**, which ships with the code it describes, and
**`ROADMAP.md`**, what comes next ([simply-chris](https://simplychris.ai): *"put
roadmap.md at root dir, it should be tracked"*).

| In `docs/ops/` | What goes in it | Who writes it | Pruned when |
|---|---|---|---|
| **The human's view** | | | |
| `BOARD.md` | running, next, what waits on the human: line items | coordinator (or `scribe`); the human, freely | a row leaves the day its work lands; its roadmap row moves to `MILESTONES.md` |
| `MILESTONES.md` | what shipped, milestone by milestone: each keeps its roadmap description and rows (✅, 🔶), then a generated index of the changelog's entries | coordinator; the index by script | never: it is the record of the work |
| `DECIDE.md` | decisions for the human, one row each, with the context to answer | coordinator | answered → moved to `DECISIONS.md` |
| `ASKS.md` | commands only the human can run, with the context to judge them | coordinator | once they have run it |
| **The record** | | | |
| `ISSUES.md` | open defects and rough edges, not scheduled | coordinator, from lane reports | fixed or won't fix → moved to `FIXED.md` |
| `FIXED.md` | issues that left `ISSUES.md`, newest first, each with a one-line verdict | coordinator | never |
| `DECISIONS.md` | settled decisions with their rationale | coordinator | never: a later row supersedes |
| `IDEAS.md` | the ideas inbox | coordinator; the human, freely | never deleted: an idea moves down |
| **Work in progress** | | | |
| `drafts/` | proposals before they become a design doc, review aids, triage | coordinator; a lane's draft arrives in its report | landed as a design or research doc, or answered → `.trash/` |
| `reports/` | each lane's full final report, `<lane>.md` | the lane, its own file only | once the coordinator has recorded it → `.trash/` |

**Rows in the record** start with a short id, then **one** emoji status column,
then the description; any other column (date, source, size) comes after. Ids are
zero-padded so the first two columns line up, stable, never reused, and assigned
by the coordinator. The prefixes live here and only here (in Linear mode only
the files that stay use them; an issue's id is Linear's, *Linear mode* below):

| Doc | Id | Status legend | Row |
|---|---|---|---|
| `MILESTONES.md` | the roadmap row's word label, e.g. `DEST-MIX` | ✅ shipped · 🔶 partly shipped | `\| DEST-MIX \| ✅ \| what you got \|` under its version's heading |
| `ISSUES.md`, `FIXED.md` | `I-007` | 🐛 defect · 🔧 rough edge · 🔬 triaged · 🔄 being fixed · ✅ fixed · 🗑️ won't fix | `\| I-007 \| 🐛 \| what is wrong \| found \| verdict \|` |
| `DECISIONS.md` | `D-042` | ✅ in force · ♻️ superseded · ❓ reopened | `\| D-042 \| ✅ \| decision \| rationale \| when · change id \|` |
| `IDEAS.md` | `N-012` | 💡 open · 🔶 partly answered · 🎯 next up · 📋 queued · 🔄 in flight · 🔬 researched · ✅ shipped · 🗑️ declined | `\| N-012 \| 💡 \| idea \| notes \| added \|` |
| `ROADMAP.md` (tracked) | a word label, e.g. `DEST-MIX` | 🔄 in flight · ⏸️ paused · 📋 queued · 🔶 partly shipped · 🎯 next up · ⬜ open | `\| DEST-MIX \| 📋 \| what you get \| size \| needs \|` |

**Lanes read `docs/ops/` by the default workspace's absolute path** (their own
workspace has none, so their brief names it); `AGENTS.project.md` reaches them
through the link `lane new` makes (§3). What a lane
may write there is under *How a lane writes into shared documents*, below.

### Linear mode — the plan in Linear, not in files

A repo may keep its plan in Linear instead of the files above. It is **opt-in,
per repo**: files stay the default, and a repo is in Linear mode only when its
`AGENTS.project.md` has a `## Tracker` section saying `linear`, with its
initiative, team and Backlog project. Setup, everyday operations, backfill and
cutover are the `linear` skill.

**The repo is an initiative; its team is named in its `## Tracker`.** Repos
share a team by default, so there is one board and one id series; a repo gets a
team of its own only when the human makes one (the Tracker says which). Ideas that fit no repo live in a shared
`Ideas` initiative and project until one earns a repo. Every issue, project
and initiative is assigned to the `## Tracker`'s owner, the human, whenever the
coordinator creates or records it.

| File mode | Linear mode |
|---|---|
| `BOARD.md` running · next | a query: the initiative's issues In Progress (running; the lane noted in a comment) and Todo (next) |
| `BOARD.md` waits on the human | the open-decisions view (issues labelled Decision, not Done) and `ASKS.md` |
| `DECIDE.md` row | an issue labelled Decision, assigned to whoever decides (today always the owner), in the project it concerns, blocking the issues that wait on it |
| `DECIDE.md` *Taken without you* | a Decision issue created Done, saying so; reopen it to reverse |
| `DECISIONS.md` | the Done Decision issues, the answer and its rationale in the last comment; a saved view (label Decision, Done, newest first) is the log |
| `ROADMAP.md` (tracked) | a project per minor version, `<repo> <major.minor> · <title>` (never one per patch), its description what the version means; each roadmap row an issue in it. The file leaves the repo; the README links the initiative |
| `MILESTONES.md` | the completed projects, with their issues; each patch release a project milestone in its minor's project, `<x.y.z> · <title>`, carried by the issues that shipped in it |
| `ISSUES.md` | issues labelled Bug (defect) or Improvement (rough edge), in `<repo> · Backlog` until scheduled |
| `FIXED.md` | the same issue, Done (fixed) or Canceled (won't fix), with a one-line verdict comment |
| `IDEAS.md` Inbox → In-flight → Done | an issue labelled Idea in `<repo> · Backlog` → moved into a milestone project → Done or Canceled |
| one emoji status | the issue's state (Backlog · Todo · In Progress · Done · Canceled · Duplicate) and label (Bug · Improvement · Feature · Idea · Decision); a finer mark (triaged, partly shipped, paused) is a comment |
| priority P1 · P2 · P3 | High · Medium · Low |
| `I-007`, `N-012`, `D-042`, a roadmap row | the issue's Linear id (`AUDIO-123`), assigned by Linear |

**What stays a file in Linear mode**: `ASKS.md`, `drafts/`, `reports/`, so in
Linear mode `docs/ops/` holds only those. Commands for the human, drafts and
lanes' reports are not tasks. `CHANGELOG.md` and `changelog.d/` are unchanged.

**Decisions are issues.** An open decision is an issue labelled Decision, and
its **blocking relations** to the issues that wait on it make *nothing is built
on an open question* (*`docs/design/`*) enforced, not remembered. Its
description is what a `DECIDE.md` row holds (*A `DECIDE.md` row answers
itself*): what is being decided, the options, the recommendation first, what
it blocks. Answered, it goes Done with the answer and its rationale in the last
comment; the *what* is folded into the design doc, this file or the skill text
in the next commit, as in file mode. Wherever this file says *the decisions
file* or `DECIDE.md`, read a Decision issue; wherever it says `DECISIONS.md`,
read a Done one. Decisions about the working system itself live in the `dev`
initiative, project `dev · Working system`.

**Reading this file in Linear mode.** A rule about the board, a row, the
roadmap, a milestone, an issue or an idea applies to its issue or project in the
table. The file mechanics do not: untracked, edited by hand, legends, padded
ids, rows moving between files. Nothing is pruned: an issue is never deleted, it
goes Done, Canceled or Duplicate. Live state the board would carry as a row
(*Standing* instructions, the local-model switch) goes under *Standing* in the
initiative's description; trunk and ready chains come from `jj log`, as always.

**The boundaries hold.**

- **Lanes never write Linear**, as they never write `docs/ops/`: they report to
  their file, and the coordinator (or `scribe`) records into Linear. A lane's
  questions go in its report; the coordinator files the Decision issue. An agent
  that must read Linear is spawned with `mcp_servers: ["linear"]` and reaches
  the tools through codemode; one that needn't is spawned without it, its
  brief carrying the issue text it needs.
- **Linear ids are ops ids.** The workspace is private, so `AUDIO-123` points at
  nothing in a clone: never in a commit message, code or a tracked doc (*What a
  commit message says*, §4).
- **A roadmap issue keeps its word label** at the head of its title
  (`DEST-MIX · …`), so the changelog can still name it.

### `BOARD.md` — the live board

A **shared, live document every agent reads before acting**, and the human's
primary view of what is happening and what needs them. In Linear mode it is a
query, not a file (*Linear mode*): the rules below hold for the issues it shows.

- **Line-items only.** Prose is what lanes collide on; line items don't.
- **Lanes never write the board**, and no role owns a section of it: the
  `integrator` writes none of it, so the `scribe` never waits for one.
- **Short, and only the live work.** Sections: running · next · waits on the
  human. Milestones and deferred work belong in the roadmap
  ([simply-chris](https://simplychris.ai): *"board.md milestones shouldn't be
  there, that belongs in roadmap … same with deferred"*).
- **One live file.** Who runs what, which chains are ready and where trunk is
  are rows here too; a second live file repeats the board and drifts from it
  ([simply-chris](https://simplychris.ai): *"we should just have BOARD.md and not
  2 files that repeat the same info"*).
- **Not here**: rationale, discussion, anything addressed to the human. Those go
  to the human channel. A board entry is a row, a state and a label.
- **Kept current.** The coordinator updates it on every spawn, landing and plan
  change, in the same turn (Linear mode: the issue's state and its lane comment).
- **What landed is told in the changelog, never here.** A landed row leaves the
  board the same day, and its roadmap row moves to `MILESTONES.md` (Linear mode:
  the issue goes Done); a superseded one is deleted (Canceled or Duplicate) and
  its successor says what it replaced.
- **Whatever waits on the human is one hop from here.** The board names the
  decisions file and the asks file (*The human channel*; Linear mode: the
  open-decisions view and `ASKS.md`); not a commit message, not a banner on a
  file.

**Edit it by hand, not by script**: it is the file everyone navigates by. Read
it, write the intended result, re-read the section you touched. What goes wrong when a shared document is
merged is under *Landing*, rule 3.

**Untracked is the point.** A gitignored file does not dirty the working copy,
so the board can be rewritten *during* an integration, exactly when most is
changing and the human most wants to look. The trade: a lane gets its context
from its brief and reads the board by absolute path. What a lane must *build on*
(code, design, research, the changelog) is tracked.

**Nothing the human wrote lives in a file that gets rewritten.** An untracked
file has no history. His review text goes in `drafts/`; a standing rule goes in
`AGENTS.project.md`, which is untracked but never rewritten (*A project's own
rules*), or a `DECISIONS.md` row.

**A row's id is its label**: the lane's name (`flaky-2`, `ui-shell`), never a
row number, which shifts as rows come and go. **A label is something the human
types**, so never strike one through: a `~~LABEL~~` cannot be typed to fire a
lane, and a struck row reads as *present but crossed out* when what is meant is
*gone*. Status lives in the status column and the row's section, never in the
label.

### `CHANGELOG.md` — tracked, at the repo root

What got added, per landing, dated and tied to versions
([simply-chris](https://simplychris.ai): *"what got added, not all the analysis
and story"*): what a capability now is, what changed in behaviour (anything
that alters saved files or an API above all), what was fixed, in a line. A few
lines an entry.

**In a merge, keep both entries; the later-landing lane's goes above.** Order by
when each landed, not by which side of the conflict it came from: easy to get
backwards when both are dated the same day.

The displaced material has homes: measurements, root causes and alternatives
weighed → `docs/research/`; what a lane left undone, and a decision *made*
rather than applied → the lane's report, from which the coordinator writes a
board, issues or decisions row. **An entry that reads as a narrative is in the
wrong document.**

**Not here**: work that has not landed; roadmap intent.

### Dating an entry — clock *and* change id

Many lanes land on one date, and a date says nothing about which came first.
Every `CHANGELOG.md` entry and every `DECISIONS.md` row (Linear mode: a Decision
issue's closing comment) carries **both**:

    #### A preset that describes itself (`LIBFIN`) · YYYY-MM-DD HH:MM · oplmqxmn
    | YYYY-MM-DD HH:MM · uvzmuvkl | **The analysis toolkit is a separate crate family…** |

- **The clock** is for a human skimming. The lane writes it in its fragment at
  commit time, as the only party that knows. It is *not* the ordering authority.
- **The change id** is the ordering authority and the verification. Ancestry
  answers "which landed first" exactly, though authoring, rebasing and landing
  are often hours apart; `jj show <id>` produces the change, so the record can be
  checked against the tree.

**jj change ids survive rebase**, so a lane's id is still valid after five
rebases onto a moving trunk. A commit hash would not be; do not use one.

### `ISSUES.md`

Defects and rough edges anyone notices in passing: file it, triage it, **don't
interrupt a lane for it**. A **parking lot, not a queue**: nothing here is
scheduled until promoted onto the board. Recorded by the coordinator from lane
reports and **never silently closed**. A resolved issue moves to `FIXED.md` with
a one-line verdict and a pointer to the changelog, so `ISSUES.md` reads as what
is still open ([simply-chris](https://simplychris.ai): *"maybe we need a
FIXED.md for fixed issues"*).

**Not here**: features somebody would ask for by name (→ ideas), or work already
scheduled (→ board).

### `IDEAS.md`

An inbox in three sections: **Inbox → In-flight → Done**. Ideas arrive raw and
half-formed; append a row the moment one surfaces, promote it when it earns a
lane. **An idea only ever moves down**: Inbox (no commitment) → In-flight (it has
a board row) → Done (answered; the account is in the changelog). A row keeps its
id as it moves.

### `ROADMAP.md` — tracked, at the repo root

In Linear mode the roadmap is the initiative's milestone projects, and this file
leaves the repo (*Linear mode*); what follows holds for the projects.

Horizons and versions, and what a version *means* in the register of the ones
before it, built from the ideas story lines plus the dependencies that gate
them. Horizon numbers continue the version series. **Only what is not done**;
milestones and work deferred by decision live here, not on the board. Tracked,
so it **cites no ops ids**: its rows carry word labels. The coordinator edits it
in the default workspace as a docs commit.

**Not here**: finished work; that is the changelog.

### `DECISIONS.md`

Dated decisions with their rationale, so a settled question stays settled. One
row, one decision, one date. In Linear mode there is no such file: a settled
decision is a Done Decision issue (*Linear mode*).

### `docs/design/`

Proposals and the locked design. **Design documents always land on trunk**,
proposals included: the human reviews on trunk, never in a lane's workspace
([simply-chris](https://simplychris.ai): *"I can't review design docs in
workspaces, they need to be in main"*). **A design doc lands like any other
doc**: no review banner, no review row; the human reads in passes of his own
choosing ([simply-chris](https://simplychris.ai): *"stop asking me to do doc
reviews, I'll do passes as I see fit, adding these as line items is just
noise"*). **What stays the human's is the decision**: it goes in the decisions
file the same day, the doc marks that question open where it is asked, and
nothing is built on an open question. When the human answers, the next commit
folds the answer in.

**Changing what a design decides goes through the decisions file; recording that
it was built does not.** Marking a stage as built, correcting a sketch to match
the code, or adding a finding the design did not predict is **reporting, not
proposing**. A lane that wants to *change* what was decided says so in its
report.

If a design's section numbers are cited from source code, **they are never
renumbered.**

### `docs/research/`

Investigations and measurements. A number with its method beside it settles an
argument; a paragraph of plausibility does not. Also **the argument behind
anything designed but not built**.

**There is no register of unlanded designs**: everything it would hold fits
elsewhere ([simply-chris](https://simplychris.ai): *"I kind of feel like
DESIGN.md as a doc should not exist unless there are things that don't fit into
the docs I just mentioned"*). An unlanded design is **a research note plus a
queue row**: the note holds the argument and measurements, the row what a lane
would do and what it costs. The decision it waits on lives where it can be
answered: a board row's priority field, an ideas note, or a decisions row once
answered. When it lands it moves into the design document.

### `docs/guides/` · `docs/reference/`

How to do a thing: build, run, release, use a tool. Generated references say so
and are **regenerated, not edited**.

### The human channel — `DECIDE.md` and `ASKS.md`

Two files in `docs/ops/` for what passes between the human and the agents,
**untracked so that conversation never enters history**. They give the narrative
somewhere to go, which is what lets the board be line items. In Linear mode
`DECIDE.md` is the open Decision issues and only `ASKS.md` is a file
(*Linear mode*); a Decision issue's description keeps a row's shape, below.

Everything that waits on the human lives here, **never only in chat or a commit
message**: chat scrolls away while lanes report.

- **`DECIDE.md`**: decisions for the human, one row each, with a short answer
  code. An answered row moves to `DECISIONS.md`.
- **`ASKS.md`**: **commands only the human can run**, with the context to judge
  each, **run or dry-run first** by the agent from the directory it names, and
  pointed at the default workspace, never a running lane's working copy.
  Deletions an agent cannot do land here (*Environment*, §4). **A block that
  names paths names them explicitly**: an *"everything except…"* filter is
  evaluated when the human runs it, in a world the agent could not see, which is
  how a cleanup deletes a lane started after it was written.

**A `DECIDE.md` row answers itself.** The human can reply from the row alone
([simply-chris](https://simplychris.ai): *"expand on U and ASK-40, missing
context"*; *"rec?"*, four times in two hours):

- **what is being decided**, in one plain sentence, every term defined;
- **the options**, each with what it changes for the human;
- **your recommendation**, first among the options;
- **what it blocks**, and where it lives.

`| D-66 | ❓ | decision | options (rec. first) | blocks · context |`. The file
opens with *Open now*, newest first; calls taken without the human come after
(*Architecture is the human's*, §1). Moot rows are pruned before he reads them
(Linear mode: a moot Decision issue is Canceled, with a one-line comment).

**No doc web yet is no excuse.** A repo without `docs/ops/` gets one the first
time something needs recording, in that turn (`adopt.sh`, or at least
`BOARD.md`, `DECIDE.md` and `ASKS.md`; Linear mode, `ASKS.md`). A question for
the human goes in the file (Linear mode: its Decision issue) *before* chat
mentions it ([simply-chris](https://simplychris.ai): *"the
questions you ask me flow away as you react to agents"*).

**Anything the human will paste goes in a file; anything an agent can run, it
runs** ([simply-chris](https://simplychris.ai): *"I can't copy paste from chat, I
need a doc"*). A post, a blurb or a config block goes in `drafts/`, and the
reply gives the path.

**The coordinator writes both files** (Linear mode: files the Decision issues). A
lane puts its questions in its report: it cannot reserve a row id, and lanes
numbering rows from their own counts collide.

### Where they live

As few top-level documents as possible ([simply-chris](https://simplychris.ai):
*"where should the remaining top-level docs go? Ideally only one or 2 key ones
remain"*):

- **the repo root** holds `AGENTS.md` and `AGENTS.project.md` if any (both
  untracked), and the tracked `CHANGELOG.md` and `ROADMAP.md` (file mode
  only), with the untracked `changelog.d/` fragments beside them;
- **`docs/ops/`** holds what decays, wrong the moment work lands, so it lives
  and is maintained together, by the coordinator, in the default workspace;
- everything else lives by kind: design, research, guides, reference. A folder
  appears when there is something to put in it.

Documentation lives in the docs tree, **never inside the source tree**.

### A repo you don't own

A shared work repo, reviewed by people who never opted into any of this, gets a
second adoption mode, not a variant of the first.

**Two repos, sibling, not nested.**

    ~/work/<project>/
      repo/           the shared repo — git, PR'd, reviewed, untouched by this system
      ops/            a separate jj repo — AGENTS.md, docs/ops/, agents/, all of it

`repo/` never contains a line of this system: not `AGENTS.md`, not `BOARD.md`,
not a gitignore entry, nothing a teammate's `git status`, PR diff or repo search
would surface. `ops/` is the doc web this file describes, laid out per §3,
pointed at a different remote (or none).

**Why sibling and not nested.** Nesting only works for *another working copy of
the same repo* (a git worktree or jj workspace, which carries no history of its
own): `repo/.worktrees/<lane>/` (or `repo/.claude/.worktrees/`) belongs inside,
per §3. An independent repo with its own object store is different: git can
gitlink it into a commit as an embedded repo, and only a per-clone
`.git/info/exclude` entry, which a re-clone drops, would keep it off the shared
remote. A sibling is safe structurally, not by discipline: nothing operating on
`repo/`'s tree can reach it.

**What still lands in `repo/`**: code, its tests, and a `CHANGELOG.md` if the
team already keeps one (check, don't assume). Nothing else from the doc web.

**Landing changes shape.** A lane still rebases and reports, but landing means a
PR against `repo/` that passes the gates clean, not moving anyone's trunk; the
changelog entry and the lane's report record the PR link or merge commit instead
of a bookmark move. Review is the team's gate, not the integrator's.

**Lanes don't write `ops/`**, as they don't write `docs/ops/`: they report, the
coordinator records. A lane's fragment goes in `ops/changelog.d/`; the fold
writes into `repo/`'s changelog, if the team keeps one.

### How a lane writes into shared documents

- **It writes into the default workspace in exactly two places**, both
  untracked, both its own file, both by absolute path: its changelog fragment,
  `changelog.d/<LANE>.md`, and its report, `docs/ops/reports/<lane>.md` (*A
  lane's report is a file*, §4). Nothing else there, and never `CHANGELOG.md`.
- **The fragment is staging, not history** ([simply-chris](https://simplychris.ai):
  *"changelog.d should be untracked, as it's temporary staging"*): the directory
  ignores itself, so a fragment never dirties the working copy an integrator
  lands in.
- **Everything else goes in its report**: issues found and closed, decisions
  taken, follow-up work with a priority. The coordinator records them.
- **On landing the fragment is folded into `CHANGELOG.md` and moved to
  `.trash/`.** A fragment whose lane has not landed stays.
- **The changelog is user-facing**: what a person gets, not what the code did.
  For internal work the honest line is *"nothing changes for you; this is what
  stops a class of bug reaching you."*
- **An issue says what is wrong before anything else.** A repair history is one
  clause at the end.
- **A design change lands with its open points marked** and its questions in the
  lane's report. A lane never presents its own change to a design as decided.
- **Fix it, do not file it.** A small defect found in passing is closed in the
  lane ([simply-chris](https://simplychris.ai): *"I hate that issues keep piling
  up instead of getting resolved."*).

**Why fragments.** Two lanes editing one changelog is a merge conflict in prose,
settled by picking a side rather than understanding either. Fragments cannot
collide; they are folded **in landing order**, the only order that reads
correctly. **A fragment that survives its fold gets applied twice**: retire it
when you fold it.

**Ids are the coordinator's.** A lane cannot see another lane's work in flight,
so lanes counting on their own pick the same id. A lane names what it found in
words; the coordinator assigns the id. In Linear mode Linear assigns it, when
the coordinator files the issue.

---

## 3. Default directory structure (a repo you own)

    AGENTS.md                  this file: a symlink to it; untracked, by a root .gitignore line
    AGENTS.project.md          this project's own rules (optional; wins over this file);
                               untracked, by a root .gitignore line; default workspace only
    .claude/agents ->          symlink to <this system's repo>/agents, untracked
                               (Claude Code; pi.dev uses .pi/agents instead)
                               lane new links all three into a workspace, by absolute path
    CHANGELOG.md               tracked, user-facing; folded from the fragments below
    ROADMAP.md                 tracked; what comes next, by version; no ops ids (file mode only)
    changelog.d/<LANE>.md      untracked, default workspace only; a lane's entry until its landing folds it in
    docs/
      ops/                     untracked working state, default workspace only (§2):
                               BOARD.md MILESTONES.md DECIDE.md ASKS.md     the human's view
                               ISSUES.md FIXED.md DECISIONS.md IDEAS.md     the record
                               drafts/                                      work in progress
                               reports/<lane>.md                            lanes' final reports
                               (Linear mode: only ASKS.md drafts/ reports/; the rest is in Linear)
      design/                  the design, proposals included
      research/                investigations and measurements
      guides/                  how-to
      reference/               generated — regenerate, don't edit
    spikes/<name>/             experiments, each its own build workspace, on a lane's chain
    .workspaces/<lane>/        one per lane, gitignored, INSIDE the repo
    .trash/<what>-<date>/      gitignored; discarded files, emptied by the human
    .screenshots/              only in projects that render images: its own .gitignore `*`
      progress/<date>-<LANE>/  what a lane renders; only scenes that CHANGED
      baseline/<date>/         the full set after an integration; keeps everything

**An untracked directory ignores itself**: its own `.gitignore` holds `*`
(`docs/ops/.gitignore`, `changelog.d/.gitignore`, `.workspaces/.gitignore`,
`.trash/.gitignore`…), not a path entry in the root `.gitignore`. The rule
travels with the directory, and the root ignore file stays the project's. The
exceptions are the local links, which can't ignore themselves: each takes one
anchored root line (`/AGENTS.md`, `/AGENTS.project.md`, `/.claude/agents` or
`/.pi/agents`), which `adopt.sh` adds.

Workspaces go **inside** the repo, not `../` siblings, which pollute the
directory the other repos live in. This is about extra working copies of *this*
repo; the `ops/` sibling for a repo you don't own is a separate repo and a
sibling on purpose (*A repo you don't own*).

---

## 4. Operating rules

### Before you land anything: check trunk is where you think it is

**Verify the bookmark against the actual tip, every session.** After a history
operation (an `op restore`, an undo, a rebase someone else ran) a bookmark can be
left many commits behind the real work, and `git log` agrees with it. Nothing
warns you; every rebase you then run is onto the wrong base. What is unintegrated
comes from a query (*Status comes from a query*, below).

**Bookmark a chain's tip before forgetting its workspace.** The workspace is the
only thing keeping that chain visible.

**One workspace, one writer — the default workspace included.** While an
`integrator` is landing, nobody else writes there, whoever is dispatching
included: the sibling of *trunk holds still* (§1). An integrator that finds
unexplained changes cannot tell whose they are, has to park them as a side
commit, and spends its judgement on archaeology. Hand a change to the
integrator, or wait.

### Status comes from a query, not from memory

Every status answer, to the human or in a report, is read off the system when it
is given. Memory and relayed messages say what *was* true. A lane reported
"running" for 13 hours had been dead on an editor prompt all along, and the
human noticed, not an agent (*"how do you know [it] is actually making progress
and not stuck"*).

- **What runs: from the agent list.** Before saying a lane is running, or that
  nothing is, list the agents and check build processes. A lane quiet for long
  is read before it is reported, and reported as quiet since when.
- **Where work stands: from `jj log`.** Ask what is unintegrated
  (`ancestors(<workspace>@) ~ ::<trunk> ~ empty()`) and count; check a fix is on
  trunk before saying it landed. A board can record a lane as landed when it has
  not been. An *empty* working copy means nothing: a finished lane's work sits in
  the ancestors.
- **Sent is not received.** A message is in a lane's plan only once it answers.
  Until then say "sent", never "it's doing X".
- **A burst of stalls is one problem** (auth, quota, network) more often than
  not. Read one stalled lane's error before retrying any: an hour went on
  retries while the cause, a revoked token, sat in the first child's output.

### Trunk and the working copy

**`default@` is always an empty commit one above trunk.** The integrator's
working copy is scratch, never the thing that ships. The loop
([simply-chris](https://simplychris.ai)):

    jj new                      # @ is an empty child of main
    …edit…
    jj commit -m "…"            # describes @ AND opens a fresh empty child
    jj bookmark set main -r @-  # main is the commit just made, @ stays empty

`jj commit` describes and opens the next empty child in one step, so `@` is
never a described commit waiting to be pointed at. Breaking the loop goes wrong
in two ways, both invisible until someone reads the log:

- an edit made while `@` *is* trunk silently joins the last commit, so two
  unrelated changes share a message;
- a `jj describe` on a commit the bookmark points at **overwrites** its message,
  so a landed lane's account is replaced by the next thing typed.

**The integrator does not run into a version.** When the last lane of a milestone
lands, stop and hand back rather than continuing to the tag
([simply-chris](https://simplychris.ai): *"don't go there automatically, let's
take the opportunity for a human review and cleaning up old workspaces"*). Each
lane was reviewed against its own brief and nobody has read the result as one
thing; after a tag a correction changes something released. It is also the only
moment no lane is rebasing, which workspace cleanup and history repair need.

### The lane lifecycle

**Docs-only changes need no workspace.** A markdown-only change, in any repo,
never gets a workspace, a lane or an integrator
([simply-chris](https://simplychris.ai): *"a worktree just for a .md update is a
waste"*). It is edited in the default workspace and committed with the trunk
loop above, committing only its own paths (`jj commit <paths> -m "…"`, never a
bare `jj commit`: other work may be uncommitted there), moving trunk to it only
if trunk is that commit's parent, and not while an integrator holds the
workspace. Design and research docs are written there too, so they land where
the human reads them. A docs-only commit changes nothing a code gate tests, so a
gated lane rebased over it needs no re-gate.

**A lane buys parallelism.** With nothing to run beside it, a workspace, a
rebase, a re-gate and an integrator are pure overhead: when the human waits on
one thing and nothing else runs, do it inline ([simply-chris](https://simplychris.ai):
*"the cost of a workspace is also the rebase and regate"*). Lanes are for two or
more things at once, or long work the human is not waiting on.

1. Idea or direction lands → **docs first** (an ideas row, a board queue entry, a
   decisions entry; in Linear mode, an issue) before engineering starts.
2. Launch: `lane new <lane>` (*Spare the disk*), plus a brief.
3. The lane works: incremental commits on its own chain, with the project's
   version control and **never git in a colocated repo** (a `git commit` after
   `jj new` lands on a detached head). Chains survive a dead agent; a
   replacement resumes from the same fence.
4. **Every finishing lane writes its own record**: its changelog fragment and
   its report file, with the board substance (what it finished, follow-up work
   with a priority, issues and decisions). The coordinator records from the
   report; reconstructing every lane's state by hand does not scale past a
   handful.
5. **The lane's last act is to rebase itself onto trunk**, resolve every
   conflict, **re-run the gates afterwards**, and report what conflicted and how
   it was resolved. Then stop.
6. An `integrator` lands it. **Landing is a pointer move, not a rebuild**
   ([simply-chris](https://simplychris.ai)):
   - **The lane sits on current trunk and gated there** → `jj st` (refuse if
     `default@` is not empty: those edits are the human's), then `jj new <lane
     tip>` from the default workspace. **No re-gate**: it is the tree the lane
     already gated.
   - **Trunk moved since the lane rebased** → send it back to rebase and
     re-gate, or rebase it yourself and re-gate **only the blast radius**.
   - **Fragment folds are batched** into one docs commit, at a natural pause or
     the version stamp, never one per landing: every trunk commit makes every
     running lane rebase again.
   - **One gate per tool call, foreground, with a tight ceiling.** Output to a
     log (its growth tells a slow run from a stuck one), then read `$?`. Set any
     timeout to about twice the gate's usual time, minutes not hours: a hung gate
     costs the whole ceiling, and no steering message reaches the agent until
     the call returns ([simply-chris](https://simplychris.ai): *"using a 2h
     timeout, wtf"*). A run that hits its ceiling is a hang to investigate, not
     to re-run.
   - **Never sleep-poll a gate.** `sleep 600` waits the full ten minutes after
     the gate is done. If a run must be backgrounded, wait with `while kill -0
     <pid>; do sleep 5; done`, which returns the moment it ends.
   - **Nothing a lane runs can wait for input**: run with `</dev/null` and
     `JJ_EDITOR=true GIT_EDITOR=true EDITOR=true`, so a prompt fails at once
     instead of waiting out the ceiling.
   - Then tell the human.
7. Recycle: `lane retire <name>` forgets the workspace and deletes its directory;
   its commits stay (bookmark an unlanded tip first). Never move a retired
   workspace to `.trash/`: a pile of them is busy work for the human and a hazard
   when they clean up by hand.

**Why the rebase belongs to the lane** ([simply-chris](https://simplychris.ai)):

- **The lane knows what its own change meant.** An integrator resolving someone
  else's conflict guesses at intent, and a wrong guess is silent: a plausible
  document nobody wrote, an entry missing its opening line, a body under the
  wrong heading, a changelog account describing another lane's work.
- **A rebase can break a lane that merged cleanly.** Another lane may have
  changed the API this one calls.
- **Resolving at the tip is not resolving** (*Landing*, rule 1).

The integrator's job is then to read the report, move the bookmark, verify.

**Never rebase a RUNNING agent's chain.** The stale-workspace recovery fires
under the agent and can revert its working copy to an older revision, leaving
its change divergent and its work lost. **Integrate only chains whose agent has
reported and stopped.** If a lane must land early, tell it to commit and stop,
wait for the completion notification, then rebase. The integrator's own working
copy going stale is harmless: that is just its session catching up.

### A lane's report is a file

**A message to a lane that is finishing replaces its report.** It wakes the
lane for one more turn, and that turn's short reply ("nothing to do, my report
covers it") becomes the final result its parent sees. Three lanes' reports were
lost this way in one afternoon, during a hotfix.

- **Every lane writes its full report to `docs/ops/reports/<lane>.md`** in the
  default workspace, by absolute path, before its final message, and ends that
  message with the path. A later reply can no longer erase it.
- **A recorded report moves to `.trash/`.**
- **Never message a lane that may be finishing**, an FYI least of all ("trunk
  moved", a peer's name). What it needs goes in its brief, or the integrator's.
- **The next ask is a `followup` after the report arrives**, never a message
  sent while it is on its way.
- **A short final result means: read the file** before asking again.

### Landing

1. **Resolve the oldest commit in a chain first, never the tip.** A clean tip can
   sit on conflicted ancestors, and resolving there leaves them conflicted in the
   repo's own history.
2. **Read the label on every conflict block; never assume which side is which.**
   `jj` writes `+++++++ … (rebase destination)` for trunk's side and `(rebased
   revision)` for the lane's, and it alternates *within a single file*. Assuming
   corrupts the document, and the result looks right.
3. **Never resolve a shared document with a union script.** A blind union (keep
   `+`, drop `-`, keep context) **silently mangles entries**: a row both sides
   edited loses its unchanged half, an old row reappears elsewhere, headings
   duplicate, a body is orphaned under another lane's heading, an entry loses
   its opening line, corrections vanish. The damage survives: a document can end up with **two tables for one
   section, with different column headers**, unnoticed for sessions. After any
   machine resolution, **grep for duplicated headings.**
4. **A clean textual merge can still leave a semantic conflict**: a changed
   signature, a moved function, an enum that gained an arm (a trait impl added
   on trunk keeps the old method signature and the crate does not compile). The
   gates are the only proof; neither lane could have seen it.
5. **Deletion-versus-modification is the reorg conflict.** When trunk splits a
   file into a directory and a lane edited the old file, a two-line change shows
   as the whole file recreated with markers. **Extract the lane's real `+`/`-`
   delta first**, take trunk's deletion, relocate the delta into the module that
   now owns it, and say where. Where `rm` is denied, accept the deletion with a
   restore-from-trunk of that path.
6. **Import lists are the most common code conflict** after a reorg: *trunk's
   form, minus what the lane removed, plus what it added*. Verify a removed
   symbol is genuinely unused rather than trusting the lane.
7. **When trunk changes a module's visibility, decide by the rule, not by
   copying a side.** Is the module reached by path from another crate? Are its
   contents re-exported at the root? The visibility follows; picking the tidier
   side reintroduces what a surface-cleanup lane just removed.
8. **`jj squash` moves the whole working copy, not the file you had in mind.**
   Pass explicit paths, or an unrelated asset lands inside a documentation commit
   and you notice only when the next commit reports `(empty)`.
9. **Land with `jj new <lane tip>`**, which keeps `default@` an empty commit one
   above trunk (*Trunk and the working copy*).
10. **Never abandon a commit trunk points at without re-setting the bookmark.**
    The next command fails with "revision doesn't exist", which explains
    nothing.

`docs/ops/` and `changelog.d/` are untracked: they never conflict and are never
part of a landing.

### Repairing history, if it comes to that

Conflicts stored in an ancestor's tree are history quality, not a broken tree:
the tip can be clean and build. Fix them only under three conditions; the first
two are why it usually waits.

- **No lane may be running.** Rewriting trunk under them invalidates their work.
- **Resolve oldest-first, in a scratch workspace.** A wrong attempt multiplies
  the conflicted commits; the operation restore that undoes it is safe only
  because no lane is running (*Environment*: never in a shared repo otherwise).
- **The acceptance test is the tree, not the log.** Hash documents and source
  before and after: **byte-identical**. A repair that changes content is a
  different change wearing a repair's clothes.

### Evidence

- **Run the project's gates unfiltered and report them verbatim**, counts
  included. A filtered gate is not a gate. Never report green without running
  them.
- **Run the full gates once, after the final rebase** (*Spare the disk*).
- **A blocked human outranks the gates.** When the human is waiting on a fix
  (live breakage, a show), land the smallest fix after a compile check and the
  test that covers it, then run the full gates behind it, and say plainly it is
  ungated until they pass. Full gates protect trunk from a lane's unknowns; they
  are not a reason to keep a known fix from the person who needs it
  ([simply-chris](https://simplychris.ai): *"PLEASE JUST LAND IT it's doing a
  full test with 3600 timeout"*).
- **Many lanes at once gate once, together.** When several lanes run on one
  trunk, each gating on its own means the first to land moves trunk and every
  other one re-gates, and under load the gates themselves crawl
  ([simply-chris](https://simplychris.ai): *"one will win the race and rebase
  and then the other will have to regate"*). Lanes in such a batch run only
  their own tests, commit and report; the coordinator stacks them on trunk
  oldest-ready first and runs the full gates once on the result.
- **Fixes are done as told; new work is asked about first.** A clear instruction
  about a fix is carried out the way the human said, the same turn, with any
  concern listed beside it as an open question. A feature, milestone or design
  starts with the questions the human hasn't settled (scope, *done*, defaults,
  what to leave out), asked in one round with a recommendation each, before any
  lane is briefed ([simply-chris](https://simplychris.ai): *"'clear order' only
  applies to fixes, stuff like this should be more about asking me the right
  questions"*).
- **Verify headlessly.** Never auto-launch the application to check something:
  it steals the human's screen focus. They launch it themselves.

### What a commit message says

**A commit message says what the commit did, never what it is waiting for.** A
commit is immutable and review state changes, so "PROPOSAL" or "NEEDS REVIEW" is
wrong within hours and stays wrong forever ([simply-chris](https://simplychris.ai):
*"calling out for 'needs review' in commit messages is silly, that's what
BOARD.md is for"*). No co-author lines.

**No internal ops references.** Issue, decision or idea ids, lane names, board
or landed-index rows, Linear ids included (`I-106`, `N8`, `DEC-42`, `AUDIO-123`,
`LANE-x`, `ops: … landed`) mean
nothing to a reader of the history, least of all in a public repo
([simply-chris](https://simplychris.ai), on `docs(ops): I-106 closed (N8–N11,
N13); N12 filed as I-107; landed-index row`: *"random internal ops docs
references as commit messages, they are meaningless"*). The subject says in plain
words what changed and why; the body may explain more, still in plain words. A
commit that only updates ops docs says what it records ("record the VST3
inactive-parameter fix as done"), not which rows moved. This holds in every repo.

**Code and tracked docs never cite ops ids either**
([simply-chris](https://simplychris.ai): *"code and docs should NEVER reference
issues and decisions and such by id"*). No issue, decision, idea, roadmap, ask or
lane id (`I-007`, `X-151`, `N-12`, `AUDIO-123`, a board label) in source, comments,
tests, design and research docs, guides, the changelog or a README: they live in
untracked `docs/ops/` or a private Linear workspace, so in a clone they point at
nothing, and the rows are
pruned and superseded while the code keeps citing them. Drop the citation, and
don't swap in the story behind it. **Code and docs are the *now* view**: they
state **why, what and how, not how we got there**. The why is today's rationale
("a scene never creates a channel, so a scene file can't change the machine"),
never what was decided, reversed or used to be; history lives in the changelog
and `docs/ops/`. What may be cited: a design doc's section number (§2.3, never
renumbered), a file or function by name, a jj change id in the changelog.

### Referring to the human's points

**Never refer to the human's points by a number alone.** They may not have
numbered them, may have added one later, or may not remember which was which
([simply-chris](https://simplychris.ai): *"when you reference my ideas by number,
it's hard to know how you have numbered them"*). Say what the point *is* with the
number ("3 (aligning OSC against the local transport)"), in chat and docs; a
document that keeps the numbering lists the points with their numbers at the
top.

**In chat, and in reports and untracked ops docs, every Linear issue, project
and initiative is a link the human can click**
([simply-chris](https://simplychris.ai): *"always hyperlink issues in chat so I
can click on them"*): `[AUDIO-123](https://linear.app/<workspace>/issue/AUDIO-123)`,
with what it is beside it, never a bare id. Projects and initiatives link by the
URL Linear returns. Tracked files still cite no ids (*What a commit message
says*).

### Survival

- **Commit early and often.** A WIP commit in your own workspace costs nothing;
  an agent that dies mid-task, on a spend limit say, loses everything
  uncommitted. A crash should cost minutes.
- **Commit after each green step**, so a dropped connection loses nothing.

### Environment

- **Agents must run version-control commands unsandboxed.** A sandbox that
  intercepts filesystem syscalls turns a working-copy scan into minutes (`jj log`:
  **over two minutes** sandboxed, **16 ms** without). It hangs rather than fails,
  so it reads as a repo problem; a slow `jj` is not evidence of a large repo, a
  lock or a corrupt operation log. Check this first.
- **`jj squash` and `jj describe` open `$EDITOR` and hang an agent forever.**
  Always pass `--use-destination-message` (the real fix), and `export
  JJ_EDITOR=true` (the belt).
- **`jj abandon` takes explicit change ids from your own chain, never a revset
  pattern.** jj has no notion of which workspace owns a commit, and every
  workspace's working copy is an empty, undescribed child of trunk, so a
  clean-up like `jj abandon -r 'main+ & empty() & description(exact:"")'` also
  abandons every *other* workspace's working copy. To find your own commits,
  query `ancestors(<your-workspace>@) ~ ::main`, read the result, then abandon
  by id. It happened twice in one night (2026-11-09): both times the commits
  were empty and an undo put them back, but a broader pattern takes real work.
- **`rm` may be denied, and `~/.Trash` is not the bin.** Move discarded files to
  the project's `.trash/<what>-<date>/` (gitignored). What only the human can
  delete goes in the asks file, except emptying `.trash/`, which the human does
  on their own: never ask for it.
- **Never search `.trash/`** (`grep -r`, `rg`, `find`). Its retired workspaces and
  build caches run to tens of GB; a `grep -r` there stalls a lane for half an
  hour or more. Search the source and docs directories by name.
- **No `timeout` on macOS.** It does not exist there; don't wrap a build in it.
- **Spikes live in a workspace, never in `/tmp`**: under `spikes/<name>/`, its
  own build workspace, committed on the lane's chain where others can see it.
  The coordinator decides whether it lands on trunk or stays on a side bookmark.
- **Never `jj op restore`, `jj op revert` or `jj undo` in a shared repo.** They
  act on the whole operation log and undo other lanes' commits, merges included.
  Fix your own mistake with `jj restore`, `jj abandon` or `jj rebase` on your own
  changes; if that cannot fix it, report it.
- **Agents never push.** Pushing is the human's call; a project's own rules may
  name an exception. While the human is still talking a design through, nothing
  is committed: the draft stays in the working copy or `drafts/`, and the
  conclusion is committed once ([simply-chris](https://simplychris.ai): *"stop
  pushing things to github, I will decide when to push … when we're having a
  discussion, wait for our conversation to conclude before you commit to avoid
  commit spam and spam in the jj log"*).
- **The human's machine is not yours.** This is a security boundary, not a
  courtesy ([simply-chris](https://simplychris.ai): *"let me worry about the
  config"*).
  - Never kill a process you did not start: kill by the pid you recorded, never
    `pkill` by pattern (one agent's `pkill` took out the human's running hub).
  - Edit nothing outside the repo you were asked to work in (the human's config
    and data, other repos' files) unless he asked for that exact edit: propose
    it in a file, with the exact lines. Your own scratch files are the
    exception.

### Spare the disk: builds are writes ([simply-chris](https://simplychris.ai))

Every build writes gigabytes to the human's SSD, and build caches are what fill
it.

- **Full gates once, after the final rebase.** While working, run only the tests
  you touched. A load or soak harness runs only when the brief asks for it.
- **A load harness runs alone.** It saturates every core by design; beside other
  lanes' gates it makes them several times slower and their timing tests flake
  (measured: load average 100+ on 16 cores, gates 3× slower). The coordinator
  schedules load runs for when no other lane is gating.
- **A lane rebases once, at the end**, and the coordinator lands in batches, so
  lanes don't rebuild after every landing.
- **Never clean a build cache that will be reused** (`cargo clean` and the like).
- **Make and retire lanes with the `lane` skill** (`skills/lane/`): `lane new
  <name> [rev]` adds the workspace and clones the repo root's `target/` into it
  (APFS `cp -c`: instant, blocks shared until cargo rewrites them);
  `lane retire <name>` forgets it and deletes its directory, cache included. A
  new lane clones the root's, so a spare cache is never worth its disk. The
  root's `target/` is the base: integrators gate in the default workspace
  without `CARGO_TARGET_DIR`, which keeps it warm on trunk. `du` counts clones
  in full; `df` doesn't.

### Work

- **Linear history on trunk**: rebase chains, never merge commits.
- **DRY.** Writing the same thing twice is the signal to move it one level down.
- **Simplify by generalizing.** Prefer the change that makes the system smaller
  AND more general: unify parallel mechanisms behind one abstraction rather than
  adding a sibling. Every proposed abstraction carries a *simplification ledger*
  (concepts and lines removed versus added) and is rejected if it does not come
  out ahead. Keep aspects orthogonal: pure-data contracts, separable traits,
  operations and events as serializable values instead of callbacks, so pieces
  compose without knowing each other.
- **Parallelize; migrate later.** Refactors do not gate feature lanes; whichever
  lands second migrates its slice. Accepted trade-off: merge conflicts over idle
  lanes. A refactor lane keeps risky rewires **additive-first, cutover-last** so
  parallel chains merge textually.
- **Docs before eng; externalize by default.** Decisions, ideas, plans and
  principles never live only in a context window; capture them in the doc web
  the moment they are settled (a position mid-discussion is not: *Agents never
  push*).
- **Land small, and don't widen your own scope.** A new ask is a new lane. Each
  lane lands as soon as its gates pass, so a refactor migrates landed code piece
  by piece. Work much larger than briefed: land what is coherent and say plainly
  what you left and why; scaling the job down is the human's call.
- **The coordinator doesn't creep either.** A new ask for a running lane becomes
  a new lane, queued until the first lands if they would touch the same files.
  Only a decision that *changes* the brief (a default, say) goes to the running
  lane. A lane that has reported is landed and closed before anything new is
  asked of it.
- **Fork, don't pile on.** When a new ask builds on a running lane's unlanded
  work, start the new lane from that lane's commit (`lane new <new> <its
  change>`), with the conversation forked if it needs it. It rebases onto trunk
  once the parent lands; the parent stays small and lands first.
- **Steer rarely.** A message reaches a lane only between its turns, often long
  after it was sent, onto work that has moved on
  ([simply-chris](https://simplychris.ai): *"stop steering agents too much, often
  your messages land with them MUCH later after they've done a bunch of work"*).
  Give the whole brief up front, and spawn only once the ask has settled: while
  the human is still shaping it, converge in the conversation. **Before every
  message to a running lane, check**:
  - **Would its result be wrong without this?** If not, it waits for the
    `followup` after its report, or becomes the next lane. A feel or visual
    iteration ("too fat", "too subtle") is never a steer.
  - **Have you read its latest output?** It may have done this, or moved past it.
  - **Is the human's burst over?** At most one consolidated message per lane,
    never one per remark: each makes the lane stop and reorient.
  - **Does it replace an earlier message?** Say which ("supersedes my 10:20
    message"): messages arrive late and out of order.
  - **Might the lane be finishing?** Then don't send it (*A lane's report is a
    file*).

  **An urgent change does not go through a running lane**: the message arrives
  late or not at all, and an interrupt aborts the lane's turn. The coordinator
  makes the change itself, or stops the lane and takes its work.
- **The human's diagnosis is the brief.** When the human names a root cause, the
  work is fixing that cause, smallest first: not confirming it, measuring around
  it, or exploring alternatives. A lane told the cause that keeps analysing is
  off its brief; take the work back.
- **Markdown tables**: short fixed-width columns first (an id, one emoji status),
  then the free-text description, then the rest (date, source, size), so
  columns align in the human's editor (*Rows in the record*, §2).
- **When a bookkeeping loop repeats, script it**
  ([simply-chris](https://simplychris.ai): *"are there any things you do
  repeatedly that could be ops/scripts"*). A few shell calls per lane, times
  every lane, is most of a context window. The judgement stays human: a real
  code conflict, and what a lane's board substance should say.

### Fences are advisory, not exclusive ([simply-chris](https://simplychris.ai))

Briefs name the files or modules a lane may touch, but **do not gate a lane on
finding files nobody else touches** ([simply-chris](https://simplychris.ai): *"we
don't need to work on things that are exclusively on free files — given we use
workspaces we can sacrifice a little cleanup pre-merge and have more stuff work
in parallel, as long as there's not massive refactors involved."*).

Overlap costs rebase conflicts, which are cheap and local. What still warrants
serialising is a **massive refactor**: ask *"is the file being restructured, or
just extended?"* Extension parallelises; restructuring does not. Fences remain
**ownership hints** ("if you need to change X, say so in your report").

### Don't mix long work into a field of short work ([simply-chris](https://simplychris.ai))

*"Long work parallelizes poorly with lots of short work, unless it's something
really different like research."*

A multi-stage lane among many short ones holds a workspace for hours while its
base drifts and its merge grows with every sibling that lands: short lanes
absorb rebases cheaply, long ones pay compound interest. **Work of a genuinely
different kind** (research, surveys, design docs, measurement rounds) is the
exception: it touches docs and cannot collide semantically with code lanes.

**Fire long multi-stage code work when the board is quiet**, or stage it so each
stage is short. Prefer many small lanes otherwise.

### Lanes cannot address each other by label

A board label is not an agent name: a message one lane sends another by label
bounces. **The coordinator alone holds every lane's agent id**, so every
cross-lane message routes through it, and cross-lane dependencies are the
briefer's problem.

- **Put the peer's agent id in the brief** when two lanes are known to share a
  file or an abstraction. One line saves a bounce at exactly the moment both are
  about to write the same code.
- **Relay promptly, and decide while relaying.** The coordinator is the only
  party who sees both lanes, so *"we both think we own this type"* comes back
  **settled**, not forwarded; while it hesitates, both lanes keep building.

**Overlapping lanes are cheap for edits and expensive for abstractions, because
only one abstraction can live.** A refactor implied by a mid-flight decision is a
new shared abstraction: assign it to exactly one lane, in writing, before either
starts. **The lane that cannot do its own work without touching those lines owns
them.**

### Show the UI; don't make the human rebuild it ([simply-chris](https://simplychris.ai))

A UI change is rendered, not described, into a shared, dated, lane-labelled
directory under the repo root, and the report says so. The lane has already paid
the build and rendered the scenes to check its own work; redirecting the images
costs one environment variable and saves the human a full rebuild
([simply-chris](https://simplychris.ai): *"having to rebuild it from scratch
myself takes a while … and subagents are already doing all that work and
screenshotting."*).

- **The path is the repo root's, by absolute path, not `$PWD`**: a lane's `$PWD`
  is its own workspace, where the human never looks and which is deleted with it.
- **Keep only the scenes that changed.** Render to scratch, diff against the
  previous run, keep what changed plus what the lane added: copying every scene
  buries the two that matter. A deliberate **baseline** set is the exception: it
  keeps everything, so the next lane has something to diff against.
- **Say both numbers**: *"21 rendered, 3 changed"*. "Nothing changed" tells the
  human they need not look.
- **`reference/` is evidence: never overwrite or clear it.** It holds captures
  of other people's software and the human's own. `progress/` is dated and
  lane-labelled so lanes don't clobber each other, and stale directories there
  are free to delete.
- **A screenshot is not proof the change is good.** The measured claims still
  belong in the report and the changelog.

### Briefing a lane

A lane is only as good as its brief. A good one carries the constraints, the
**collisions it will hit** and who owns what, the APIs that moved under it, what
you want in the report, and **which of the briefer's own assumptions it should
verify rather than trust**. That last one has repeatedly returned the most
valuable finding in a lane's report.

### Local-model delegation

Burn bulk-implementation tokens on a LOCAL model so the frontier-model quota goes
to judgment. Limits are real: an agent that hits one dies mid-task.

Verified working: `pi --provider ollama --model <local-model> --no-session -p "…"`
(pi 0.84.3, headless print mode; `--mode json` for structured output,
`--session`/`-c` to iterate with context, e.g. feeding compile errors back).

**The tier**: human → coordinator → supervising agents (one per lane) → local
model (implementation batches).

**Supervisor protocol**:

1. Write the spec and the ACCEPTANCE TESTS first. The tests are the contract:
   never delegate the tests that gate the delegate.
2. Delegate one tight batch: exact files, one worked example ("here is one
   converted module, convert these N the same way"), the conventions, the fence,
   the command to verify, and a hard instruction to change nothing else.
3. Verify: run the gates and review the whole diff like a hostile PR. The local
   model **never commits**; the supervisor commits after review, pruning slop.
4. Iterate with the error output, at most ~2 rounds, then take over: review cost
   must stay below writing cost. Rewriting more than 30% means the task was
   miscategorised: do it directly next time and note it.

**Delegate only well-specified mechanical work**: template-following module
batches, test boilerplate, mechanical API sweeps (e.g. a 45-file signature
migration), doc-table regeneration, rename chores. **Never delegate**:
architecture, compiler or unsafe internals, conflict resolution, contract and
design decisions, anything spec-ambiguous. A loosely specified task (a test
port, say) comes back slow, misusing private APIs with the wrong semantics, and
gets rewritten.

**The switch goes both ways.** Pause it for laptop heat or GPU contention when
the human needs the machine; prefer batching runs over keeping the server warm.
**Re-enable it under quota pressure**: local latency beats no quota. Which way it
is set *now* is live state, on the board.

### Constraint hygiene

When work is throttled by a constraint (quota, a blocking lane, a paused
dependency), record WHICH constraint and lift the throttle the moment it stops
applying. The failure is a conservative policy outliving its cause and quietly
serialising work nobody chose to serialise: a model-quota freeze never applies to
lanes on another model, so after a model switch lift it yourself rather than
wait for the human to ask why everything is sequential. Default posture remains
parallelise-and-merge-later.

---

## 5. How we state claims — #SimplyAILogic ([simply-chris](https://simplychris.ai))

Docs, reports and briefs reason **modally and constructively**, not classically:

1. **No excluded middle.** Don't force a binary. "Not yet constructed" is a real
   third state: a design isn't right-or-wrong before it exists, and a claim
   isn't true-or-false before someone builds the evidence.
2. **Distinguish kinds of impossibility, because the distinction is actionable.**
   ⚫️ = impossible in every world. 🚫 = impossible *in this context*, open
   elsewhere. ◇ = possible. □ = necessary. **Most "we can't do that" is 🚫**:
   usually a single mechanism makes it impossible, and naming it is the lever.
   Writing ⚫️ where 🚫 is meant hides the lever.
3. **Belief carries evidence and stays revisable.** `(p ∧ e) → Bp`: assert with
   what produced the assertion. There is **no T axiom for belief**: we hold false
   beliefs and correct some the day they are written. On contradiction, revise
   (`Bp ∧ B¬p → BR`) rather than pick a side or stall, and keep the correction
   visible; it is usually more useful than the claim.
4. **Fixed past, open future** (`□Past`, `◇Future`). Shipped work is stated
   flatly; roadmap and queue entries are **possibilities, not commitments**, and
   read that way.

---

## 6. The big question (periodic review ritual)

When the human asks "the big question", or at any natural lull, run the pipeline
review across the doc web, in this order:

1. **What other ideas could we be looking into?** File new rows in the ideas
   inbox (generalisations, gaps, adjacent envelope-pushes).
2. **What ideas can we start to put into the roadmap and spec out?** Promote
   mature rows: design rounds for the big ones, roadmap entries for the
   committed.
3. **What roadmap things can we pull onto the board?** Turn roadmap scope into
   launch-ready queue entries, lanes permitting.
4. **What board items can we conclude and mark done in the roadmap?** Close
   finished lanes in both places; prune superseded queue entries.
5. **What decisions can we be discussing?** Surface open calls (pending reviews,
   design forks, go/no-go gates) with a recommendation each.

Answer all five explicitly, docs updated as you go (docs before eng).

In Linear mode the same five run over the initiative: the inbox is its Backlog
issues labelled Idea; the roadmap, its milestone projects; the board, its Todo
and In Progress issues; concluding means Done and, for a finished milestone, a
completed project; decisions are the open Decision issues.

---

## 7. Recovery (crashed session / fresh context)

1. Read the project's `AGENTS.project.md`, this file, and the board (Linear
   mode: the board query, the open-decisions view and `ASKS.md`).
2. `jj log`: every lane's chain is committed incrementally; compare with the
   board's running rows (Linear mode: In Progress issues and their lane
   comments). `jj workspace list` plus a per-workspace `jj status`
   finds uncommitted lane work.
3. Finished unmerged chains → hand to an `integrator`. Dead agents → relaunch
   with the fence from the board row; the chain survives.
4. **Salvage dead agents' transcripts.** A killed subagent's full transcript
   survives at `~/.claude/projects/<project>/<session>/subagents/agent-<id>.jsonl`
   even when the harness says it "won't be resumed". Give the relaunched agent
   its predecessor's transcript path: the tail holds the exact plan and next
   step, finer-grained than the committed workspace state.
5. Private memory duplicates the key conventions and points back here.
