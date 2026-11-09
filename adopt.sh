#!/usr/bin/env bash
#
# adopt.sh — install the simply/dev workflow into a project.
#
# Does four things, all idempotent (safe to re-run; nothing existing is
# overwritten):
#
#   1. links AGENTS.md         -> dev's AGENTS.md, by a relative symlink
#      (../dev/AGENTS.md when the repo sits beside dev), untracked (step 4),
#      and starts an AGENTS.project.md for the repo's own rules, untracked
#   2. symlinks the role definitions into the directory the coding harness
#      in use reads them from:
#        pi.dev       .pi/agents       (personas; needs projectPersonas: true
#                                       in ~/.pi/agent/subagents.json and a
#                                       trusted project)
#        Claude Code  .claude/agents   (subagents)
#   3. lays out the doc web per AGENTS.md §3:
#        CHANGELOG.md and ROADMAP.md at the root, tracked
#        changelog.d/  lanes' changelog fragments (untracked)
#        docs/ops/   the one untracked directory of working state:
#                    BOARD DECIDE ASKS  ISSUES FIXED DECISIONS IDEAS
#                    reports/ (lanes' final reports)
#                    (drafts/ appears when there is a draft)
#        (docs/{design,research,guides,reference}/ are not made: a folder
#        appears when there is something to put in it)
#        .workspaces/  .trash/   (untracked)
#      The starter files are copied from dev's templates/, each only where
#      the project has no file of that name yet. Files of an older layout
#      (docs/ops/STATUS.md, docs/ops/ROADMAP.md) are left where they are;
#      a root ROADMAP.md is not added while docs/ops/ROADMAP.md exists.
#      A real AGENTS.md (an old copy) is left alone and reported: its rules
#      move into AGENTS.project.md by hand (skills/adopt), then re-run with
#      --replace-agents-md, which moves it to .trash/ and makes the link.
#      With --tracker linear the repo keeps its plan in Linear (AGENTS.md
#      §2, *Linear mode*): ROADMAP.md and docs/ops/'s BOARD MILESTONES
#      ISSUES FIXED IDEAS DECIDE DECISIONS are not copied (a warning names any that already exist: they
#      move at cutover, per skills/linear), and AGENTS.project.md gains a
#      '## Tracker' section from skills/linear/tracker.md, once.
#   4. ignores what must never be committed: each untracked directory above
#      (and .claude/ or .pi/) gets its own .gitignore holding '*'. The symlink
#      targets are machine-specific absolute paths, so they must never be
#      committed either.
#      AGENTS.md, AGENTS.project.md and the agent links are untracked in
#      every repo, in both modes: they are local setup (the AGENTS.md link
#      dangles in a lane's workspace and in a public clone). A single file
#      can't ignore itself, so the root .gitignore gains an anchored line for
#      each, once: '/AGENTS.md', '/AGENTS.project.md', '/.pi/agents' or
#      '/.claude/agents'. Any already tracked is untracked (jj file untrack;
#      git rm --cached in a git-only repo), staying on disk. Nothing is
#      committed: the report prints the by-path commit command.
#      A lane's workspace gets its own absolute links from `lane new`
#      (skills/lane).
#
# Usage:
#   ./adopt.sh <project-dir> [--harness pi|claude|both|auto]
#                            [--tracker files|linear]
#                            [--replace-agents-md]
#
#   --harness          which harness directory(s) to wire (default: auto —
#                      .claude if the project has one, else .pi)
#   --tracker          where the plan lives (default: files; linear also
#                      when AGENTS.project.md already has '## Tracker')
#   --replace-agents-md  a real AGENTS.md (an old copy of the system) goes to
#                      .trash/ and becomes the link; only once its project
#                      rules are in AGENTS.project.md
#
set -euo pipefail

DEV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "dev dir: $DEV_DIR"

