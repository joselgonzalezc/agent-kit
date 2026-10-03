# Core principles (portable)

Stack-, project-, spec- and model-agnostic. A project constitution copies this part verbatim
(Part A) and adds its own rules (Part B), each project rule naming the core principle it
implements. Ids `C1…` are stable; never renumber, only append.

`[!]` = NON-NEGOTIABLE.

## C1 [!] Constitution is the supreme authority

The constitution overrides every other document, preference and tool default. It changes only by
an explicit amendment approved by the owner, with date and rationale in the amendment history. A
rule that is wrong is amended, never ignored. "We'll fix it later" does not exist.

## C2 [!] Organise by feature, depend inward, no cycles

Code is grouped by feature/domain, not by technical type. Dependencies point from delivery
(UI, transport) towards the domain, never back. A feature can be removed by deleting its folder
and its registration; nothing else reaches into its internals — only its public API. Circular
dependencies are a build error.

## C3 [!] Boundaries behind contracts

Persistence, external services, clocks, randomness and other side-effecting infrastructure sit
behind interfaces owned by the domain (ports & adapters). Swapping an implementation changes no
code outside its adapter. Reads and writes are separate operations (CQRS-lite).

## C4 [!] Explicit types; parse, don't assert

Every data shape has a name. No escape-hatch types (`any`-like) and no unchecked casts. Data
crossing a boundary — network, storage, files, user input, environment — is parsed and validated
at that boundary into domain types; invalid data is rejected with a typed error, never silently
coerced. Inbound parsing of persisted or synced data is tolerant of older shapes so a rollout never
loses data (see C14).

## C5 [!] Explicit state, isolated side effects

State changes flow through one designated path per feature (facade/service/command). Updates are
immutable. Functions that look pure are pure; side effects are declared in the name/contract and
live at the edges. Long-running work is cancelable. Derived values are computed, not stored, unless
storing them is a documented decision.

## C6 [!] Testable by construction; tests that can fail

Domain logic is testable without UI, network or real infrastructure. Pure helpers have full branch
coverage. Rendering and output are deterministic (inject time and randomness). Every test tier must
be able to fail: a test that cannot observe the thing it asserts on is a defect, and the harness
guards against it. Integrations have contract tests against fixtures of the real shape.

## C7 [!] Done means verified

A change is done when tests, lint, type-check and build pass with zero new errors, acceptance
criteria are met, and — for UI — it was checked visually. "Done" is reported with evidence (the
commands and their result), not asserted. Checks are never weakened, skipped or suppressed to get
green.

## C8 [!] Documentation is part of done

Docs describe the current verified state. A change to observable behaviour, a public contract, a
parameter, a default, a schema or a config key updates the doc that describes it in the same change
set. Docs that describe old behaviour are a defect. When code, spec and docs disagree, the
discrepancy is reported and resolved by the owner, not silently picked.

## C9 Decisions and deferrals are recorded

A load-bearing decision (alternatives were rejected for a reason) is recorded with context,
decision, alternatives and consequences. Intentionally deferred work is recorded in the roadmap
with source and reason. History lives in those records and in version control — not in rule text.

## C10 [!] Security baseline

No secrets in source or committed config. Least privilege for every credential and access rule.
Authorisation is enforced as close to the data as the platform allows — row-level security
(RLS): every row is reachable only by the identities a versioned policy grants, default deny.
All external input is validated and output is encoded for its context (no raw HTML injection).
No dynamic code execution. Dependencies are audited; known high/critical vulnerabilities block
release.

## C11 [!] Accessible and resilient UI (projects with a UI)

Every interactive surface is keyboard-operable, has accessible names and visible focus, uses
semantic elements, meets contrast, honours reduced motion and works across viewport sizes and zoom.
Visual values come from design tokens.

## C12 [!] Rules for AI agents

Agents follow every rule above, plus: search and reuse existing types and logic before creating
new ones; never duplicate domain logic; make the smallest change that solves the task; never
introduce hidden side effects; stop and ask when ambiguity would change behaviour; record task
completion only for verified work; never edit a spec's task text, only its completion state.

## C13 Small, conventional commits

Commits follow Conventional Commits, one cohesive concern each, with a message that explains why
when it is not obvious. Hooks are never bypassed. Published history is never rewritten without the
owner's explicit instruction.

## C14 [!] Data safety

Persisted data survives every change: schema changes ship with a migration; parsing an older shape
never drops unrelated fields; absence is never inferred from a failure (a failed read is not an
empty result); destructive or bulk actions are undoable or confirmed. Backups can be restored, and
restoring is tested.

## Governance

- Amendments: owner-approved, versioned (MAJOR: rule removed/redefined · MINOR: rule added or
  expanded · PATCH: clarification), with date and rationale recorded in the amendment history file,
  not in the rule text.
- The rules digest is updated in the same change as any amendment.
- Rule text states the rule. Narrative — which spec introduced it, what went wrong before — belongs
  in the amendment history or the decisions log.
