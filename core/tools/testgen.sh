#!/usr/bin/env bash
# testgen — draft a unit test with a second, cheaper model in a throwaway git worktree.
#
#   .agents/tools/testgen.sh [--model <id>] [--timeout <sec>] [--fresh] [--ref <test>]... \
#       <source-file> <test-file>
#
# Paths are repo-relative. The model may write ONLY <test-file>, inside a detached worktree of HEAD;
# the caller's working tree is never touched. Then the project hook verifies the draft (tests +
# coverage) and lint-fixes it, and the draft is copied to an output folder for the caller to review
# and adopt (cp). Exit 0 = draft written AND verify passed; 4 = draft written, verify failed (read
# the log); 2 = no draft; 3 = the model touched another file (nothing kept). Without --fresh, an
# existing test that already passes verify short-circuits to exit 0 without calling the model.
#
#   --fresh   delete an existing <test-file> in the worktree first (benchmark / full rewrite);
#             default: the model extends the existing file and keeps every existing test.
#   --ref     a sibling test to copy conventions from (repeatable; give 1–2).
#
# Project hook: <agents-dir>/testgen.config.sh (sourced, optional) may define
#   TESTGEN_LINKS=(<repo-relative paths>)  symlinked from the main checkout into the worktree
#                                           (node_modules, build outputs the test setup imports)
#   testgen_verify <source> <test>          run from the worktree root; non-zero = failed
#   testgen_lint_fix <test>                 run from the worktree root; best effort
#
# Pure modules (helpers, facades, domain) are the target. Component tests run against whatever
# build the links point at, so they are only as fresh as the main checkout's last build.
#
# Env: TESTGEN_MODEL (default claude-sonnet-4-6), TESTGEN_TIMEOUT (seconds, default 900),
#      TESTGEN_OUT (output folder, default <git-dir>/testgen).
set -euo pipefail

MODEL="${TESTGEN_MODEL:-claude-sonnet-4-6}"
TIMEOUT="${TESTGEN_TIMEOUT:-900}"
FRESH=0
REFS=()
ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --model) MODEL="$2"; shift 2 ;;
    --timeout) TIMEOUT="$2"; shift 2 ;;
    --fresh) FRESH=1; shift ;;
    --ref) REFS+=("$2"); shift 2 ;;
    -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
    *) ARGS+=("$1"); shift ;;
  esac
