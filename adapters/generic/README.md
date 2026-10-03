# Using the kit with other AI tools

Nothing in `core/` names a vendor, a model or a tool. Any agent runtime can use it:

| Runtime                                                                                     | Project instructions          | Roles                                                           |
| ------------------------------------------------------------------------------------------- | ----------------------------- | --------------------------------------------------------------- |
| Tools that read `AGENTS.md` natively (Codex CLI, Gemini CLI via config, Copilot, Cursor, …) | `AGENTS.md`                   | Prompt: "Act as the role defined in `.agents/roles/<role>.md`." |
| Tools with their own subagent format                                                        | import or symlink `AGENTS.md` | write a renderer like `adapters/claude/render.mjs`              |
| Plain chat model / API                                                                      | paste `AGENTS.md`             | system prompt = role file body                                  |

## Mapping tiers

Roles declare `tier: deep | standard | fast` — a cost/capability level, not a model:

- `deep` — design and root-cause work where a wrong decision is expensive (architect).
- `standard` — executes well-specified work, reviews, writes docs (lead, developer, reviewer,
  documenter).
- `fast` — mechanical work with strict rules (commiter).

Map each tier to whatever model your runtime offers at that level. When the vendor renames models,
only the adapter mapping changes.

## Mapping capabilities

`read` (read files, search) · `write` (create files) · `edit` (modify files) · `exec` (run shell
commands) · `delegate` (start another agent). Grant the closest equivalents; if a runtime cannot
delegate, the caller runs the steps of the lead's protocol itself.
