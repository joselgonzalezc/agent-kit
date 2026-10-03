# AGENTS.md

Entry point for any AI coding agent (and a quick orientation for humans). Keep it short: it is
loaded into every agent's context, so every line here is paid for on every turn. Details live in
the files it points to.

## Project

<2–4 lines: what the system is, who uses it, the stack.>

## Commands

```bash
<install>
<dev server>
<test>
<lint>
<build>
```

## Where things are

<Short layout of the repo — only what an agent needs to navigate. Link the architecture doc.>

## Rules

- Constitution (supreme, full text): `<path>`.
- Rules digest (read this first): `.agents/context/rules-digest.md`.
- Pitfalls (read before working): `.agents/context/pitfalls.md`.

<3–8 bullet hard rules that are violated most often, each with its rule id.>

## Agent bindings

Values the generic roles in `.agents/roles/` resolve at run time.

| Key           | Value                                                                            |
| ------------- | -------------------------------------------------------------------------------- |
| agents-dir    | `.agents`                                                                        |
| briefs-dir    | `briefs/` (committed)                                                            |
| spec-dir      | `<specs/>` · spec tool: `<spec-kit / none>`                                      |
| constitution  | `<path>`                                                                         |
| rules digest  | `.agents/context/rules-digest.md`                                                |
| pitfalls      | `.agents/context/pitfalls.md`                                                    |
| test / lint   | `<commands>`                                                                     |
| build / e2e   | `<commands>`                                                                     |
| docs index    | `<docs/README.md>`                                                               |
| decisions log | `<docs/decisions.md or docs/adr/>`                                               |
| roadmap       | `<docs/roadmap.md>`                                                              |
| commits       | Conventional Commits · scope = `<feature>` · header ≤ 100 · trailers: `<policy>` |
| branch policy | `<e.g. commit on the current branch; never create branches unless asked>`        |

### Doc-impact map

| Change                                 | Doc                 |
| -------------------------------------- | ------------------- |
| new/changed component, route, endpoint | `<feature map>`     |
| data model, schema, migration, sync    | `<data doc>`        |
| new domain term                        | `<glossary>`        |
| load-bearing decision                  | decisions log       |
| deferred work                          | roadmap             |
| user-visible behaviour                 | `<user guide page>` |

## Agent workflow

Pick the cheapest track that is safe. Every handoff passes **file paths**, never pasted contents.

| Track     | When                                                                  | Flow                                                                                                                            |
| --------- | --------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| `direct`  | ≤ 2 files, obvious, no contract/schema change; clear bug              | developer (`direct`) → commiter                                                                                                 |
| `brief`   | fix, refactor, small feature, no new persisted/synced/public contract | architect (`brief`) → reviewer (`design`, skip if size S) → developer (`brief`) → documenter (`sync`, if doc impact) → commiter |
| `spec`    | feature/epic, new entity, persisted/synced/public contract change     | lead (architect + reviewer inside) → owner approval → lead (continued) → developer (`spec`) → documenter → commiter             |
| `consult` | question about design, no change yet                                  | architect (`consult`)                                                                                                           |

Owner approval points: open questions / deviations in a brief, the lead's consolidation, any
constitution amendment.

### Protocol for every agent

1. Read the rules digest and pitfalls; open the constitution only by section id.
2. Locate before reading; read ranges. Do not re-research what an upstream agent already wrote down
   — verify only what you are about to rely on.
3. Outputs that others consume go to files; replies are short and point to them.
4. Evidence over assertion: "done" means the verification commands ran and passed, quoted.
5. Ambiguity that changes behaviour → ask (or report as an open question). Never guess silently.
6. Never weaken a rule, test or check to get green.
7. Continue an agent that already holds the context instead of starting a fresh one.
