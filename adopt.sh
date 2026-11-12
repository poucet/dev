#!/usr/bin/env bash
#
# adopt.sh — put a repo on the simply/dev working system.
#
# The system itself (AGENTS.md, the roles, the skills) is a pi package,
# installed once per machine (`pi install <this repo>`); nothing of it is
# linked into a repo. What a repo gets is its own small part, all idempotent
# (safe to re-run; nothing existing is overwritten):
#
#   1. AGENTS.project.md for the repo's own rules, untracked by an anchored
#      root .gitignore line (it can name private things: the tracker, its URLs)
#   2. CHANGELOG.md (tracked), unless the repo keeps a changelog already, and
#      ROADMAP.md (tracked) in file mode
#   3. the self-ignoring local directories: .pi/ (reports, drafts, changelog
#      fragments, sessions, the agent tree), .workspaces/, .trash/
#   4. in Linear mode, the '## Tracker' section in AGENTS.project.md
#
# With --theirs (a repo you don't own, AGENTS.md §2) it touches nothing a
# teammate could see: no .gitignore line, no tracked file; the project rules go
# in .pi/AGENTS.project.md and lanes in .pi/workspaces/.
#
# Usage:
#   ./adopt.sh <project-dir> [--tracker files|linear] [--theirs]
#
#   --tracker  where the plan lives (default: files; linear also when
#              AGENTS.project.md already has '## Tracker')
#   --theirs   a shared repo you don't own: everything stays inside .pi/
#
set -euo pipefail

DEV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() { sed -n '2,27p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

PROJECT=""
TRACKER=""
THEIRS=""

while [ $# -gt 0 ]; do
	case "$1" in
		-h|--help) usage 0 ;;
		--tracker) TRACKER="${2:?}"; shift 2 ;;
		--theirs) THEIRS=1; shift ;;
		-*) echo "unknown option: $1" >&2; usage 1 >&2 ;;
		*) if [ -n "$PROJECT" ]; then echo "unexpected argument: $1" >&2; usage 1 >&2; fi
		   PROJECT="$1"; shift ;;
	esac
done

[ -n "$PROJECT" ] || usage 1 >&2
[ -d "$PROJECT" ] || { echo "not a directory: $PROJECT" >&2; exit 1; }
PROJECT="$(cd "$PROJECT" && pwd)"

if [ -n "$THEIRS" ]; then RULES=".pi/AGENTS.project.md"; else RULES="AGENTS.project.md"; fi

# Resolve the tracker: explicit flag wins; a project whose rules already
# declare '## Tracker' stays in Linear mode on a re-run.
if [ -z "$TRACKER" ]; then
	if grep -qs '^## Tracker' "$PROJECT/$RULES"; then TRACKER="linear"; else TRACKER="files"; fi
fi
case "$TRACKER" in
	files|linear) ;;
	*) echo "--tracker must be files or linear (got: $TRACKER)" >&2; exit 1 ;;
esac

# --- helpers -----------------------------------------------------------------

ensure_untracked_dir() { mkdir -p -- "$1"; [ -e "$1/.gitignore" ] || echo '*' > "$1/.gitignore"; }

# Copy templates/<rel> to <dest> in the project, unless <dest> exists.
from_template() { # <rel> <dest>
	[ -e "$PROJECT/$2" ] && return 0
	mkdir -p -- "$(dirname "$PROJECT/$2")"
	cp -- "$DEV_DIR/templates/$1" "$PROJECT/$2"
	CREATED+=("$2")
}

# The project-relative path of an entry named $1 (any case) at the root, or nothing.
find_ci() {
	local hit
	hit="$(find "$PROJECT" -mindepth 1 -maxdepth 1 -iname "$1" 2>/dev/null | sort | head -n1)"
	[ -n "$hit" ] && printf '%s\n' "${hit#"$PROJECT"/}"
	return 0
}

CREATED=()
TO_COMMIT=()

# --- 1. local directories ------------------------------------------------------

ensure_untracked_dir "$PROJECT/.pi"
mkdir -p "$PROJECT/.pi/reports" "$PROJECT/.pi/drafts" "$PROJECT/.pi/changelog.d"
if [ -z "$THEIRS" ]; then
	ensure_untracked_dir "$PROJECT/.workspaces"
	ensure_untracked_dir "$PROJECT/.trash"
else
	mkdir -p "$PROJECT/.pi/workspaces" "$PROJECT/.pi/trash"
