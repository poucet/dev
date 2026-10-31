#!/usr/bin/env bash
#
# adopt.sh — install the simply/dev workflow into a project.
#
# Does four things, all idempotent (safe to re-run; nothing existing is
# overwritten):
#
#   1. links AGENTS.md         -> dev's AGENTS.md, by a relative symlink
#      (../dev/AGENTS.md when the repo sits beside dev), and starts an
#      AGENTS.project.md for the repo's own rules
#   2. symlinks the role definitions into the directory the coding harness
#      in use reads them from:
#        pi.dev       .pi/agents       (personas; needs projectPersonas: true
#                                       in ~/.pi/agent/subagents.json and a
#                                       trusted project)
#        Claude Code  .claude/agents   (subagents)
#   3. lays out the doc web per AGENTS.md §3:
#        CHANGELOG.md at the root, tracked (changelog.d/ appears with the
#        first lane fragment)
#        docs/ops/   the one untracked directory of working state:
#                    BOARD DECIDE ASKS  ISSUES DECISIONS IDEAS ROADMAP  STATUS
#                    (drafts/ appears when there is a draft)
#        (docs/{design,research,guides,reference}/ are not made: a folder
#        appears when there is something to put in it)
#        .workspaces/  .trash/   (untracked)
#      The starter files are copied from dev's templates/, each only where
#      the project has no file of that name yet.
#      A real AGENTS.md is left alone: its rules move into AGENTS.project.md
#      by hand (skills/adopt), then re-run this to make the link.
#   4. ignores what must never be committed: each untracked directory above
#      (and .claude/ or .pi/) gets its own .gitignore holding '*'. The symlink
#      targets are machine-specific absolute paths, so they must never be
#      committed either.
#
# Usage:
#   ./adopt.sh <project-dir> [--harness pi|claude|both|auto]
#
#   --harness          which harness directory(s) to wire (default: auto —
#                      .claude if the project has one, else .pi)

#
set -euo pipefail

DEV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "dev dir: $DEV_DIR"

usage() { sed -n '2,32p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

PROJECT=""
HARNESS="auto"

while [ $# -gt 0 ]; do
	case "$1" in
		-h|--help) usage 0 ;;
		--harness) HARNESS="${2:?}"; shift 2 ;;
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
link_into "$AGENTS_LINK" "$PROJECT/AGENTS.md"

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
ensure_untracked_dir "$PROJECT/.workspaces"
ensure_untracked_dir "$PROJECT/.trash"

# The starter files: AGENTS.project.md, CHANGELOG.md, and docs/ops/'s
# BOARD DECIDE ASKS ISSUES DECISIONS IDEAS ROADMAP STATUS.
copy_templates

# --- report -------------------------------------------------------------------

echo "Adopted simply/dev into $PROJECT (harness: $HARNESS)."
echo "  AGENTS.md -> $AGENTS_LINK, AGENTS.project.md"
for dir in "${AGENT_DIRS[@]}"; do
	echo "  $dir -> $DEV_DIR/agents"
done
echo "  CHANGELOG.md (tracked)"
echo "  docs/ops/ (untracked)"
echo "  .workspaces/, .trash/"
if [ "$HARNESS" = "pi" ] || [ "$HARNESS" = "both" ]; then
	echo
	echo "Reminders for pi:"
	echo "  - set \"projectPersonas\": true in ~/.pi/agent/subagents.json"
	echo "  - trust the project when pi prompts on next launch"
fi
echo