usage() { sed -n '2,65p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

PROJECT=""
HARNESS="auto"
TRACKER=""
REPLACE_AGENTS_MD=""

while [ $# -gt 0 ]; do
	case "$1" in
		-h|--help) usage 0 ;;
		--harness) HARNESS="${2:?}"; shift 2 ;;
		--tracker) TRACKER="${2:?}"; shift 2 ;;
		--replace-agents-md) REPLACE_AGENTS_MD=1; shift ;;
		-*) echo "unknown option: $1" >&2; usage 1 >&2 ;;
		*) if [ -n "$PROJECT" ]; then echo "unexpected argument: $1" >&2; usage 1 >&2; fi
		   PROJECT="$1"; shift ;;
	esac
done

[ -n "$PROJECT" ] || usage 1 >&2
[ -d "$PROJECT" ] || { echo "not a directory: $PROJECT" >&2; exit 1; }
PROJECT="$(cd "$PROJECT" && pwd)"

# Resolve the harness: explicit flag wins; auto picks .claude if the project
# already has one, else .pi.
if [ "$HARNESS" = "auto" ]; then
	if [ -d "$PROJECT/.claude" ]; then HARNESS="claude"; else HARNESS="pi"; fi
fi
case "$HARNESS" in
	pi|claude|both) ;;
	*) echo "--harness must be pi, claude, both or auto (got: $HARNESS)" >&2; exit 1 ;;
esac

# Resolve the tracker: explicit flag wins; a project whose AGENTS.project.md
# already declares '## Tracker' stays in Linear mode on a re-run.
if [ -z "$TRACKER" ]; then
	if grep -qs '^## Tracker' "$PROJECT/AGENTS.project.md"; then TRACKER="linear"; else TRACKER="files"; fi
fi
case "$TRACKER" in
	files|linear) ;;
	*) echo "--tracker must be files or linear (got: $TRACKER)" >&2; exit 1 ;;
esac

# What lives in Linear instead of a file in Linear mode (AGENTS.md §2).
LINEAR_MOVED="ROADMAP.md docs/ops/BOARD.md docs/ops/MILESTONES.md docs/ops/ISSUES.md docs/ops/FIXED.md docs/ops/IDEAS.md docs/ops/DECIDE.md docs/ops/DECISIONS.md"
moved_to_linear() { [ "$TRACKER" = "linear" ] && case " $LINEAR_MOVED " in *" $1 "*) return 0 ;; esac; return 1; }

# --- helpers -----------------------------------------------------------------

# Create a directory (and parents) if absent.
ensure_dir() { mkdir -p -- "$1"; }


# Ensure dir contains a .gitignore with wild card to ignore that directory.
ensure_untracked_dir() { ensure_dir "$1"; [ -e "$1/.gitignore" ] || echo '*' > "$1/.gitignore"; }

# Copy every file under templates/ to the same path in the project, unless
# that path already exists. The templates are real files in dev, not heredocs.
copy_templates() {
	local rel
	while IFS= read -r rel; do
		rel="${rel#./}"
		[ -e "$PROJECT/$rel" ] && continue
		moved_to_linear "$rel" && continue
		if [ "$rel" = "ROADMAP.md" ] && [ -e "$PROJECT/docs/ops/ROADMAP.md" ]; then
			echo "  !! docs/ops/ROADMAP.md exists: move it to the repo root (tracked) by hand" >&2
			continue
		fi
		ensure_dir "$PROJECT/$(dirname "$rel")"
		cp -- "$DEV_DIR/templates/$rel" "$PROJECT/$rel"
	done < <(cd "$DEV_DIR/templates" && find . -type f ! -name .DS_Store | sort)
}

# Symlink, refreshing a stale link but never clobbering a real file/directory.
link_into() { # <target> <link-path>
	local target="$1" link="$2"
	if [ -e "$link" ] && [ ! -L "$link" ]; then
		echo "  !! exists and is not a symlink, left alone: $link" >&2
		return 0
	fi
	ln -sfn -- "$target" "$link"
}

# The path of $1 relative to directory $2.
relative_to() { perl -MFile::Spec -e 'print File::Spec->abs2rel($ARGV[0], $ARGV[1])' "$1" "$2"; }

# --- 1. AGENTS.md and AGENTS.project.md ---------------------------------------

