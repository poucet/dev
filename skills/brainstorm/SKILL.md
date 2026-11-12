---
name: brainstorm
description: How the co-developer works an open-ended decision through with the human developer — asking the questions that separate the alternatives, never presenting the alternatives; diverging first, converging by pruning, reopening when an answer reveals a missed path. Done by the co-developer only, never a subagent.
---

This is the **co-developer's own method** — simplychris: *"brainstorm
MUST be done by you, the top agent, never any of the subagents."* It is a
skill, not a role: nothing is dispatched. The one who holds the conversation
is the one who asks, because the questions come from everything in context —
the artefact, the tree, the human's past rulings — and a subagent has none of it.
The human developer iterates on this file; *Open in this file* is where they
change it.

## The method, in one paragraph

**Read the artefact. Generate alternatives privately. Do not present them.
Find the questions whose answers would separate them, and ask those.** Each
answer prunes the set — *or widens it*: an answer that reveals an axis the
alternatives never covered sends the process back to diverging, and an earlier
answer can be revised when a later concept makes it look wrong. Stop when the
candidates that remain are no longer drastically different approaches — when
what separates them is detail, and continuing to diverge would be inventing
differences rather than finding them. Then present the survivor in enough detail that what is left is minor
iteration.

**The human answers the open-ended question. Always.** simplychris:
*"it's important the human answers the open-ended question — it leads to
direct brainstorming between human and AI without group-think."* The agent's
job is to *find* the axis; the human's job is to *answer* it. An agent that
answers its own questions, or leans on them, is one mind talking to itself and
calling it a conversation. The value of the method is that two different
priors meet at a question neither would have asked alone.

The alternatives are hypotheses; the questions are the experiments that
partition them. A menu — *"here are four options, pick one"* — is the failure
mode this exists to avoid: it hands the whole search to the human and asks nothing
of the agent's own thinking.

## Three phases, not one

simplychris: *"sometimes it's important to diverge further at first; the
first few alternatives might not have covered everything, and suggestions from
users to questions might lead down a different path. And sometimes the user
might say yes but then a better refinement comes along, so decisions might get
refined as new concepts are explored."*

So this is not a funnel. It is:

1. **Diverge.** Generate more alternatives than seem necessary — six to eight,
   not three. Include at least one that reshapes the question rather than
   answering it. Ask at least one *widening* question early: *"what is not in
   this artefact at all that should be?"* An answer that adds an axis is the
   best possible first-round outcome.
2. **Converge.** Ask the questions that split the set. Prune. Re-rank. Say how
   many fell.
3. **Reopen — whenever, not only at the start.** If an answer, or a refinement
   the human offers mid-way, reveals a dimension the sealed set did not contain,
   **that is not a prune with a footnote; it is a re-divergence.** Generate a
   new candidate set around the new dimension — not "add one alternative" but
   "what does the whole set look like now that this axis exists" — then
   re-extract the questions from the new set, and **say which earlier answers
   the new set puts back in play.** A decision made in round two is not final
   in round four if round four found something better. The ledger records the
   original answer, the dimension that reopened it, and the revision, so the
   path is visible.

   simplychris: *"it's not JUST pruning — surprising new dimensions to
   questions need re-divergence through new candidate sets and new question
   extraction."*

Convergence is the *usual* direction, not a rule. The rule is that the
alternative set is always honest about what is known so far.

## The steps

1. **Read the artefact whole.** Note what is stale, contradictory, or moved
   under it since it was written.
2. **Seal the alternatives in chat or in a doc** — never in a private
   scratchpad the human cannot reach. *Sealed* means "not yet read", not
   "cannot be read": a `docs/live/brainstorm-<topic>.md` with a section
   marked *sealed until convergence*, or a marked block in the conversation.
   The human is trusted not to look; the record exists so the brainstorm
   can resume after a lost context and so the alternatives demonstrably came
   before the answers. One line each, two lines of argument. Include one that
   reframes.
3. **Derive the axes.** For every pair of alternatives, the question that
   separates them; merge shared axes; rank by how many alternatives each
   splits. Add one widening question. Hold the ranked list in context;
   checkpoint it to the sealed file when a section closes.
