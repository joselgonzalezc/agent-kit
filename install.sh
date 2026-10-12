#!/usr/bin/env bash
# Installs or updates agent-kit in a project.
#
#   ./install.sh <project-dir> [--adapter claude] [--constitution <path>] [--update]
#
# First install: copies roles + templates, creates AGENTS.md, context files and (if missing) a
# constitution skeleton with the core principles inlined. Never overwrites a project-owned file.
# --update: refreshes the kit-owned files only (roles, templates, adapter renderer) and re-renders.
set -euo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET=""
ADAPTER=""
CONSTITUTION=""
UPDATE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --adapter) ADAPTER="$2"; shift 2 ;;
    --constitution) CONSTITUTION="$2"; shift 2 ;;
    --update) UPDATE=1; shift ;;
    -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
    *) TARGET="$1"; shift ;;
  esac
done
[[ -n "$TARGET" && -d "$TARGET" ]] || { echo "usage: $0 <project-dir> [--adapter claude] [--constitution <path>] [--update]" >&2; exit 1; }
TARGET="$(cd "$TARGET" && pwd)"
AG="$TARGET/.agents"

# kit-owned: always refreshed on --update
kit_copy() { # src dst
  if [[ -e "$2" && $UPDATE -eq 0 ]]; then echo "keep    ${2#"$TARGET"/}"; return; fi
  mkdir -p "$(dirname "$2")"; cp "$1" "$2"; echo "write   ${2#"$TARGET"/}"
}
# project-owned: created once, never overwritten
seed() { # src dst
  if [[ -e "$2" ]]; then echo "keep    ${2#"$TARGET"/}"; return; fi
  mkdir -p "$(dirname "$2")"; cp "$1" "$2"; echo "create  ${2#"$TARGET"/}"
}

for f in "$KIT"/core/roles/*.md; do kit_copy "$f" "$AG/roles/$(basename "$f")"; done
for f in "$KIT"/core/templates/*.md; do kit_copy "$f" "$AG/templates/$(basename "$f")"; done
kit_copy "$KIT/core/docs-structure.md" "$AG/docs-structure.md"
for f in "$KIT"/core/tools/*.sh; do kit_copy "$f" "$AG/tools/$(basename "$f")"; chmod +x "$AG/tools/$(basename "$f")"; done
seed "$KIT/core/templates/pitfalls.md" "$AG/context/pitfalls.md"
seed "$KIT/core/templates/rules-digest.md" "$AG/context/rules-digest.md"
seed "$KIT/core/AGENTS.template.md" "$TARGET/AGENTS.md"
mkdir -p "$TARGET/briefs"; [[ -n "$(ls -A "$TARGET/briefs")" ]] || touch "$TARGET/briefs/.gitkeep"

if [[ -n "$CONSTITUTION" && ! -e "$TARGET/$CONSTITUTION" ]]; then
  mkdir -p "$(dirname "$TARGET/$CONSTITUTION")"
  awk -v core="$KIT/core/constitution/core.md" '
    /^<Copy `agent-kit\/core\/constitution\/core.md`/ { while ((getline l < core) > 0) print l; skip=1; next }
    skip && /^here; propose changes/ { skip=0; next }
    !skip { print }
  ' "$KIT/core/constitution/constitution.template.md" > "$TARGET/$CONSTITUTION"
  echo "create  $CONSTITUTION"
fi

case "$ADAPTER" in
  claude)
    kit_copy "$KIT/adapters/claude/render.mjs" "$AG/adapters/claude/render.mjs"
    seed "$KIT/adapters/claude/claude.json" "$AG/adapters/claude.json"
    seed "$KIT/adapters/claude/CLAUDE.template.md" "$TARGET/CLAUDE.md"
    node "$AG/adapters/claude/render.mjs"
    ;;
  "") ;;
  *) echo "unknown adapter: $ADAPTER (available: claude)" >&2; exit 1 ;;
esac

cp "$KIT/VERSION" "$AG/KIT_VERSION"
echo "agent-kit $(cat "$KIT/VERSION") → $TARGET"
echo "Next: fill AGENTS.md (bindings), write Part B of the constitution, then the rules digest."