AGENTS_LINK="$(relative_to "$DEV_DIR/AGENTS.md" "$PROJECT")"
# A real AGENTS.md is an old copy of the system, maybe with project rules in
# it. Replacing it changes what the repo's agents read, so it is the human's
# step: reported, and done only with --replace-agents-md.
AGENTS_COPY=""
if [ -e "$PROJECT/AGENTS.md" ] && [ ! -L "$PROJECT/AGENTS.md" ]; then
	if [ -n "$REPLACE_AGENTS_MD" ]; then
		trash="$PROJECT/.trash/AGENTS.md-$(date +%Y-%m-%d)"
		ensure_dir "$trash"
		mv -- "$PROJECT/AGENTS.md" "$trash/AGENTS.md"
		AGENTS_COPY="replaced"
	else
		AGENTS_COPY="kept"
	fi
fi
[ "$AGENTS_COPY" = "kept" ] || link_into "$AGENTS_LINK" "$PROJECT/AGENTS.md"

# --- 2. harness agents symlink ------------------------------------------------

AGENT_DIRS=()
[ "$HARNESS" = "pi" ] || [ "$HARNESS" = "both" ] && AGENT_DIRS+=(".pi/agents")
[ "$HARNESS" = "claude" ] || [ "$HARNESS" = "both" ] && AGENT_DIRS+=(".claude/agents")
for dir in "${AGENT_DIRS[@]}"; do
	ensure_dir "$PROJECT/$(dirname "$dir")"
	ensure_untracked_dir "$PROJECT/$(dirname "$dir")"
	link_into "$DEV_DIR/agents" "$PROJECT/$dir"
done

# --- 3. the doc web (AGENTS.md §3) --------------------------------------------

# docs/ops/ is the one untracked directory of working state (AGENTS.md §2);
# the workspaces and discarded files are untracked too. (.screenshots/ is not
# made: a project that renders images adds it, per AGENTS.md §3.)
ensure_untracked_dir "$PROJECT/docs/ops"
ensure_dir "$PROJECT/docs/ops/reports"   # lanes write their reports here
ensure_untracked_dir "$PROJECT/changelog.d"
ensure_untracked_dir "$PROJECT/.workspaces"
ensure_untracked_dir "$PROJECT/.trash"

# The starter files: AGENTS.project.md, CHANGELOG.md, ROADMAP.md, and
# docs/ops/'s BOARD DECIDE ASKS ISSUES FIXED DECISIONS IDEAS (Linear mode:
# ASKS only).
copy_templates

# Linear mode: the '## Tracker' switch, appended once, and a warning for each
# file that should have moved (they go at cutover, per skills/linear).
if [ "$TRACKER" = "linear" ]; then
	if ! grep -qs '^## Tracker' "$PROJECT/AGENTS.project.md"; then
		{ echo; sed "s/<repo>/$(basename "$PROJECT")/g" "$DEV_DIR/skills/linear/tracker.md"; } >> "$PROJECT/AGENTS.project.md"
	fi
	for rel in $LINEAR_MOVED; do
		[ -e "$PROJECT/$rel" ] && echo "  !! $rel exists: in Linear mode it moves to Linear at cutover (skills/linear)" >&2
	done
fi

# --- 4. the local files are untracked (AGENTS.md, *A project's own rules*) ---

# AGENTS.project.md can name private infrastructure (the tracker, its URLs);
# the AGENTS.md link dangles in a lane's workspace and in a public clone, and
# the agent links point into this machine. A single file can't ignore itself,
# so each takes an anchored root .gitignore line.
LOCAL_PATHS=("AGENTS.md" "AGENTS.project.md" "${AGENT_DIRS[@]}")
TO_COMMIT=()
for rel in "${LOCAL_PATHS[@]}"; do
	re="$(printf '%s' "$rel" | sed 's/[.]/\\./g')"
	grep -qsxE "/?$re/?" "$PROJECT/.gitignore" && continue
	if [ -s "$PROJECT/.gitignore" ] && [ -n "$(tail -c1 "$PROJECT/.gitignore")" ]; then
		echo >> "$PROJECT/.gitignore"
	fi
	echo "/$rel" >> "$PROJECT/.gitignore"
	case " ${TO_COMMIT[*]-} " in *" .gitignore "*) ;; *) TO_COMMIT+=(".gitignore") ;; esac