4. **Work down the ranked list, one to three at a time, by the size of the
   question.** A big axis gets a round to itself; small ones travel together.
   The list is the thing; the batch is pacing. Every question on the list will be asked
   unless an answer removes it or a reopen replaces the list. After each
   round, re-rank what is left — an answer can promote a question that was
   low — and take the next two or three off the top. Plain language, no
   vocabulary the artefact invented, no hint of which alternative each answer
   serves. State the axis, not the options: *"who is the next release for?"*
   not *"Instrument or Platform?"*
5. **On each answer: prune, widen, or reopen.** Say what happened by count —
   *"that removes two of six"*, *"that adds an axis; the set is eight now"*,
   *"that puts round-two's answer back in play."*
6. **Converge.** Convergence is a judgement, not a count: it is
   reached when the remaining candidates are the same *approach* and differ
   only in details that implementation would settle. More than one can
   survive. simplychris: *"ends when solutions seem fairly similar to
   the point that they are not drastically different approaches, and then
   it's more about nailing down the details rather than continuing
   divergence."* Present what survived as one approach with its open details.
   No audit ceremony — simplychris: *"you don't need a full audit."*
   The sealed set is the agent's discipline, not evidence for a hearing.
7. **Conclude with a high-level design summary.** Not a design doc. simplychris:
   *"the end goal of a brainstorm is a high-level design summary
   — more like a technical requirements doc or a product doc, whatever fits.
   High-level, not in the details, with the decisions and overall
   direction."* The decisions, the direction, what was ruled out and why in a
   line each. The details are the next lane's, or the next brainstorm's.

## Rules

- **Never present an alternative before convergence.** If asked, say they are
  sealed and why, and offer the next question. If the human insists, unseal — their
  call — and say the brainstorm is over.
- **Never ask a binary question.** *"Chat or doc?"* is a menu of two — the
  failure mode with a smaller menu. Ask the axis: *"where should a round
  happen, and what does it need from that place?"* simplychris: *"avoid
  binary questions at all costs."* A yes/no answer cannot add a dimension;
  an open answer can, and that is the outcome the method is for.
- **Never ask a question the tree or a past ruling already answers.**
- **Never pad, never skip.** One question that splits the set well beats five
  that split it badly — but the ranked list is walked to its end, not
  abandoned after the top three. simplychris: *"work your way down the
  top questions, two or three at a time."*
- **Never treat a "yes" as closed.** Record it; keep asking; if something
  better arrives, say so and ask whether the earlier answer stands.
- **Keep the ledger in the context window; checkpoint it to the doc, not
  every round.** Questions, answers, revisions, alternatives added and
  removed — held in the conversation as it runs, and written to the sealed
  doc when a big decision lands or a section of questions closes. simplychris:
  *"it might be inefficient to keep an alternative trace — it's a
  lot of churn on the model for tool-calling. Ideally in context window and
  periodically saved, like if some big decisions are made or a section of
  them."* The doc is for a resume after a lost
  context; it is not a transcript, and it is not an audit trail.
- **Write for the human developer.** Mechanism first, vocabulary defined, no `§`.

## Open in this file — what the method has not decided about itself

Answered so far by simplychris:
- **Not a pure funnel** — diverge first, reopen when an answer reveals a
  missed path, decisions revisable. *(Written into "Three phases" above.)*
- **Name** — brainstormer, not tunneler. Tunneling is the converging phase,
  not the whole thing.
- **One to three per round by the size of the question, down a ranked list
  walked to its end.**
  Re-ranked after every answer. *(Step 4 and the pad/skip rule.)*
- **The sealed set lives in chat or in a doc** — somewhere the human could
  read but does not. Not a private scratchpad. *(Step 2.)*
- **It ends when the survivors are one approach**, differing only in details
  — a judgement, not a survivor count. *(Step 6.)*
- **Rounds run in the context window; the doc is checkpointed at big
  decisions or when a section closes**, not per round. *(Ledger rule.)*
- **No binary questions.** A yes/no cannot add a dimension. *(Rules.)*
- **The questioner never states its lean.** The human answers the open
  question; a stated lean is group-think by another route. *(Written into the
  paragraph above.)*

- **Done by the co-developer, never a subagent.** The asker is the one with
  the whole context. *(Top of this file.)*
- **It ends in a high-level design summary** — decisions and direction, not
  details. *(Step 7.)*

Nothing is open in this file. The human developer iterates here.
