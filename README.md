# agent-kit

A portable way of working with AI coding agents: a constitution, generic agent roles, task
templates and documentation conventions. Independent of stack, project, spec tool and model vendor.
First consumer: `videogames-manager`.

## Principles

1. **Thinking happens upstream.** The architect researches and decides; the reviewer attacks the
   decision; the developer executes a brief that leaves nothing to decide. Expensive reasoning
   runs once, on the strongest tier, instead of being redone by every agent.
2. **Context is engineered, not dumped.** Agents read a one-line-per-rule digest and a pitfalls
   list, then open exactly the sections and line ranges they need. Handoffs pass file paths, not
   pasted content.
3. **The cheapest safe track wins.** A typo does not need a spec; a synced-schema change does.
4. **Evidence over assertion.** "Done" carries the commands that ran and their results.
5. **Vendor-neutral by construction.** Roles declare a tier (`deep | standard | fast`) and
   capabilities (`read | write | edit | exec | delegate`). An adapter maps them to a runtime.

## Layers of knowledge

| Layer         | Lifetime | Where                                             | Who writes         |
| ------------- | -------- | ------------------------------------------------- | ------------------ |
| Constitution  | years    | project constitution (Part A core + Part B rules) | owner (amendments) |
| Knowledge     | long     | `docs/`, decisions log, `.agents/context/`        | documenter         |
| Task context  | one task | `briefs/*.md` or `specs/<id>/`                    | architect / lead   |
| Working state | one run  | the agent's own context                           | —                  |

## Layout

```
core/
  AGENTS.template.md          project entry point: commands, bindings, workflow, protocol
  constitution/
    core.md                   C1–C14 portable principles + governance
    constitution.template.md  Part A (core, verbatim) + Part B (project rules)
    profiles/
      frontend-web.md         FE.* — TypeScript web app / component library
      backend-service.md      BE.* — API / service / worker
      offline-sync.md         OS.* — local-first clients with background sync
  roles/                      lead, architect, reviewer, developer, documenter, commiter
  templates/                  brief, adr, pitfalls, rules-digest
  tools/scout.sh              read-only delegate to a cheaper second model (Antigravity CLI)
  docs-structure.md           numbered developer docs + Diátaxis user guide
adapters/
  claude/                     renderer → .claude/agents/*.md, tier/capability map, CLAUDE.md
  generic/                    how to use the kit with any other runtime
install.sh
```

## Roles

| Role       | Tier     | Does                                                        | Never                         |
| ---------- | -------- | ----------------------------------------------------------- | ----------------------------- |
| lead       | standard | spec track: architect → reviewer → owner → spec/plan/tasks  | writes code                   |
| architect  | deep     | research + design → executable brief                        | writes code                   |
| reviewer   | standard | findings with evidence + concrete fix, per needed dimension | edits anything but its review |
| developer  | standard | implements briefs/tasks, fixes bugs, tests, evidence        | redesigns                     |
| documenter | standard | doc impact, drift detection, decisions, user guide          | edits code or specs           |
| commiter   | fast     | grouped Conventional Commits, push on request               | rewrites history              |

Why no analyst / researcher / tester / bugfixer: each extra agent re-reads the project. The architect
already researches and analyses; the developer already tests and fixes. Add a role only when a
responsibility cannot be stated as a mode of an existing one.

## Tracks

| Track   | When                                                         | Agents                                                                  |
| ------- | ------------------------------------------------------------ | ----------------------------------------------------------------------- |
| direct  | ≤ 2 files, obvious, no contract change; clear bug            | developer → commiter                                                    |
| brief   | fix / refactor / small feature without new public contract   | architect → reviewer (skip for S) → developer → documenter → commiter   |
| spec    | feature, new entity, persisted/synced/public contract change | lead (+architect, reviewer) → owner → developer → documenter → commiter |
| consult | design question                                              | architect                                                               |

The spec track works with any spec tool (spec-kit or none); the brief track needs none.

## Token budget rules (why this is cheaper)

- Constitution rule text holds rules only; history moves to an amendment-history file. Agents read
  the digest (~2–4 k tokens) instead of the full text.
- `AGENTS.md` is loaded on every turn of every agent — keep it under ~250 lines; link out.
- Briefs carry the applicable rules verbatim, so the developer never opens the constitution.
- Agents return ≤ 10–25 line replies pointing at files; the caller's context stays small.
- Continue an agent that holds the context instead of spawning a fresh one.
- The commiter does not re-run checks that the developer just ran on the same tree.
- Use the `deep` tier only where decisions are made.

## Adopt in a project

```bash
~/Documents/personal/agent-kit/install.sh <project> --adapter claude \
  --constitution docs/constitution.md        # or .specify/memory/constitution.md with spec-kit
```

Then:

1. Fill `AGENTS.md`: project summary, commands, layout, **Agent bindings**, doc-impact map.
2. Write Part B of the constitution from the profiles that apply; bind real paths and names.
3. Write `.agents/context/rules-digest.md` (one line per rule, same ids).
4. Start `.agents/context/pitfalls.md` empty; add traps as they bite.
5. `CLAUDE.md` just imports `AGENTS.md`; keep Claude-only mechanics there.

## Update a project

```bash
~/Documents/personal/agent-kit/install.sh <project> --adapter claude --update
```

Refreshes roles, templates and the renderer (kit-owned), keeps `AGENTS.md`, the constitution,
context files and `claude.json` (project-owned), then re-renders `.claude/agents/`.
Improve a role here, in the kit, and push it to every project with `--update` — do not fork roles
per project; put project specifics in `AGENTS.md` bindings.
