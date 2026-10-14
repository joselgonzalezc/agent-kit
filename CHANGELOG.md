# Changelog

## 1.5.0

- `core/tools/testgen.sh` (installed to `.agents/tools/`): drafts a unit test with a second model
  (default `agy` + Claude Sonnet 4.6) in a detached worktree; the model may write only the test file;
  the project hook `<agents-dir>/testgen.config.sh` links build/deps, verifies (coverage) and
  lint-fixes; the draft lands in `<git-dir>/testgen/` for the caller to review and adopt. Skips the
  model when the existing test already passes verify. Protocol rule 9; developer uses it for pure
  modules.
- scout: Gemini 3.1 Pro left the Antigravity CLI for AI Pro accounts; defaults are now
  `claude-opus-4-6-thinking` and `--fast` `gemini-3.8-flash-high`.
- documenter: scout pre-pass uses `--fast` (Flash high: accurate on drift; agy-hosted Opus is flaky
  in print mode).

## 1.4.1

- developer: spec mode sets `spec.md` `**Status**` to `Implemented` when the last task is ticked.

## 1.4.0

- documenter: scout pre-pass in `sync`/`audit` (candidates only, every one verified before use);
  new `inline` mode reports doc comments that contradict the code, routed to the developer; report
  gains `inline-doc drift` and `scout` lines.

## 1.3.0

- `core/tools/scout.sh` (installed to `.agents/tools/`): read-only delegate to a second model
  (default Antigravity CLI `agy`, plan mode + sandbox, working-tree guard). Protocol rule 8 in
  `AGENTS.template.md` routes broad read-only sweeps to it.

## 1.2.1

- install copies `docs-structure.md` to `.agents/`; documenter points to it.

## 1.2.0

- Roles learned from the first full spec run (videogames-manager spec 049):
  - lead: fallback when it cannot message a running agent; may hand-write spec artefacts from the
    spec tool's templates when the tool is unavailable; `[owner]` steps written for each target's
    real deploy setup.
  - architect: owner steps must be grounded in how the target actually deploys.
  - developer: mandatory cleanup of every process it started, reported in a `cleanup:` line.
  - documenter: verify every factual statement; no bulk search-and-replace of paths.
  - commiter: every commit passes its own checks — no gate before the code it validates.

## 1.1.0

- Row-level security: core C10 (authorisation at the data, default deny), backend profile BE.17,
  offline-sync OS.6 reference, reviewer security dimension for access-rule changes.

## 1.0.0

- Initial kit: core constitution C1–C14, profiles (frontend-web, backend-service, offline-sync),
  generic roles (lead, architect, reviewer, developer, documenter, commiter), templates (brief, ADR,
  pitfalls, rules digest), Claude Code adapter (renderer), install script.
