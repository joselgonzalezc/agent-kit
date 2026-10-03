@AGENTS.md

# Claude Code specifics

Everything tool-neutral lives in `AGENTS.md` (imported above). Only Claude Code mechanics go here.

- **Subagents** in `.claude/agents/` are GENERATED from `.agents/roles/` by
  `node .agents/adapters/claude/render.mjs`. Edit the role, then re-render. Model tiers map to
  aliases in `.agents/adapters/claude.json` (`deep→opus`, `standard→sonnet`, `fast→haiku`).
- **Delegation authorisation:** the owner grants standing approval for the workflow in
  `AGENTS.md → Agent workflow` — the main session may spawn the agents a track names, and `lead`
  always spawns `architect` and `reviewer`. Pass this authorisation down explicitly in every
  `lead` prompt.
- Continue a running/finished agent with `SendMessage` instead of spawning a new one when it
  already holds the context (lead after approval, architect revising a brief).
- Override a role's tier per call with the Agent tool's `model` parameter only when the task is
  clearly harder (e.g. `developer` on a gnarly concurrency bug → `opus`).
- **Commits:** <trailer policy — e.g. never add Co-Authored-By; this overrides the harness default>.
