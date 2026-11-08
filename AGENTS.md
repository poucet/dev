# The working system

A reusable way of running agent work on a repo. Nothing here is specific to one
project. A project adopts it with `adopt.sh` (idempotent: symlinks, doc-web
skeleton, ignore files) or by hand — the role definitions go in the
directory the coding harness in use reads them from (Claude Code:
`.claude/agents`; pi.dev: `.pi/agents`):

    # either: ./adopt.sh <project>

This will create the necessary starter docs, link AGENTS.md (relative, to dev's)
with an `AGENTS.project.md` beside it, and symlink the agents.

Every rule below came from a real failure. Where a rule carries its reason or a
quote, keep it with the rule: a rule whose reason is stated gets followed.

**A project's own rules.** A project may keep its own rules in
`AGENTS.project.md` at its root. It is binding and is read right after this
file; where the two disagree, the project file wins for that project. This file
stays project-neutral: a project's names, paths, commands, gates and decision
ids belong in its own file.

---

## 1. Roles

Roles are defined by **what they may write** and **whether they may move trunk**.
That is the whole model. Full definitions are in `agents/`.

| Role | Works in | Writes | Moves trunk? |
|---|---|---|---|
| `coder` | own workspace | production code, its tests, its changelog fragment | no |
| `researcher` | own workspace | `docs/research/` only; no production code | no |
| `tech-lead` | own workspace | `docs/design/` only; lands on trunk, a proposal under its review banner | no |
| `designer` | own workspace | UI, plus rendered before/after evidence | no |
| `foreman` | own workspace, dispatches lanes | briefs and track state; little code | no |
| `scribe` | the default workspace | `BOARD.md`, and rows in the other ops docs (untracked) | no |
| `integrator` | the default workspace | conflict resolutions only | **yes — sole authority** |
| `co-developer` | the conversation | the board, the briefs | via `integrator` |

**Why per-role and not per-task.** An agent roster is read once at session start,
so a name invented for one task is always a session late. There are eight roles,
they are permanent, and they are always available.

**The human developer is not one of the eight.** They set direction and priorities, review,
and **edits the board and the ideas inbox freely at any time** — so an agent
re-reads those documents before acting on them rather than trusting a copy it
read earlier. They launch the application themselves; agents never do (it steals
their screen focus).

Two rules hold the model together.

**A lane rebases itself onto trunk and stops.** Its last act is to rebase, re-run
its gates *after* the rebase, and report. It does not land itself. One writer to
the bookmark — otherwise you get N-way races on trunk, which is how a repo ends
up with conflicted commits inside its own history.

**Trunk holds still while lanes are rebasing onto it.** Moving it underneath a
running lane corrupts nothing, but it silently invalidates that lane's gate run,
and green on a base nobody will integrate is not evidence: the lane rebases again
and re-resolves the same conflicts. Batch integrator commits; land them after
lanes report.

**Anything over ~15 minutes of engineering leaves the conversation.** The
coordinator that talks to the human stays free; long serial work done inline is
dead time for them ([simply-chris](https://simplychris.ai): *"you're doing too
much stuff in main agent, I am blocked by you linearizing all this work"*). Spawn first, then do the small residue.

**Architecture is the human's.** Neither a lane nor the coordinator decides a
design-doc change, a public API or a wire or file format, a crate or repo
boundary, what a component owns, a cross-component semantic (threading, undo
scope, what a mode means), or a user-visible default. A lane that meets one
**stops and asks** its coordinator, unless its brief settles it. The coordinator
**puts it in the decisions file** (*The human channel*, §2) **and waits**; if it
blocks work, it takes the most reversible option and lists it there as *taken
without you*. Bug fixes inside an existing design are not architecture.

---

## 2. The doc web

A project run this way keeps a small set of documents. Most of these rules exist
because something ended up in the wrong one, so each says what does **not**
belong as well as what does.

**These documents carry no policy of their own.** What belongs in each, and what
does not, is stated once — here — and a document that restates it drifts from
this list and pollutes the content it exists to hold ([simply-chris](https://simplychris.ai): *"the
operational sections at the top of what belongs in which doc … belong in
AGENTS.md and pollute those docs"*). Each opens with one pointer line and, where
its rows carry status marks, the legend for reading them: a key belongs beside
its table, a policy does not.

**Working state or history.** The documents that decay — the board, the human
channel, the record, live notes and drafts — are **working state, not
history**. They live in one untracked directory in the default workspace,
**`docs/ops/`**, which ignores itself (§3): no commits, no rebase conflicts,
and one copy, always the current one. The one decaying document that is tracked
is **`CHANGELOG.md`, at the repo root**, because it ships with the code it
describes.

| In `docs/ops/` | What goes in it | Who writes it | Pruned when |
|---|---|---|---|
| **The human's view** | | | |
| `BOARD.md` | running, next, what waits on the human: line items | coordinator (or `scribe`); the human, freely | a row leaves the day its work lands, into `LANDED.md` |
| `LANDED.md` | every board row that left the board, newest first, under its board label: what, when, change ids | coordinator (or `scribe`) | never: it is the record of the work (what a user gets is the changelog) |
| `DECIDE.md` | decisions for the human, one row each, with the context to answer | coordinator | answered → moved to `DECISIONS.md` |
| `ASKS.md` | commands only the human can run, with the context to judge them | coordinator | once they have run it |
| **The record** | | | |
| `ISSUES.md` | defects and rough edges, not scheduled | coordinator, from lane reports | fixed → a one-line verdict |
| `DECISIONS.md` | settled decisions with their rationale | coordinator | never: a later row supersedes |
| `IDEAS.md` | the ideas inbox | coordinator; the human, freely | never deleted: an idea moves down |
| `ROADMAP.md` | horizons and versions: only what is not done | coordinator | done → the changelog has it |
| **Live notes** | | | |
| `STATUS.md` | the coordinator's live notes: lanes running, ready and unintegrated, where trunk is, side lines | coordinator (or `scribe`) | rewritten as it changes |
| **Work in progress** | | | |
| `drafts/` | proposals before they become a design doc, review aids, triage | coordinator; a lane's draft arrives in its report | landed as a design or research doc, or answered → `.trash/` |

**Rows in the record** start with a short id, then **one** emoji status column,
then the description; any other column (date, source, size) comes after it. Ids
are zero-padded so the first two columns line up when a human scans, stable,
never reused, and assigned by the coordinator. The prefixes live here and only
here:

| Doc | Id | Status legend | Row |
|---|---|---|---|
| `LANDED.md` | the board label, e.g. `` `flaky-2` `` | 🚧 landing · ✅ landed · 🔀 folded elsewhere · 📄 finished, not landed · 🗑️ dropped | `\| `flaky-2` \| ✅ \| what finished \| when \| change ids \|` |
| `ISSUES.md` | `I-007` | 🐛 defect · 🔧 rough edge · 🔬 triaged · 🔄 being fixed · ✅ fixed · 🗑️ won't fix | `\| I-007 \| 🐛 \| what is wrong \| found \| verdict \|` |
| `DECISIONS.md` | `D-042` | ✅ in force · ♻️ superseded · ❓ reopened | `\| D-042 \| ✅ \| decision \| rationale \| when · change id \|` |
| `IDEAS.md` | `N-012` | 💡 open · 🔶 partly answered · 🎯 next up · 📋 queued · 🔄 in flight · 🔬 researched · ✅ shipped · 🗑️ declined | `\| N-012 \| 💡 \| idea \| notes \| added \|` |
| `ROADMAP.md` | `R-12` | 🔄 in flight · ⏸️ paused · 📋 queued · 🔶 partly shipped · 🎯 next up · ⬜ open | `\| R-12 \| 📋 \| item \| size \| ideas \|` |

- **Lanes read `docs/ops/` by the default workspace's absolute path** (their own
  workspace has none) and **never write it**.
- **A lane reports; the coordinator records.** Issues found and closed,
  decisions taken and follow-up work go in the lane's report, and the
  coordinator writes them into `docs/ops/`.
- **A lane's changelog entry is a tracked fragment**, `changelog.d/<LANE>.md` at
  the repo root (*How a lane writes into shared documents*, below).

### `BOARD.md` — the live board

The concept matters more than the file. It is a **shared, live document that
every agent reads before acting and writes when its state changes**, and it is
the human's primary view of what is happening and what needs them.

- **Line-items only.** Prose is what lanes collide on: every lane that edits the
  same narrative paragraph conflicts with every other, and line items don't.
- **Lanes never write the board**, and no role owns a section of it: the
  `integrator` writes none of it, so the `scribe` never waits for one.
- **Keep it short.** It exists to show the *live* work.
- Sections: running · next · waits on the human · milestones · deferred by
  decision.
- **Not here**: rationale, discussion, anything addressed to the human. Those go
  to the human channel below. A board entry is a row, a state and a label.
- **Keep it current.** The coordinator updates it on every spawn, landing and
  plan change, in the same turn. It is untracked: there is nothing to commit.
- **What landed is told in the changelog, never here.** On landing the lane's
  changelog fragment is folded in, and its row leaves the board the same day.
- **Whatever waits on the human is one hop from here** — decisions in the
  decisions file, things to run in the asks file (*The human channel*, below),
  and the board names both. Not in a commit message, not in a banner on a file.

**Edit it by hand, not by script** — read the file and write the intended
result, then re-read the section you touched. It is one file, prose plus tables,
and the file everyone navigates by. Being untracked, it never conflicts; what
goes wrong when a shared document is merged is under *Landing*, rule 3.

**A row's id is its label**: the lane's name (`flaky-2`, `ui-shell`), never a row number. Numbers shift as rows come and go and mean nothing a day later; a label survives into `LANDED.md`, commit-free notes and conversation. **A label is something the human types.** Never strike a label through — a
`~~LABEL~~` cannot be typed to fire a lane, tildes are awkward to reach, and a
struck row reads as *present but crossed out* when what is meant is *gone*. A
landed lane's row **moves to `LANDED.md`** under the same label (the changelog says what a user got); a superseded one is deleted and its successor says what it replaced.
Status lives in the status column and in which section the row is in, never in
the label.

### `STATUS.md` — the churny half of the board

The board splits in two, because its halves change at different speeds.

- **`BOARD.md` is for the human**: what runs, what is next, what waits on them.
- **`STATUS.md` is the coordinator's live notes**: lane ids, chains ready and
  unintegrated, where trunk is, side lines. It changes hourly.

Both are untracked, and that is the point. Both a `scribe` and an `integrator`
write in the default workspace and must not run at once; a **gitignored** file
does not dirty the working copy at all, so the `scribe` can rewrite the board
*during* an integration — exactly when most is changing and the human most wants
to look. Untracked removes the contention rather than scheduling around it.

One untracked **directory** rather than untracked files: one ignore file, and
room for whatever else turns out to want the same treatment.

The trade, stated plainly: **an untracked file is not in a lane's workspace.**
That is acceptable because a lane gets its context from its brief, and reads
the board by the default workspace's absolute path when it needs more. What a
lane must *build on* — code, design, research, the changelog — is tracked.

**Name it where a lane looks.** An untracked directory nobody references is
undiscoverable: the project's own rules (`AGENTS.project.md`) name `docs/ops/`
with the default workspace's absolute path.

### `CHANGELOG.md` — tracked, at the repo root

What got added, per landing, dated and tied to versions — *"what got added, not
all the analysis and story"* ([simply-chris](https://simplychris.ai)). What a capability now is, what
changed in behaviour — especially anything that alters saved files or an API —
and what was fixed, in a line. A few lines an entry. In a merge, **both** entries
survive, the later landing above the earlier.

The displaced material has homes and should reach them rather than be cut:
measurements, root causes and alternatives weighed → `docs/research/`; what a
lane left undone, and a decision that was *made* rather than applied → the
lane's report, from which the coordinator writes a board, issues or decisions
row. **An entry that reads as a narrative is in the wrong document.**

**Not here**: work that has not landed; roadmap intent.

### Dating an entry — clock *and* change id

A date alone is not enough granularity: many lanes land on one date, and nothing
in a dated text says which of them came first.

Every `CHANGELOG.md` entry and every `DECISIONS.md` row carries **both**:

    #### A preset that describes itself (`LIBFIN`) · YYYY-MM-DD HH:MM · oplmqxmn
    | YYYY-MM-DD HH:MM · uvzmuvkl | **The analysis toolkit is a separate crate family…** |

- **The clock** is for a human skimming: roughly when this happened. A lane
  writes it in its changelog fragment at commit time, because the lane is the
  only party that knows, and it is *not* the ordering authority.
- **The change id** is the ordering authority and the verification. Ancestry
  answers "which landed first" exactly — with no ambiguity about *which* moment
  a timestamp recorded, since authoring, rebasing and landing are often hours
  apart. And `jj show <id>` produces the actual change, so a prose record can be
  checked against the tree rather than drifting from it.

**This works because jj change ids survive rebase.** A lane knows its id when it
writes the entry, and the id is still valid after five rebases onto a moving
trunk. A commit hash would not be; do not use one.

### `ISSUES.md`

Defects and rough edges anyone notices in passing: file it, triage it, **DON'T
interrupt a lane for it**. A **parking lot, not a queue** — nothing here is
scheduled until it is promoted onto the board. Found and fixed by lanes,
recorded by the coordinator from their reports, and **never silently closed**. A resolved issue
loses its long description, keeps a one-line verdict, and points at the changelog
for the account, so the table reads as what is still open.

**Not here**: features somebody would ask for by name (→ ideas), or work already
scheduled (→ board).

### `IDEAS.md`

An inbox, in three sections: **Inbox → In-flight → Done**. Ideas arrive raw and
are allowed to be half-formed; that is the point of an inbox. Append a row the
moment an idea surfaces; promote it when it earns a lane. **An idea only ever
moves down** — Inbox (no commitment) → In-flight (it has a board row) → Done
(answered; the account is in the changelog). Ids are stable and never reused, so
a row keeps its number as it moves.

### `ROADMAP.md`

Horizons and versions, and what a version *means* in the register of the ones
before it — built from the ideas story lines, plus the dependencies that gate
them. Horizon numbers continue the version series. **Only what is not done.**

**Not here**: finished work — that is the changelog, version by version.

### `DECISIONS.md`

Dated decisions with their rationale, so a settled question stays settled and
nobody relitigates it three sessions later. One row, one decision, one date.

### `docs/design/`

Proposals and the locked design. **Design documents always land on trunk**, the
proposals included: the human reviews on trunk, never in a lane's workspace
([simply-chris](https://simplychris.ai): *"I can't review design docs in workspaces, they need to be in main"*).
A proposal lands with a `⚠️ PROPOSAL — awaits review` banner and its open
questions marked; the decisions it waits on go in the decisions file the same day.
When the human answers, the next commit folds the answers in and takes the
banner off. **Review gates what a design *decides*, not whether it is on trunk**:
nothing is built on a proposal's open questions until they are answered.

**Changing a design needs review; recording that it was built does not.** Once a
design is approved, a lane marking its own stage as built, correcting a sketch to
match the code, or adding a finding the design did not predict is **reporting,
not proposing**, and does not wait on a second review. Gating those makes an
approved document read as pending long after it was signed off, in the very
document the human looks at to check. A lane that wants to *change* what was
decided says so in its report, not as a banner on the file.

If a design's section numbers are cited from source code, **they are never
renumbered.**

### `docs/research/`

Investigations and measurements. A number with its method beside it settles an
argument; a paragraph of plausibility does not. Also **the argument behind
anything designed but not built**.

**There is no register of unlanded designs** ([simply-chris](https://simplychris.ai): *"I
kind of feel like DESIGN.md as a doc should not exist unless there are things
that don't fit into the docs I just mentioned"*: everything such a register would
hold fits elsewhere). An unlanded
design is **a research note plus a queue row**: the note holds the argument and
the measurements, the row holds what a lane would do and what it costs, and the
decision it waits on lives where it can still be answered — a board row's
priority field, an ideas note, or a decisions row once it is answered. When it
lands it moves into the design document.

### `docs/guides/` · `docs/reference/`

How to do a thing — build, run, release, use a tool. Generated references say so
and are **regenerated, not edited**.


### The human channel — `DECIDE.md` and `ASKS.md`

Two files in `docs/ops/` for what passes between the human and the agents.
**Untracked, so that conversation never enters history.** This is what lets the
board be line-items at all: the narrative has somewhere to go.

Everything that waits on the human lives in these two, **never only in chat or
a commit message** — chat scrolls away while lanes report:

- **`DECIDE.md`**: decisions for the human, one row each, with a short answer
  code and the context to answer it. An answered row moves to `DECISIONS.md`.
- **`ASKS.md`**: things for the human to run.

The coordinator writes both; a lane puts its questions in its report. A lane
never writes them, so it cannot reserve a row id there: lanes that number rows
from their own counts collide.

The asks file holds **commands only the human can run**, with the context to
judge each one. `rm` is denied to agents, so deletions land here rather than in a chat
message ([simply-chris](https://simplychris.ai): *"copy paste from Claude Code is terrible"*). **A
block that names paths names them explicitly** — an *"everything except…"* filter
is evaluated when the human runs it, in a world the agent could not see, which is
how a cleanup deletes a lane started after it was written.


### Where they live

As few top-level documents as possible ([simply-chris](https://simplychris.ai): *"where
should the remaining top-level docs go? Ideally only one or 2 key ones remain"*):

- **the repo root** holds `AGENTS.md`, and the project's `AGENTS.project.md` if it
  has one, and nothing else of this kind;
- **one untracked directory, `docs/ops/`,** holds what *decays* — the board,
  the human channel, the record, live notes and drafts. These are the documents that are wrong the
  moment work lands, which is why they live together and get maintained
  together, by the coordinator, in the default workspace;
- **`CHANGELOG.md` sits at the repo root**, tracked, with its `changelog.d/`
  fragments: the one decaying document that ships with the code;
- everything else lives by kind: design, research, guides, reference. A folder
  appears when there is something to put in it; nothing is laid down empty.

Documentation lives in the docs tree, **never inside the source tree**.

### A repo you don't own

Everything above assumes the repo is yours to lay this system out inside. A
shared work repo — reviewed by people who never opted into any of this — gets
a second adoption mode, not a variant of the first one.

**Two repos, sibling, not nested.**

    ~/work/<project>/
      repo/           the shared repo — git, PR'd, reviewed, untouched by this system
      ops/            a separate jj repo — AGENTS.md, docs/ops/, agents/, all of it

`repo/` never contains a line of this system — not `AGENTS.md`, not
`BOARD.md`, not a gitignore entry, nothing a teammate's `git status`, PR diff,
or repo search would ever surface. `ops/` is the same doc web this file
describes everywhere else, laid out per §3, just pointed at a different remote
(or none) than the code it tracks.

**Why sibling and not nested inside `repo/`.** Nesting only works when the
nested thing is *another working copy of the same repo* — a git worktree or a
jj workspace, which the repo's own git/jj already understands and which
carries no history of its own. `repo/.worktrees/<lane>/` (or
`repo/.claude/.worktrees/`) is exactly that, and belongs inside, per §3's rule
below. A second, independent repo with its own object store is a different
kind of thing: git can mistake it for an embedded repo and gitlink it into a
commit, and the only thing keeping it invisible to the shared remote would be
a per-clone `.git/info/exclude` entry that a re-clone silently drops. A
sibling directory needs no such entry to be safe — nothing that operates on
`repo/`'s tree can ever reach a path that isn't inside it, structurally, not
by discipline.

**What still lands in `repo/`**: code, its tests, and a real `CHANGELOG.md` if
the team already keeps one by convention — check first, don't assume. Nothing
else from this file's doc web belongs there.

**Landing changes shape.** A lane's last act is still the same
rebase-and-report as always, but landing means opening a PR against `repo/`
that passes the gates clean, not moving anyone else's trunk — the changelog
entry and the lane's report record the PR link or merge commit in place of a
bookmark move. Review is the team's gate, not the integrator's.

**Lanes don't write `ops/`** any more than they write `docs/ops/` in a repo
you own: they report, and the coordinator records. A lane's changelog fragment
goes wherever the changelog lives — in `repo/` if the team keeps one there.

### How a lane writes into shared documents

- **A lane writes one tracked file of record: `changelog.d/<LANE>.md`** at the
  repo root, its user-facing entry. It never edits `CHANGELOG.md` directly, and
  never writes `docs/ops/`.
- **Everything else goes in its report**: issues found and closed, decisions
  taken, follow-up work with a priority. The coordinator records them.
- **On landing the fragment is folded into `CHANGELOG.md` and removed.**
- **the changelog is user-facing** — what a person gets, not what the code
  did. For internal work the honest line is *"nothing changes for you; this is
  what stops a class of bug reaching you."*
- **An issue says what is wrong before anything else.** A repair history is one
  clause at the end, never the opening.
- **A design change lands as a proposal**: the banner on, the changed or open points marked, the questions in the lane's report. A lane never presents its own change to a design as decided.
- **Fix it, do not file it.** A small defect found in passing is closed in the
  lane. [simply-chris](https://simplychris.ai): *"I hate that issues keep piling up instead of getting resolved."*

**Why fragments rather than direct edits.** Two lanes editing one changelog is
a merge conflict in prose, which a resolver settles by picking a side rather
than by understanding either. A fragment per lane cannot collide; they are
folded **in landing order**, which is the only order that reads
correctly, and deletes them. The cost is one step that must not be skipped:
**a fragment that survives its fold gets applied twice.** Retire it in the same
commit that folds it, or the next fold reads it as unlanded work.

**Ids are the coordinator's.** A lane cannot reserve an issue or decision id:
it cannot see another lane's work in flight, so lanes counting on their own pick
the same id. A lane names what it found in words; the
coordinator assigns the id when it records it.

---

## 3. Default directory structure (a repo you own)

    AGENTS.md                  this file: a symlink to it, or a copy
    AGENTS.project.md          this project's own rules (optional; wins over this file)
    .claude/agents ->          symlink to <this system's repo>/agents
                               (Claude Code; pi.dev uses .pi/agents instead)
    CHANGELOG.md               tracked, user-facing; folded from the fragments below
    changelog.d/<LANE>.md      tracked; a lane's entry until its landing folds it in
    docs/
      ops/                     untracked working state, default workspace only (§2):
                               BOARD.md DECIDE.md ASKS.md         the human's view
                               ISSUES.md DECISIONS.md IDEAS.md ROADMAP.md   the record
                               STATUS.md                          live notes
                               drafts/                            work in progress
      design/                  the design, proposals included (banner until reviewed)
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
(`docs/ops/.gitignore`, `.workspaces/.gitignore`, `.trash/.gitignore`…),
not a path entry in the root `.gitignore`. The directory carries its own rule
wherever it is, and the root ignore file stays the project's.

Workspaces go **inside** the repo, not `../` siblings — siblings pollute the
directory the other repos live in. This is about extra working copies of *this*
repo (git worktrees, jj workspaces); a separate repo with its own history —
the `ops/` sibling for a repo you don't own — is a different kind of thing and
is a sibling on purpose. See *A repo you don't own* above.

---

## 4. Operating rules

### Before you land anything: check trunk is where you think it is

**Verify the bookmark against the actual tip.** After a history operation — an
`op restore`, an undo, a rebase someone else ran — a bookmark can be left
pointing at an old commit, many commits behind, while the real work sits above
it, and `git log` agrees with the stale bookmark. Nothing warns you; every
rebase you then run is onto the wrong base. Check first, every session.

**Know what is actually unintegrated, from a query, not from memory.** Ask the
repo — in `jj`, `ancestors(<workspace>@) ~ ::<trunk> ~ empty()` — and count. A
board can record a lane as landed when it has not been. A workspace whose
working copy is *empty* is normal and means nothing: a finished lane's work sits
in the ancestors, not in `@`.

**Bookmark a chain's tip before forgetting its workspace.** Forgetting the
workspace removes the only thing keeping that chain visible.

**One workspace, one writer — the default workspace included.** While an
`integrator` is landing, nobody else writes in the default workspace, and that
includes whoever is dispatching. This is the sibling of *trunk holds still while
lanes are rebasing onto it*. An integrator that finds unexplained changes in its
own working copy cannot tell whose they are, has to park them as a side commit to
keep `@` clean, and spends its judgement on archaeology instead of landing. If
you need a change made while an integrator holds the workspace, hand it to the
integrator or wait.

### Trunk and the working copy

**`default@` is always an empty commit one above trunk.** The integrator's
working copy is scratch, never the thing that ships. The loop
([simply-chris](https://simplychris.ai)):

    jj new                      # @ is an empty child of main
    …edit…
    jj commit -m "…"            # describes @ AND opens a fresh empty child
    jj bookmark set main -r @-  # main is the commit just made, @ stays empty

`jj commit` is the point: it does the describe and the `jj new` in one step, so
there is no window in which `@` is a described commit waiting to be pointed at.
`@-` then names it, and `@` is empty again without a second command. Two things
go wrong when the loop is broken, and both are invisible until someone reads the
log:

- an edit made while `@` *is* trunk silently joins the last commit, so two
  unrelated changes end up sharing a message;
- a `jj describe` on a commit the bookmark already points at **overwrites** its
  message rather than starting a new one, so a landed lane's account is replaced
  by the next thing typed.

**The integrator does not run into a version.** When the last lane of a milestone
lands, stop and hand back rather than continuing to the tag ([simply-chris](https://simplychris.ai):
*"don't go there automatically, let's take the opportunity for a human review and
cleaning up old workspaces"*). Every lane was reviewed against its own brief and
nobody has read the result as one thing; a version boundary is the natural place
for that and the last cheap one, because after a tag a correction is a change to
something released. It is also the only moment when no lane is rebasing, which is
what workspace cleanup and any history repair need.

### The lane lifecycle

1. Idea or direction lands → **docs first** (an ideas row, a board queue entry, a
   decisions entry as appropriate) before engineering starts.
2. Launch: `jj workspace add .workspaces/<lane> --name <lane>`, plus a brief.
3. The lane works: incremental commits on its own chain, with the project's
   version control and **never git in a colocated repo** — a `git commit` after
   `jj new` lands on a detached head. Chains are crash-safe: they survive a dead
   agent, and a replacement resumes from the same fence.
4. **Every finishing lane writes its own record**: its changelog fragment in its
   final commit, and in its report the board substance — what it finished, the
   follow-up work it discovered with a priority, issues and decisions. The
   coordinator records it from the report instead of reconstructing every lane's
   state by hand, which does not scale past a handful of lanes.
5. **The lane's last act is to rebase itself onto trunk**, resolve every conflict,
   and **re-run the gates afterwards**. Then report, saying what conflicted and
   how it was resolved. Then stop.
6. A `integrator` lands it. **Landing is a pointer move, not a rebuild**
   ([simply-chris](https://simplychris.ai)):
   - **The lane sits on the current trunk and gated there** → `jj st` (refuse if
     `default@` is not empty: those edits are the human's), then `jj new <lane
     tip>` from the default workspace. **No re-gate**: it is the same tree the
     lane already gated, and re-running the suite on it costs minutes and proves
     nothing.
   - **Trunk moved since the lane rebased** → send it back to rebase and re-gate,
     or rebase it yourself and re-gate **only the blast radius**.
   - **Fragment folds are batched** into one docs commit — at a natural pause or
     at the version stamp — never one fold commit per landing. Every trunk commit,
     docs included, makes every running lane rebase again.
   - **One gate per tool call, with a tight ceiling.** Run each gate in its own call, output to a log, and read `$?`. If the tool takes a timeout, set it to about twice that gate's usual time (minutes, not hours): a ceiling of two hours means a hung gate costs two hours, and no steering message reaches the agent for the whole call ([simply-chris](https://simplychris.ai): *"using a 2h timeout, wtf"*). A run that hits its ceiling is a hang to investigate, not something to re-run. **Nothing a lane runs can wait for input**: run commands with `</dev/null` and `JJ_EDITOR=true GIT_EDITOR=true EDITOR=true`, so a prompt fails at once instead of waiting out the ceiling; and write gate output to a log, whose growth is how the coordinator tells a slow run from a stuck one.
   - **Never sleep-poll a gate.** Run it in the foreground, output to a log,
     and read `$?`. A backgrounded run plus `sleep 600` waits the full ten
     minutes after the gate is done, and no steering message reaches the agent
     until the sleep returns. If a run must be backgrounded, wait on it
     with `while kill -0 <pid>; do sleep 5; done`, which returns the moment it ends.
   - Then tell the human.
7. Recycle: forget the workspace when a lane is done and move its directory to
   `.trash/` (agents cannot `rm`). Its build cache goes to the next lane, not to
   the bin: see *Spare the disk* below.

**Why the rebase belongs to the lane and not the integrator** ([simply-chris](https://simplychris.ai)):

- **The lane knows what its own change meant.** The integrator resolving someone
  else's conflict is guessing at intent, and a wrong guess in a union merge is
  silent — it produces a plausible document nobody wrote: an entry loses its
  opening line, a body is reattached to the wrong heading, a changelog account
  ends up describing another lane's work.
- **A rebase can break a lane that merged cleanly.** Another lane may have
  changed the API this one calls, so a conflict-free rebase is not a green one.
- **Resolving at the tip is not resolving.** See below.

The integrator's job is then what it should be: read the report, move the
bookmark, verify.

**Never rebase a RUNNING agent's chain.** Integrating a
lane's chain while that agent is still working corrupts its working copy: the
stale-workspace recovery fires under it and can revert it to an older revision,
leaving its change divergent and its work lost. **Integrate only chains whose agent has reported and
stopped.** If a lane must land early, message it to commit and stop FIRST, wait
for the completion notification, then rebase. The integrator's own working copy
going stale is harmless by comparison — that is just this session catching up.

### Landing

1. **Resolve the oldest commit in a chain first, never the tip.** A clean tip can
   sit on conflicted ancestors. Resolving at the tip leaves conflicted commits in
   the repo's own history.
2. **Read the label on every conflict block; never assume which side is which.**
   `jj` writes `+++++++ … (rebase destination)` for trunk's side but
   `(rebased revision)` for the lane's — and it alternates *within a single
   file*, sometimes between two blocks of the same document. Assuming corrupts
   the document, and the merge that did it looks right.
3. **Never resolve a shared document with a union script.** A blind union (keep
   `+` lines, drop `-` lines, keep context) **silently mangles entries**: a row
   both sides edited loses the unchanged half, and a `-`/`+` rewrite of the same
   row can leave the old row duplicated elsewhere. It duplicates headings,
   orphans one lane's body under another lane's heading, strips an entry of its
   opening line and drops corrections entirely, and only someone reading the
   file properly catches it. Worse, the damage survives: a union merge can leave
   a document with **two tables for one section, with different column
   headers**, that nobody notices for sessions. After resolving any document by machine, **grep for duplicated
   headings.**
4. **A clean textual merge can still leave a semantic conflict** — a changed
   signature, a moved function, an enum that gained an arm. For example: a trait
   impl added on trunk keeps the old method signature after a clean merge and the
   crate does not compile; or a lane passes a value to a function whose parameter
   type another lane turned into an enum. The
   gates are the only proof, and neither lane could have seen its own.
5. **Deletion-versus-modification is the reorg conflict.** When trunk splits a
   file into a directory and a lane edited the old file, the conflict presents as
   the entire file recreated with markers — a two-line change can look like a
   thousand-line conflict. **Extract the lane's real `+`/`-` delta first**, take
   trunk's deletion, then relocate that delta into whichever new module owns the
   responsibility, and say where you put it. Where `rm` is denied, accept the
   deletion with a restore-from-trunk of that path.
6. **Import lists are the most common code conflict** after a reorg. The merge is
   almost always *trunk's form, minus what the lane removed, plus what the lane
   added* — then verify the removed symbol is genuinely unused rather than
   trusting the lane.
7. **When trunk changes a module's visibility, decide by the rule, not by
   copying a side.** Is the module reached by path from another crate? Are its
   contents re-exported at the root? Answer those and the visibility follows;
   picking whichever side looks tidier reintroduces exactly what a
   surface-cleanup lane just removed.
8. **`jj squash` moves the whole working copy, not the file you had in mind.**
   Pass explicit paths when the working copy holds more than one concern —
   otherwise an unrelated asset lands inside a documentation commit, and you will
   not notice until the commit after it reports `(empty)`.
9. **`default@` is always an empty commit one above trunk.** Land with `jj new
   <lane tip>`, which makes that empty commit on the tip — see *Trunk and the working copy* above for the loop and
   the two ways breaking it corrupts a message.
10. **Never abandon a commit trunk points at without re-setting the bookmark.**
    Abandoning deletes it, and the next command fails with "revision doesn't
    exist" rather than anything that explains itself.

### Ordering and document conventions

- `CHANGELOG.md`: keep **both** entries; the **later-landing** lane's goes above.
  Getting this backwards is easy when both are dated the same day — order by when
  each landed, not by which side of the conflict it came from.
- `docs/ops/` (board, issues, decisions, ideas, roadmap) is untracked: it never
  conflicts, and no lane's commit touches it.
- **Land `docs/design/` changes like any other docs**, banner intact: the human
  reviews them on trunk. Never strip a review banner while landing.

### Repairing history, if it comes to that

Conflicts stored in a commit's own tree are history quality, not a broken tree:
the tip can be clean and everything can build while ancestors carry markers. Fix
it only under three conditions, and the first two are why it usually waits.

- **No lane may be running.** Every lane rebases onto trunk, so rewriting it
  underneath them invalidates their work.
- **Resolve oldest-first, in a scratch workspace.** A wrong attempt multiplies
  the conflicted commits, so work where an undo is cheap; the operation restore
  that undoes it is safe only because no lane is running (*Environment*: never in
  a shared repo otherwise).
- **The acceptance test is the tree, not the log.** Hash the documents and the
  source before and after; the result must be **byte-identical**. A repair that
  changes content is a different change wearing a repair's clothes.

### Evidence

- **Run the project's gates unfiltered and report them verbatim**, counts
  included. A filtered gate is not a gate.
- **Run the full gates once, after the final rebase**, not before. While
  working, run only the tests you touched (*Spare the disk*, below).
- Never report green without having run them.
- **A blocked human outranks the gates.** When the human is waiting on a fix
  (live breakage, a show), land the smallest fix after a compile check and the
  test that covers it, then run the full gates behind it. Say plainly that it
  is ungated until they pass. Full gates protect trunk from a lane's
  unknowns; they are not a reason to keep a known fix from the person who
  needs it ([simply-chris](https://simplychris.ai): *"PLEASE JUST LAND IT it's doing a full test with 3600 timeout"*).
- **Verify headlessly.** Never auto-launch the application to check something —
  it steals the human's screen focus. They launch it themselves.

### What a commit message says

**A commit message says what the commit did — never what it is waiting for.**
Review state, "PROPOSAL", "NEEDS REVIEW" and the like do not belong in a commit,
least of all in its subject: a commit is immutable and review state changes, so
the message is wrong within hours and stays wrong forever ([simply-chris](https://simplychris.ai):
*"calling out for 'needs review' in commit messages is silly, that's what
BOARD.md is for"*). No co-author lines.

**No internal ops references.** Issue ids, decision ids, lane names, board or
landed-index rows (`I-106`, `N8`, `DEC-42`, `LANE-x`, `ops: … landed`) mean
nothing to a reader of the history, and nothing at all in a public repo. The
subject says, in plain words, what changed and why it matters; the body may
explain more, still in plain words ([simply-chris](https://simplychris.ai), on
`docs(ops): I-106 closed (N8–N11, N13); N12 filed as I-107; landed-index row`:
*"random internal ops docs references as commit messages, they are
meaningless"*). A commit that only updates ops docs says what it records
("record the VST3 inactive-parameter fix as done"), not which rows moved.

**Code and tracked docs never cite ops ids either** ([simply-chris](https://simplychris.ai): *"code and docs should NEVER reference issues and decisions and such by id"*). No issue, decision, idea, roadmap, ask or lane id (`I-007`, `DEC-42`, `X-151`, `T-3`, `N-12`, `A-22`, `SC-11`, a board label) in source, comments, tests, design and research docs, guides, the changelog or a README. Those ids live in `docs/ops/`, which is untracked: in a clone, a review or a public repo they point at nothing, and the rows they name are pruned, renumbered and superseded while the code keeps citing them. Say the reason itself, in plain words, where it is needed ("a scene never creates a channel", not "per T-35"). What may be cited: a design doc's section number (§2.3, which is never renumbered), another file or function by name, and a jj change id in the changelog.

### Referring to the human's points

**Never refer to the human's points by a number alone.** When they raise
several things at once and you answer by number ("1, 3, 7"), they can't tell
how you numbered them: they may not have numbered them at all, they added one
later, or they don't remember which was which ([simply-chris](https://simplychris.ai):
*"when you reference my ideas by number, it's hard to know how you have
numbered them"*). In chat and in docs alike, say what the point *is* with the
number, in a few words ("3 (aligning OSC against the local transport)"), and
when a document keeps the numbering, list the points with their numbers at
the top.

### Survival

- **Commit early and often.** A WIP commit in your own workspace costs nothing.
  An agent that dies mid-task, on a spend limit say, loses everything it had not
  committed. A crash should cost minutes.
- **Commit after each green step**, so a dropped connection loses nothing.

### Environment

- **Agents must run version-control commands unsandboxed.** A sandbox that
  intercepts filesystem syscalls turns a working-copy scan into minutes: `jj log`
  measured **over two minutes** sandboxed and **16 ms** without. It hangs rather
  than fails, so it reads as a repo problem — the same command run by hand
  returns instantly. A slow `jj` is not
  evidence of a large repo, a lock, or a corrupt operation log. Check this first.
- **`jj squash` and `jj describe` open `$EDITOR` and hang an agent forever.**
  `export JJ_EDITOR=true` and always pass `--use-destination-message`.
  `--use-destination-message` is the real fix; `JJ_EDITOR` is the belt.
- **`rm` may be denied, and `~/.Trash` is not the bin.** Move discarded files to
  the project's `.trash/<what>-<date>/` (gitignored; the human empties it). What
  only the human can delete goes in the asks file — except emptying `.trash/`, which
  the human does on their own: never ask for it.
- **Never search `.trash/`** (`grep -r`, `rg`, `find`). It holds retired
  workspaces and their build caches, tens of GB; a `grep -r` into it stalls a
  lane for half an hour or more. Search the source and docs
  directories by name.
- **No `timeout` on macOS.** The command does not exist there; don't wrap a
  build in it. Commit after each green step instead.
- **Spikes live in a workspace, never in `/tmp`.** Under `spikes/<name>/`, its
  own build workspace, committed on the lane's chain, where others can see it;
  the coordinator decides whether it lands on trunk or stays on a side bookmark.
- **Never `jj op restore`, `jj op revert` or `jj undo` in a shared repo.** They
  act on the whole repo's operation log and undo other lanes' commits too,
  merges included. To fix your own mistake,
  `jj restore`, `jj abandon` or `jj rebase` your own changes; if that cannot fix
  it, report it.

### Spare the disk: builds are writes ([simply-chris](https://simplychris.ai))

Every build writes gigabytes to the human's SSD, and build caches are what fill
their disk.

- **Full gates once, after the final rebase.** While working, run only the tests
  you touched. A load or soak harness runs only when the brief asks for it.
- **A load harness runs alone.** It saturates every core by design; run beside other lanes' gates, it makes all of them several times slower and makes their timing tests flake (measured: load average 100+ on 16 cores, gates 3× slower). The coordinator schedules load runs for when no other lane is gating.
- **A lane rebases once, at the end**, and the coordinator lands in batches, so
  lanes don't rebuild after every landing.
- **Never clean a build cache that will be reused** (`cargo clean` and the like).
- **Make and retire lanes with the `lane` skill** (`skills/lane/`): `lane new <name> [rev]` adds the workspace and clones the repo root's `target/` into it (APFS `cp -c`: instant, and the blocks are shared until cargo rewrites them, so dependencies are stored once); `lane retire <name>` forgets it and moves it to `.trash/`. The root's `target/` is the base: integrators gate in the default workspace without `CARGO_TARGET_DIR`, which keeps it warm on trunk. `du` counts clones in full; `df` doesn't.
- **A finished lane's cache goes with it** (`lane retire`): a new lane clones the root's, so a spare is never worth its disk.

### Work

- **Linear history on trunk** — rebase chains, never merge commits.
- **DRY.** Writing the same thing twice is the signal to move it one level down.
- **Simplify by generalizing.** Prefer the change that makes the system smaller
  AND more general: unify parallel mechanisms behind one clean abstraction rather
  than adding a sibling mechanism. Every proposed abstraction carries a
  *simplification ledger* — concepts and lines removed versus added — and is
  rejected if it does not come out ahead. Keep aspects orthogonal and
  decouplable: pure-data contracts, separable traits, operations and events as
  serializable values instead of callbacks, so pieces compose without knowing
  each other.
- **Parallelize; migrate later.** Refactors do not gate feature lanes; whichever
  lands second owns migrating its slice. Accepted trade-off: merge conflicts over
  idle lanes. A refactor lane keeps risky rewires **additive-first,
  cutover-last** so parallel chains merge textually.
- **Docs before eng; externalize by default.** Decisions, ideas, plans and
  principles never live only in a context window; capture them per the doc web
  the moment they occur.
- **Don't widen your own scope.** If work turns out much larger than briefed,
  land what is coherent and say plainly what you left and why. Scaling the job
  down is the human's call.
- **Land small.** No scope creep in a lane: a new ask is a new lane. Each lane
  rebases and lands as soon as its gates pass, so a refactor migrates landed code
  piece by piece instead of stalling feature work.
- **The coordinator doesn't creep either.** A new ask for a running lane becomes
  a new lane, queued until the first lands if they would touch the same files.
  Only a decision that *changes* the brief (a default, say) goes to the running
  lane. A lane that has reported is landed and closed before anything new is
  asked of it.
- **Fork, don't pile on.** When a new ask builds on a running lane's unlanded
  work, start the new lane from that lane's commit (`jj workspace add
  .workspaces/<new> -r <its change>`), with the conversation forked if it needs
  it. It rebases onto trunk once the parent lands; the parent stays small and
  lands first.
- **Steer rarely.** A message reaches a lane only between its turns, often long
  after it was sent, so frequent steers land on work that has moved on. Give the
  whole brief up front; send a running lane only a correction that would
  otherwise make its result wrong. Everything else waits for its report.
  **Batch steers**: each message makes a lane stop and reorient, so the
  coordinator collects the human's remarks and sends at most one consolidated
  message per lane, never one per remark.
  **An urgent change does not go through a running lane**: the message arrives
  late or not at all, and an interrupt aborts the lane's turn. The coordinator
  makes the change itself, or stops the lane and takes its work.
- **The human's diagnosis is the brief.** When the human names a root cause,
  the work becomes fixing that cause, smallest first. It is not confirming it,
  measuring around it, or exploring alternatives. A lane that has been told the
  cause and keeps analysing is off its brief; take the work back.
- **Markdown tables**: short fixed-width columns first — an id, one emoji
  status — then the free-text description, then anything else (date, source,
  size). Keeps columns aligned in the human's editor (*Rows in the record*, §2).
- **When a bookkeeping loop repeats, script it.** [simply-chris](https://simplychris.ai):
  *"are there any things you do repeatedly that could be ops/scripts"*. A few
  shell calls per lane, times every lane, is most of a context window spent on
  bookkeeping. The judgement stays human: a real code conflict, and what a lane's
  board substance should say.

### Fences are advisory, not exclusive ([simply-chris](https://simplychris.ai))

Briefs enumerate the files or modules a lane may touch, and overlaps are
deliberate choices rather than accidents — but **do not gate a lane on finding
files nobody else touches.** [simply-chris](https://simplychris.ai): *"we don't need to work on things that are
exclusively on free files — given we use workspaces we can sacrifice a little
cleanup pre-merge and have more stuff work in parallel, as long as there's not
massive refactors involved."*

Overlapping modules are fine; the coordinator pays for it in rebase conflicts,
which are cheap and local. What still warrants serialising is a **massive
refactor** — a lane rewriting a file's structure makes concurrent edits to that
file genuinely expensive, not merely annoying. Judge by *"is the file being
restructured, or just extended?"* — extension parallelises, restructuring does
not. Fences remain useful as **ownership hints** ("if you need to change X, say
so in your report") rather than hard walls.

### Don't mix long work into a field of short work ([simply-chris](https://simplychris.ai))

*"Long work parallelizes poorly with lots of short work, unless it's something
really different like research."*

A multi-stage lane among many short lanes is the worst case: it holds a workspace
for hours, its base drifts under it while everything else lands, and its merge
grows monotonically with every sibling that finishes. Short lanes absorb rebases
cheaply; long ones pay compound interest. The exception is **work of a genuinely
different kind** — research, surveys, design docs, measurement rounds — which
parallelises fine at any length because it mostly touches docs and cannot collide
semantically with code lanes.

Rule of thumb: **fire long multi-stage code work when the board is quiet**, or
stage it explicitly so each stage is short. Prefer many small lanes otherwise.

### Lanes cannot address each other by label

A lane cannot see another lane's workspace or wait on it, and a board label is
not an agent name. A message one lane sends another by label bounces — **the coordinator is
the only one that holds every lane's agent id**, so every cross-lane message
routes through it whether or not that was intended. Cross-lane dependencies are
the briefer's problem.

- **Put the peer's agent id in the brief** when two lanes are known in advance to
  share a file or an abstraction. One line, and it saves a bounce and a round
  trip at exactly the moment the two lanes are about to write the same code.
- **Relay promptly, and decide while relaying.** A relayed message is not a
  postal service — the coordinator is the only party who can see both lanes, so a
  request like *"we both think we own this type"* comes back **settled**, not
  forwarded. The cost of hesitating is that both lanes keep working, which is
  precisely the failure this is meant to prevent.

The deeper point, since two lanes in the same area can each build the same type
independently: **overlapping lanes are cheap for edits and expensive for
abstractions, because only one abstraction can live.** When a decision lands
mid-flight that implies a refactor, that refactor is a *new shared abstraction*
by definition — assign it to exactly one lane, in writing, before either starts.
The rule of thumb: **the lane that cannot do its own work without
touching those lines owns them.**

### Show the UI; don't make the human rebuild it ([simply-chris](https://simplychris.ai))

A UI change is rendered, not described — into a shared, dated, lane-labelled
directory under the repo root, and said so in the report.

The reason is arithmetic. [simply-chris](https://simplychris.ai): *"having to rebuild it from scratch myself takes
a while … and subagents are already doing all that work and screenshotting."* The
lane has already paid the build cost and already rendered the scenes to check its
own work; without redirection those images land in a build directory and are
deleted by the next clean. Redirecting them costs one environment variable and
saves a full rebuild per lane.

- **The path is the repo root's, not `$PWD`.** A lane runs inside its own
  workspace, so `$PWD/…` writes where the human never looks and which is deleted
  with the workspace. Use an absolute path.
- **Keep only the scenes that changed.** Rendering is all-or-nothing, but a lane
  that copies every scene into its directory buries the two that matter, and a
  few lanes doing it leave piles of near-identical files. Render to scratch, diff against the previous run,
  keep what changed plus what the lane added. The exception is a deliberate
  **baseline** set, which keeps everything precisely so the next lane has
  something to diff against.
- **Say both numbers** — *"21 rendered, 3 changed"*. "Nothing changed" is
  information too, and it is the sentence that tells the human they need not look.
- **`reference/` is evidence: never overwrite or clear it.** It holds captures of
  other people's software and the human's own manual captures. `progress/` is
  dated and lane-labelled so two lanes do not clobber each other, and stale
  directories there are free to delete — that is the difference.
- **A screenshot is not proof the change is good.** This is how the human sees a
  visual change without rebuilding; the measured claims still belong in the
  report and the changelog account.

### Briefing a lane

A lane is only as good as its brief. A good one carries: the constraints, the
**collisions it will hit** and who owns what, the APIs that moved under it since
it last ran, what you want in the report — and **which of the briefer's own
assumptions it should verify rather than trust**. That last one has repeatedly
returned the most valuable finding in a lane's report.

### Local-model delegation

Burn bulk-implementation tokens on a LOCAL model so the frontier-model quota goes
to judgment. Limits are real: an agent that hits one dies mid-task.

Verified working: `pi --provider ollama --model <local-model> --no-session -p "…"`
(pi 0.84.3, headless print mode; `--mode json` for structured output,
`--session`/`-c` to iterate with context, e.g. feeding compile errors back).

**The tier**: human → coordinator → supervising agents (one per lane) → local
model (implementation batches).

**Supervisor protocol**, for an agent on delegable work:

1. Write the spec and the ACCEPTANCE TESTS first — the tests are the contract, so
   author them yourself and never delegate the tests that gate the delegate.
2. Delegate one tight batch: a narrow prompt naming exact files, conventions
   (point it at a model file to imitate), and the fence.
3. Verify: run the gates and review the whole diff. The local model **never
   commits**; the supervisor commits after review, pruning slop.
4. Iterate with the error output, at most ~2 rounds, then take over yourself —
   review cost must stay below writing cost.

**Delegate**: template-following module batches, test boilerplate, mechanical API
sweeps (e.g. a 45-file signature migration), doc plumbing.
**Never delegate**: architecture, compiler or unsafe internals, conflict
resolution, contract and design decisions, anything spec-ambiguous.

Policy, because a loosely specified task (a test port, say) comes back slow,
misusing private APIs with the wrong semantics, and gets rewritten:

- Delegate ONLY well-specified mechanical work — rote sweeps with an exemplar
  ("here is one converted module, convert these N the same way"), test
  boilerplate from a template, doc-table regeneration, rename chores.
- Every delegated task ships with exact files, one worked example, the command to
  verify, and a hard instruction to change nothing else. Review the diff like a
  hostile PR; rewriting more than 30% means the task was miscategorised — do it
  directly next time and note it.
- Laptop heat and GPU contention are real: if the human needs the machine they say
  so and the local model pauses. Prefer batching runs over keeping the server
  warm.

The switch goes both ways: pause it for laptop heat, and **re-enable it under
quota pressure** when frontier quota is near its limit, because local latency
beats no quota. Which way it is set *now* is live
state and belongs on the board, not here.

### Constraint hygiene

When work is throttled by a constraint — quota, a blocking lane, a paused
dependency — record WHICH constraint and re-check it when the situation changes.
A throttle set for reason X must be lifted the moment X stops applying; the
failure mode is a conservative policy outliving its cause and quietly serialising
work nobody chose to serialise. For example: a model-quota freeze stops lanes on
that model, but lanes on a different model are never subject to it, so after a
switch of model lift the freeze yourself rather than wait for the human to ask
why everything is sequential. Default posture
remains parallelise-and-merge-later.

---

## 5. How we state claims — #SimplyAILogic ([simply-chris](https://simplychris.ai))

Docs, reports and briefs reason **modally and constructively**, not classically.
Four operational habits:

1. **No excluded middle.** Don't force a binary. "Not yet constructed" is a real
   third state — a design isn't right-or-wrong before it exists, and a claim
   isn't true-or-false before someone builds the evidence.
2. **Distinguish kinds of impossibility, because the distinction is actionable.**
   ⚫️ = impossible in every world. 🚫 = impossible *in this context*, open
   elsewhere. ◇ = possible. □ = necessary. **Most "we can't do that" is 🚫**, and
   naming it points at the context that would have to change — usually a single
   mechanism is the only thing making it impossible, and saying which one is the
   lever. Writing ⚫️ where 🚫 is meant hides that lever.
3. **Belief carries evidence and stays revisable.** `(p ∧ e) → Bp`: assert with
   what produced the assertion. There is **no T axiom for belief** — we hold
   false beliefs, and correct some the day they are written. On
   contradiction, revise (`Bp ∧ B¬p → BR`) rather than pick a side or stall. Keep
   the correction visible; it is usually more useful than the claim.
4. **Fixed past, open future** (`□Past`, `◇Future`). Shipped work is stated
   flatly; roadmap and queue entries are **possibilities, not commitments**, and
   should read that way.

---

## 6. The big question (periodic review ritual)

When the human asks "the big question" — or at any natural lull — run the
pipeline review across the doc web, in this order:

1. **What other ideas could we be looking into?** — generate and file new rows in
   the ideas inbox (generalisations, gaps, adjacent envelope-pushes).
2. **What ideas can we start to put into the roadmap and spec out?** — promote
   mature rows: design rounds for the big ones, roadmap entries for the committed.
3. **What roadmap things can we pull onto the board?** — turn roadmap scope into
   launch-ready queue entries, lanes permitting.
4. **What board items can we conclude and mark done in the roadmap?** — close
   finished lanes in both places; prune the queue of superseded entries.
5. **What decisions can we be discussing?** — surface open calls (pending
   reviews, design forks, go/no-go gates) with a recommendation each.

Answer all five explicitly, docs updated as you go (docs before eng).

---

## 7. Recovery (crashed session / fresh context)

1. Read the project's `AGENTS.md`, this file, and the board.
2. `jj log` — every lane's chain is committed incrementally; compare with the
   board's running rows and `STATUS.md`. `jj workspace list` plus a per-workspace `jj status`
   finds uncommitted lane work.
3. Finished unmerged chains → hand to a `integrator`. Dead agents → relaunch with
   the fence from the board row; the chain survives.
4. **Salvage dead agents' transcripts.** A killed subagent's full transcript
   survives at
   `~/.claude/projects/<project>/<session>/subagents/agent-<id>.jsonl` even when
   the harness says it "won't be resumed". Give the relaunched agent its
   predecessor's transcript path — the tail holds the exact plan and next step it
   was executing, which is finer-grained than the committed workspace state.
5. Private memory duplicates the key conventions and points back here.