done

# Already tracked: untrack each, after its ignore line exists. The files stay.
# A real AGENTS.md left in place (an old copy) stays tracked until it is
# replaced. A colocated repo is jj's, never git's (AGENTS.md §4).
# A .gitignore already changed by an earlier run is still to commit.
if [ -d "$PROJECT/.jj" ] && [ -n "$(cd "$PROJECT" && jj diff --name-only -- .gitignore </dev/null 2>/dev/null)" ]; then
	case " ${TO_COMMIT[*]-} " in *" .gitignore "*) ;; *) TO_COMMIT+=(".gitignore") ;; esac
fi
UNTRACKED=()
for rel in "${LOCAL_PATHS[@]}"; do
	[ "$rel" = "AGENTS.md" ] && [ "$AGENTS_COPY" = "kept" ] && continue
	if [ -d "$PROJECT/.jj" ]; then
		[ -n "$(cd "$PROJECT" && jj file list -- "$rel" </dev/null 2>/dev/null)" ] || continue
		(cd "$PROJECT" && jj file untrack -- "$rel" </dev/null)
	elif [ -d "$PROJECT/.git" ]; then
		git -C "$PROJECT" ls-files --error-unmatch -- "$rel" >/dev/null 2>&1 || continue
		git -C "$PROJECT" rm --cached -q -- "$rel"
	else
		continue
	fi
	UNTRACKED+=("$rel")
	TO_COMMIT+=("$rel")
done

# --- report -------------------------------------------------------------------

echo "Adopted simply/dev into $PROJECT (harness: $HARNESS)."
case "$AGENTS_COPY" in
	kept) echo "  !! AGENTS.md is a real file (an old copy of the system), left tracked and in place:"
	      echo "     move its project rules into AGENTS.project.md, then re-run with --replace-agents-md" ;;
	replaced) echo "  AGENTS.md (an old copy) moved to .trash/AGENTS.md-$(date +%Y-%m-%d)/" ;;
esac
[ "$AGENTS_COPY" = "kept" ] || echo "  AGENTS.md -> $AGENTS_LINK (untracked)"
echo "  AGENTS.project.md (untracked)"
for dir in "${AGENT_DIRS[@]}"; do
	echo "  $dir -> $DEV_DIR/agents (untracked)"
done
if [ "$TRACKER" = "linear" ]; then
	echo "  CHANGELOG.md (tracked); plan in Linear: ## Tracker in AGENTS.project.md"
else
	echo "  CHANGELOG.md, ROADMAP.md (tracked)"
fi
echo "  changelog.d/, docs/ops/ (untracked)"
echo "  .workspaces/, .trash/"
if [ ${#TO_COMMIT[@]} -gt 0 ]; then
	echo
	echo "To commit, by path (nothing was committed): ${TO_COMMIT[*]}"
	msg="Keep AGENTS.md, AGENTS.project.md and the agent links out of version control: they are local setup"
	if [ ${#UNTRACKED[@]} -gt 0 ]; then
		echo "  Were tracked, now untracked and still on disk: ${UNTRACKED[*]}."
		echo "  The commit records them removed from the repo; their old contents stay"
		echo "  in history, which only the human can rewrite."
	fi
	if [ -d "$PROJECT/.jj" ]; then
		echo "  jj commit ${TO_COMMIT[*]} -m \"$msg\""
	else
		echo "  git add .gitignore && git commit -m \"$msg\""
	fi
fi
if [ "$HARNESS" = "pi" ] || [ "$HARNESS" = "both" ]; then
	echo
	echo "Reminders for pi:"
	echo "  - set \"projectPersonas\": true in ~/.pi/agent/subagents.json"
	echo "  - trust the project when pi prompts on next launch"
fi
echo
