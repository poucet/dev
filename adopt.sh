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
#   2. Creates a .pi directory with
#      - .gitignore = *
#      - .pi/agents -> dev/agents
#      - .pi/skills -> dev/skills
#   3. Sets up the tracker + docweb
#   4. Sets up the relevant .gitignore for the docweb and AGENTS.md
#
# Usage:
#   ./adopt.sh <project-dir> [--tracker files|linear] [--replace-agents-md]
#
#   --tracker          where the plan lives (default: files; linear also
#                      when AGENTS.project.md already has '## Tracker')
#   --replace-agents-md  a real AGENTS.md (an old copy of the system) goes to
#                      .trash/ and becomes the link; only once its project
#                      rules are in AGENTS.project.md
#
set -euo pipefail

DEV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "dev dir: $DEV_DIR"

usage() { sed -n '2,69p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

PROJECT=""
TRACKER=""
REPLACE_AGENTS_MD=""

while [ $# -gt 0 ]; do
	case "$1" in
		-h|--help) usage 0 ;;
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
		[ "$rel" = "CHANGELOG.md" ] && [ -n "$FOUND_CHANGELOG" ] && continue
		moved_to_linear "$rel" && continue
		if [ "$rel" = "ROADMAP.md" ] && [ -e "$PROJECT/docs/ops/ROADMAP.md" ]; then
			echo "  !! docs/ops/ROADMAP.md exists: move it to the repo root (tracked) by hand" >&2
			continue
		fi
		ensure_dir "$PROJECT/$(dirname "$rel")"
		cp -- "$DEV_DIR/templates/$rel" "$PROJECT/$rel"
	done < <(cd "$DEV_DIR/templates" && find . -type f ! -name .DS_Store | sort)
}

# The project-relative path of an entry named $2 (any case) directly in
# directory $1 ("" for the root), or nothing.
find_ci() { # <dir> <name>
	local base="$PROJECT${1:+/$1}" hit
	[ -d "$base" ] || return 0
	hit="$(find "$base" -mindepth 1 -maxdepth 1 -iname "$2" 2>/dev/null | sort | head -n1)"
	[ -n "$hit" ] && printf '%s\n' "${hit#"$PROJECT"/}"
	return 0
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

# --- 2. agents + skills symlink ------------------------------------------------

ensure_untracked_dir "$PROJECT/.pi"
link_into "$DEV_DIR/agents" "$PROJECT/.pi/agents"
link_into "$DEV_DIR/skills" "$PROJECT/.pi/skills"

# --- 3. the doc web (AGENTS.md §3) --------------------------------------------

# docs/ops/ is the one untracked directory of working state (AGENTS.md §2);
# the workspaces and discarded files are untracked too. (.screenshots/ is not
# made: a project that renders images adds it, per AGENTS.md §3.)
# A changelog the repo already keeps, wherever it keeps it, is left as it is:
# no template beside it, and no root changelog.d/ when the fragments (or the
# changelog itself) live in docs/ops/.
FOUND_CHANGELOG="$(find_ci "" CHANGELOG.md)"
[ -n "$FOUND_CHANGELOG" ] || FOUND_CHANGELOG="$(find_ci docs/ops CHANGELOG.md)"
FOUND_FRAGMENTS="$(find_ci "" changelog.d)"
[ -n "$FOUND_FRAGMENTS" ] || FOUND_FRAGMENTS="$(find_ci docs/ops changelog.d)"

ensure_untracked_dir "$PROJECT/docs/ops"
ensure_dir "$PROJECT/docs/ops/reports"   # lanes write their reports here
case "$FOUND_FRAGMENTS" in
	docs/ops/*) ;;                                     # untracked with docs/ops/
	"") case "$FOUND_CHANGELOG" in
		docs/ops/*) ;;                                 # changelog kept in docs/ops/
		*) ensure_untracked_dir "$PROJECT/changelog.d" ;;
	    esac ;;
	*) ensure_untracked_dir "$PROJECT/$FOUND_FRAGMENTS" ;;
esac
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
LOCAL_PATHS=("AGENTS.md" "AGENTS.project.md")
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

echo "Adopted simply/dev into $PROJECT."
case "$AGENTS_COPY" in
	kept) echo "  !! AGENTS.md is a real file (an old copy of the system), left tracked and in place:"
	      echo "     move its project rules into AGENTS.project.md, then re-run with --replace-agents-md" ;;
	replaced) echo "  AGENTS.md (an old copy) moved to .trash/AGENTS.md-$(date +%Y-%m-%d)/" ;;
esac
[ "$AGENTS_COPY" = "kept" ] || echo "  AGENTS.md -> $AGENTS_LINK (untracked)"
echo "  AGENTS.project.md (untracked)"
echo "  $PROJECT/.pi/agents -> $DEV_DIR/agents (untracked)"
echo "  $PROJECT/.pi/skills -> $DEV_DIR/skills (untracked)"
if [ -n "$FOUND_CHANGELOG" ]; then
	echo "  found an existing changelog, no template added: $FOUND_CHANGELOG"
	CL=""
else
	CL="CHANGELOG.md"
fi
if [ "$TRACKER" = "linear" ]; then
	echo "  ${CL:+$CL (tracked); }plan in Linear: ## Tracker in AGENTS.project.md"
else
	echo "  ${CL:+$CL, }ROADMAP.md (tracked)"
fi
if [ -n "$FOUND_FRAGMENTS" ]; then
	echo "  found existing changelog fragments: $FOUND_FRAGMENTS/"
	echo "  docs/ops/ (untracked)"
elif [ -d "$PROJECT/changelog.d" ]; then
	echo "  changelog.d/, docs/ops/ (untracked)"
else
	echo "  docs/ops/ (untracked); no changelog.d/: the changelog lives in docs/ops/"
fi
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
echo
echo "Reminders for pi:"
echo "  - set \"projectPersonas\": true in ~/.pi/agent/subagents.json"
echo "  - trust the project when pi prompts on next launch"
echo
