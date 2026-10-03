# Documentation structure

What the documenter maintains and where. Start small; add a doc when there is something true to say
in it, not before.

## Three readers, one set of docs

| Reader     | Needs                                           | Lives in                                |
| ---------- | ----------------------------------------------- | --------------------------------------- |
| AI agents  | rules, where things are, traps, current task    | `AGENTS.md`, `.agents/context/`, briefs |
| Developers | how it is built, how to change, run and ship it | `docs/` (numbered)                      |
| Users      | how to use it                                   | `docs/user-guide/` (Diátaxis)           |

Agents also read `docs/` — on demand, by section, never as a whole.

## Developer docs — numbered in reading order

```
docs/
  README.md                 # index: one line per doc, what it gives you
  01-project-overview.md    # what it is, stack, routes/endpoints, where code lives
  02-architecture.md        # layers, seams, data flow (C4 context + container level is enough)
  03-data-and-storage.md    # entities, schema, migrations, sync/consistency contract
  04-feature-map.md         # per feature: entry → components/handlers → application → infra
  05-glossary.md            # one definition per term
  06+ topic docs            # styling, import formats, deploy, release checklist, …
  NN-decisions-log.md       # ADR entries (or docs/adr/ADR-NNN-*.md, one per decision)
  NN-roadmap.md             # planned, deferred (with source + reason), known defects
```

Numbers give a reading order and stable names; gaps are fine.

## User docs — Diátaxis

```
docs/user-guide/
  README.md
  tutorials/      # learning: "your first …", step by step, guaranteed to work
  how-to/         # goals: "how to import …", assumes basic familiarity
  reference/      # lookup: fields, settings, shortcuts, file formats
  explanation/    # understanding: "how sync works", "why scores differ"
```

One purpose per page. A how-to never stops to explain; an explanation never lists steps.

## Specs vs docs

- **Specs** (`specs/` or briefs) say what a change _should_ do. They are a historical archive once
  shipped and are not updated afterwards.
- **Docs** say what the system _does now_. They are updated with every observable change.
- **Constitution** says what must always hold.
- **Decisions log** says why.

Never point a reader at a spec to learn current behaviour; move that knowledge into docs.

## Diagrams

Mermaid in Markdown, so diagrams diff and review like text. C4 levels 1–2 (context, containers)
cover most needs; go deeper only for a component that is genuinely complex.