fi

# --- 2. the project's rules ----------------------------------------------------

from_template AGENTS.project.md "$RULES"
if [ "$TRACKER" = "linear" ] && ! grep -qs '^## Tracker' "$PROJECT/$RULES"; then
	{ echo; sed "s/<repo>/$(basename "$PROJECT")/g" "$DEV_DIR/skills/linear/tracker.md"; } >> "$PROJECT/$RULES"
fi

# Untracked: a single file can't ignore itself, so it takes an anchored root
# .gitignore line; one already tracked is untracked (the file stays). A
# colocated repo is jj's, never git's (AGENTS.md §4).
if [ -z "$THEIRS" ]; then
	if ! grep -qsxE '/?AGENTS\.project\.md' "$PROJECT/.gitignore"; then
		if [ -s "$PROJECT/.gitignore" ] && [ -n "$(tail -c1 "$PROJECT/.gitignore")" ]; then
			echo >> "$PROJECT/.gitignore"
		fi
		echo "/AGENTS.project.md" >> "$PROJECT/.gitignore"
		TO_COMMIT+=(".gitignore")
	fi
	if [ -d "$PROJECT/.jj" ]; then
		if [ -n "$(cd "$PROJECT" && jj file list -- AGENTS.project.md </dev/null 2>/dev/null)" ]; then
			(cd "$PROJECT" && jj file untrack -- AGENTS.project.md </dev/null)
			TO_COMMIT+=("AGENTS.project.md")
		fi
	elif [ -d "$PROJECT/.git" ]; then
		if git -C "$PROJECT" ls-files --error-unmatch -- AGENTS.project.md >/dev/null 2>&1; then
			git -C "$PROJECT" rm --cached -q -- AGENTS.project.md
			TO_COMMIT+=("AGENTS.project.md")
		fi
	fi
fi

# --- 3. tracked starters -------------------------------------------------------

FOUND_CHANGELOG="$(find_ci CHANGELOG.md)"
if [ -z "$THEIRS" ]; then
	[ -n "$FOUND_CHANGELOG" ] || from_template CHANGELOG.md CHANGELOG.md
	[ "$TRACKER" = "linear" ] || from_template ROADMAP.md ROADMAP.md
fi

# --- 4. what the old system left behind ----------------------------------------

LEFTOVERS=()
for rel in AGENTS.md .pi/agents .pi/skills .claude/agents changelog.d docs/ops; do
	[ -e "$PROJECT/$rel" ] || [ -L "$PROJECT/$rel" ] || continue
	LEFTOVERS+=("$rel")
done

# --- report -------------------------------------------------------------------

echo "Adopted simply/dev into $PROJECT ($TRACKER mode${THEIRS:+, shared repo})."
for rel in ${CREATED[@]+"${CREATED[@]}"}; do echo "  created $rel"; done
[ -n "$FOUND_CHANGELOG" ] && echo "  kept the existing changelog: $FOUND_CHANGELOG"
echo "  .pi/ (untracked: reports/, drafts/, changelog.d/, sessions, the agent tree)"
if [ -z "$THEIRS" ]; then echo "  .workspaces/, .trash/ (untracked)"; else echo "  .pi/workspaces/, .pi/trash/"; fi
if [ ${#LEFTOVERS[@]} -gt 0 ]; then
	echo
	echo "Left from the old setup, now unused (the package replaces them):"
	for rel in "${LEFTOVERS[@]}"; do echo "  $rel"; done
	echo "  Move them to .trash/ once their content is elsewhere: docs/ops/ holds"
	echo "  decisions and rules worth folding into AGENTS.project.md or a design"
	echo "  doc, changelog.d/ fragments move to .pi/changelog.d/."
fi
if [ ${#TO_COMMIT[@]} -gt 0 ]; then
	msg="Keep AGENTS.project.md out of version control: it holds this machine's project rules"
	echo
	echo "To commit, by path (nothing was committed): ${TO_COMMIT[*]}"
	if [ -d "$PROJECT/.jj" ]; then
		echo "  jj commit ${TO_COMMIT[*]} -m \"$msg\""
	else
		echo "  git add ${TO_COMMIT[*]} && git commit -m \"$msg\""
	fi
fi
if ! grep -qs "simply" "${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}/settings.json"; then
	echo
	echo "The package isn't installed for pi yet:  pi install $DEV_DIR"
fi