done
[[ ${#ARGS[@]} -eq 2 ]] || { echo "testgen: need <source-file> <test-file> (see --help)" >&2; exit 1; }
SRC="${ARGS[0]}"
TEST="${ARGS[1]}"
command -v agy >/dev/null || { echo "testgen: agy not found — install Antigravity CLI" >&2; exit 1; }
command -v jq >/dev/null || { echo "testgen: jq not found" >&2; exit 1; }

ROOT="$(git rev-parse --show-toplevel)"
[[ -f "$ROOT/$SRC" ]] || { echo "testgen: source not found: $SRC" >&2; exit 1; }
AGENTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TESTGEN_LINKS=()
testgen_verify() { echo "testgen: no testgen_verify hook in $AGENTS_DIR/testgen.config.sh" >&2; return 1; }
testgen_lint_fix() { :; }
# shellcheck source=/dev/null
[[ -f "$AGENTS_DIR/testgen.config.sh" ]] && source "$AGENTS_DIR/testgen.config.sh"

OUT="${TESTGEN_OUT:-$(git rev-parse --absolute-git-dir)/testgen}"
mkdir -p "$OUT"
STAMP="$(date +%Y%m%d-%H%M%S)"
DRAFT="$OUT/$STAMP-$(basename "$TEST")"
LOG="$OUT/$STAMP-$(basename "$TEST" | sed 's/\.[^.]*$//').log"

WT="$(mktemp -d "${TMPDIR:-/tmp}/testgen-XXXXXX")"
cleanup() { git -C "$ROOT" worktree remove --force "$WT" >/dev/null 2>&1 || rm -rf "$WT"; git -C "$ROOT" worktree prune; }
trap cleanup EXIT
git -C "$ROOT" worktree add --detach --quiet "$WT" HEAD
for link in "${TESTGEN_LINKS[@]}"; do
  [[ -e "$ROOT/$link" && ! -e "$WT/$link" ]] && ln -s "$ROOT/$link" "$WT/$link"
done
# Uncommitted edits to the source are what the caller wants tested.
cp "$ROOT/$SRC" "$WT/$SRC"
[[ $FRESH -eq 1 ]] && rm -f "$WT/$TEST"
if [[ $FRESH -eq 0 && -f "$WT/$TEST" ]]; then
  # Nothing to draft when the existing test already passes the project's verify (full coverage).
  if (cd "$WT" && testgen_verify "$SRC" "$TEST") >"$LOG" 2>&1; then
    echo "testgen: $TEST already passes verify — no draft needed. Log: $LOG"
    exit 0
  fi
fi
baseline="$(git -C "$WT" status --porcelain=v1 -uall | grep -vF " $TEST" || true)"

refs=""
for r in "${REFS[@]}"; do refs="${refs:+$refs and }$r"; done
if [[ -f "$WT/$TEST" ]]; then
  goal="Extend the existing test file $TEST so it covers every branch of $SRC. Keep every existing test unchanged; add tests only."
else
  goal="Create the unit test file $TEST for $SRC."
fi
prompt="Use ONLY your file read and file write tools. Never run shell commands and never list directories:
they are blocked and abort your turn. Every path you need is given here or imported by these files.

TASK: ${goal}
First read $SRC, the modules it imports (for exact types)${refs:+, and these sibling tests for conventions: $refs}.
Follow the project rules in AGENTS.md (types, no 'any', no 'as' casts on data). Aim for 100% branch
coverage: one describe per exported function, every documented rule and edge case. Build fixtures with
small local factory functions. Write ONLY $TEST; modify nothing else. You cannot run the tests, so
reason through each branch before writing."

{
  echo "# testgen $STAMP model=$MODEL src=$SRC test=$TEST fresh=$FRESH"
  set +e
  (cd "$WT" && agy -p "$prompt" --mode accept-edits --sandbox --model "$MODEL" --output-format json \
    --print-timeout "${TIMEOUT}s" 2>/dev/null) | grep -E '^\{' | tail -n 1 \
    | jq '{status, error, duration_seconds, usage: .usage.total_tokens, denied_actions}'
  set -e
} >>"$LOG" 2>&1

after="$(git -C "$WT" status --porcelain=v1 -uall | grep -vF " $TEST" || true)"
if [[ "$baseline" != "$after" ]]; then
  { echo "## model touched files other than $TEST:"; diff <(echo "$baseline") <(echo "$after"); } >>"$LOG"
  echo "testgen: model edited other files — nothing kept. Log: $LOG" >&2
  exit 3
fi
if [[ ! -f "$WT/$TEST" ]] || { [[ $FRESH -eq 0 ]] && git -C "$WT" diff --quiet -- "$TEST" 2>/dev/null && git -C "$WT" ls-files --error-unmatch "$TEST" >/dev/null 2>&1; }; then
  echo "testgen: no draft produced. Log: $LOG" >&2
  exit 2
fi

(cd "$WT" && testgen_lint_fix "$TEST") >>"$LOG" 2>&1 || true
set +e
(cd "$WT" && testgen_verify "$SRC" "$TEST") >>"$LOG" 2>&1
verify=$?
set -e
cp "$WT/$TEST" "$DRAFT"

echo "draft:  $DRAFT"
echo "log:    $LOG"
echo "adopt:  cp '$DRAFT' '$ROOT/$TEST'   (review it first)"
grep -E "Tests |Branches|Statements|error|✖" "$LOG" | tail -n 8 || true
if [[ $verify -ne 0 ]]; then
  echo "testgen: verify FAILED (exit $verify) — see log." >&2
  exit 4
fi
