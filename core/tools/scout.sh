#!/usr/bin/env bash
# scout — read-only delegate to a second, cheaper model (default: Antigravity CLI `agy`).
#
#   .agents/tools/scout.sh [--fast] [--model <id>] [--timeout <sec>] "<question>"
#   echo "<question>" | .agents/tools/scout.sh
#
# Use it for broad READ-ONLY work whose raw input would flood the caller's context: sweeping many
# files, doc/code drift, summarising specs, a second-opinion review of a diff or brief, drafting
# prose. The caller gets back only the answer; it verifies anything it relies on (protocol rule 2).
# Never use it for production code, rule enforcement or commits.
#
# Safety: runs in plan mode + sandbox (no file writes, no shell). As a second guard it fingerprints
# the working tree before and after; any change → exit 3 and the diff is left for the owner.
#
# Env: SCOUT_MODEL (default claude-opus-4-6-thinking), SCOUT_FAST_MODEL (default gemini-3.8-flash-high),
#      SCOUT_TIMEOUT (seconds, default 600), SCOUT_MAX_WORDS (default 400).
set -euo pipefail

MODEL="${SCOUT_MODEL:-claude-opus-4-6-thinking}"
TIMEOUT="${SCOUT_TIMEOUT:-600}"
MAX_WORDS="${SCOUT_MAX_WORDS:-400}"
PROMPT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fast) MODEL="${SCOUT_FAST_MODEL:-gemini-3.8-flash-high}"; shift ;;
    --model) MODEL="$2"; shift 2 ;;
    --timeout) TIMEOUT="$2"; shift 2 ;;
    -h|--help) sed -n '2,17p' "$0"; exit 0 ;;
    *) PROMPT="${PROMPT:+$PROMPT }$1"; shift ;;
  esac
done
[[ -n "$PROMPT" || -t 0 ]] || PROMPT="$(cat)"
[[ -n "$PROMPT" ]] || { echo "scout: empty question (see --help)" >&2; exit 1; }
command -v agy >/dev/null || { echo "scout: agy not found — install Antigravity CLI" >&2; exit 1; }
command -v jq >/dev/null || { echo "scout: jq not found" >&2; exit 1; }

fingerprint() { git status --porcelain=v1 -uall 2>/dev/null; git diff 2>/dev/null | sha1sum; }
before="$(fingerprint)"

frame="You are a read-only scout for another coding agent. Do not modify, create or delete files and
do not run commands. Follow the project rules in AGENTS.md. Answer the question below directly, in
at most ${MAX_WORDS} words, as terse bullets. Cite evidence as path:line. If you are unsure, say so
instead of guessing.

QUESTION:
${PROMPT}"

set +e
raw="$(agy -p "$frame" --mode plan --sandbox --model "$MODEL" --output-format json \
  --print-timeout "${TIMEOUT}s" 2>/dev/null)"
status=$?
set -e

after="$(fingerprint)"
if [[ "$before" != "$after" ]]; then
  echo "scout: WORKING TREE CHANGED during the run — inspect 'git status' / 'git diff'." >&2
  exit 3
fi

json="$(printf '%s\n' "$raw" | grep -E '^\{' | tail -n 1)"
answer="$(printf '%s' "$json" | jq -r '.response // empty' 2>/dev/null || true)"
if [[ $status -ne 0 || -z "$answer" ]]; then
  denied="$(printf '%s' "$json" | jq -r '[.denied_actions[]?.action] | join(", ")' 2>/dev/null || true)"
  echo "scout: no answer (exit $status${denied:+, denied: $denied}). Answer it yourself." >&2
  exit 2
fi
printf '%s\n' "$answer"
