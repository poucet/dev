#!/usr/bin/env bash
#
# adopt.sh — put a repo on the simply/dev working system.
#
# The system itself (its rules, the roles, the skills) is a pi package,
# installed once per machine (`pi install <this repo>`); nothing of it is
# linked into a repo. What a repo gets is its own small part, all idempotent
# (safe to re-run; nothing existing is overwritten):
#
#   1. AGENTS.md for the repo's own rules (tracked, unless the root .gitignore
#      ignores /AGENTS.md), and .pi/AGENTS.md for the private ones: the
#      tracker, standing instructions (untracked, like all of .pi/)
#   2. CHANGELOG.md (tracked), unless the repo keeps a changelog already, and
#      ROADMAP.md (tracked) in file mode
#   3. the self-ignoring local directories: .pi/ (reports, drafts, changelog
#      fragments, sessions, the agent tree), .workspaces/, .trash/
#   4. in Linear mode, the '## Tracker' section in .pi/AGENTS.md
#
# An old AGENTS.project.md becomes the root AGENTS.md when that is ignored,
# else .pi/AGENTS.md; an old AGENTS.md symlink to dev's is removed first.
#
# With --theirs (a repo you don't own, AGENTS.md §2) it touches nothing a
# teammate could see: no root AGENTS.md, no tracked file; lanes go in
# .pi/workspaces/.
#
# Usage:
#   ./adopt.sh <project-dir> [--tracker files|linear] [--theirs]
#
#   --tracker  where the plan lives (default: files; linear also when
#              .pi/AGENTS.md or AGENTS.md already has '## Tracker')
#   --theirs   a shared repo you don't own: everything stays inside .pi/
#
set -euo pipefail

DEV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() { sed -n '2,32p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

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

LOCAL=".pi/AGENTS.md"

# Resolve the tracker: explicit flag wins; a project whose rules already
# declare '## Tracker' stays in Linear mode on a re-run.
if [ -z "$TRACKER" ]; then
	if grep -qs '^## Tracker' "$PROJECT/$LOCAL" "$PROJECT/AGENTS.md" "$PROJECT/AGENTS.project.md"; then
		TRACKER="linear"; else TRACKER="files"; fi
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
MIGRATED=()

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

root_ignored() { grep -qsxE '/?AGENTS\.md' "$PROJECT/.gitignore"; }

# The old layout: AGENTS.md was a link to dev's, the rules in AGENTS.project.md.
if [ -L "$PROJECT/AGENTS.md" ]; then
	rm -- "$PROJECT/AGENTS.md"
	MIGRATED+=("removed the AGENTS.md link to dev's")
fi
if [ -f "$PROJECT/AGENTS.project.md" ]; then
	if [ -z "$THEIRS" ] && [ ! -e "$PROJECT/AGENTS.md" ] && root_ignored; then
		mv -- "$PROJECT/AGENTS.project.md" "$PROJECT/AGENTS.md"
		MIGRATED+=("AGENTS.project.md -> AGENTS.md (local: the root .gitignore ignores /AGENTS.md)")
	elif [ ! -e "$PROJECT/$LOCAL" ]; then
		mv -- "$PROJECT/AGENTS.project.md" "$PROJECT/$LOCAL"
		MIGRATED+=("AGENTS.project.md -> $LOCAL")
	else
		MIGRATED+=("!! AGENTS.project.md left: both AGENTS.md and $LOCAL exist; merge it by hand")
	fi
fi

[ -n "$THEIRS" ] || from_template AGENTS.md AGENTS.md
from_template local-AGENTS.md "$LOCAL"
if [ "$TRACKER" = "linear" ] && ! grep -qs '^## Tracker' "$PROJECT/$LOCAL" "$PROJECT/AGENTS.md"; then
	{ echo; sed "s/<repo>/$(basename "$PROJECT")/g" "$DEV_DIR/skills/linear/tracker.md"; } >> "$PROJECT/$LOCAL"
fi

# --- 3. tracked starters -------------------------------------------------------

FOUND_CHANGELOG="$(find_ci CHANGELOG.md)"
if [ -z "$THEIRS" ]; then
	[ -n "$FOUND_CHANGELOG" ] || from_template CHANGELOG.md CHANGELOG.md
	[ "$TRACKER" = "linear" ] || from_template ROADMAP.md ROADMAP.md
fi

# Of what was created, what git will see.
for rel in ${CREATED[@]+"${CREATED[@]}"}; do
	case "$rel" in
		.pi/*) ;;
		AGENTS.md) root_ignored || TO_COMMIT+=("$rel") ;;
		*) TO_COMMIT+=("$rel") ;;
	esac
done

# --- 4. what the old system left behind ----------------------------------------

LEFTOVERS=()
for rel in .pi/agents .pi/skills .claude/agents changelog.d docs/ops; do
	[ -e "$PROJECT/$rel" ] || [ -L "$PROJECT/$rel" ] || continue
	LEFTOVERS+=("$rel")
done

# --- report -------------------------------------------------------------------

echo "Adopted simply/dev into $PROJECT ($TRACKER mode${THEIRS:+, shared repo})."
for rel in ${CREATED[@]+"${CREATED[@]}"}; do echo "  created $rel"; done
for m in ${MIGRATED[@]+"${MIGRATED[@]}"}; do echo "  $m"; done
if [ -z "$THEIRS" ] && [ -e "$PROJECT/AGENTS.md" ]; then
	if root_ignored; then echo "  AGENTS.md is local (/AGENTS.md in .gitignore)"
	else echo "  AGENTS.md is to be tracked: keep private rules in $LOCAL"; fi
fi
[ -n "$FOUND_CHANGELOG" ] && echo "  kept the existing changelog: $FOUND_CHANGELOG"
echo "  .pi/ (untracked: reports/, drafts/, changelog.d/, sessions, the agent tree)"
if [ -z "$THEIRS" ]; then echo "  .workspaces/, .trash/ (untracked)"; else echo "  .pi/workspaces/, .pi/trash/"; fi
if [ ${#LEFTOVERS[@]} -gt 0 ]; then
	echo
	echo "Left from the old setup, now unused (the package replaces them):"
	for rel in "${LEFTOVERS[@]}"; do echo "  $rel"; done
	echo "  Move them to .trash/ once their content is elsewhere: docs/ops/ holds"
	echo "  decisions and rules worth folding into AGENTS.md, .pi/AGENTS.md or a design"
	echo "  doc, changelog.d/ fragments move to .pi/changelog.d/."
fi
if [ ${#TO_COMMIT[@]} -gt 0 ]; then
	msg="Start the repo's AGENTS.md, CHANGELOG.md and ROADMAP.md"
	echo
	echo "To commit, by path (nothing was committed): ${TO_COMMIT[*]}"
	if [ -d "$PROJECT/.jj" ]; then
		echo "  jj commit ${TO_COMMIT[*]} -m \"$msg\""
	else
		echo "  git add ${TO_COMMIT[*]} && git commit -m \"$msg\""
	fi
fi
if command -v pi >/dev/null 2>&1; then
	# pi list prints each package's installed path; dev may be reached by a symlink.
	real="$(cd "$DEV_DIR" && pwd -P)"
	installed=""
	while IFS= read -r line; do
		path="${line#"${line%%[![:space:]]*}"}"
		[ -d "$path" ] && [ "$(cd "$path" && pwd -P)" = "$real" ] && installed=1
	done < <(pi list 2>/dev/null </dev/null)
	if [ -z "$installed" ]; then
		echo
		echo "The package isn't installed for pi yet:  pi install $DEV_DIR"
	fi
fi
