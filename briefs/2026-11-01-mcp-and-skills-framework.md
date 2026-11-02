# Brief: MCP tools, skills and plugins — where they live

| id                                  | track | size | status |
| ----------------------------------- | ----- | ---- | ------ |
| 2026-11-01-mcp-and-skills-framework | brief | S    | done   |

## Goal

The owner added connectors (Cloudflare Developer Platform, Figma, GitHub Integration, Neon, Render)
and plugins (frontend-design, Engineering, Modern Web Guidance, Figma, neon, Cloudflare, Design,
playwright) on claude.ai and wants them to benefit the projects. Cloudflare, Neon and Render belong
to `videogames-manager` only, never to the kit.

## Current behaviour / root cause

- claude.ai connectors and plugins **already sync into Claude Code** for the whole account:
  connectors appear as `claude.ai <Name>` MCP servers (`~/.claude.json → claudeAiMcpEverConnected`),
  plugins land in `~/.claude/plugins/synced/` and their skills load in every session
  (`engineering:debug`, `engineering:deploy-checklist`, `frontend-design`, `neon:*`, `cloudflare:*`,
  `figma:*`, …). Nothing has to be copied into the kit.
- Rendered subagents list fixed tools (`Read, Grep, …`), so `developer`, `reviewer` and `architect`
  **cannot** call any MCP tool (not even the project's Playwright) — the real gap.
- The Neon connector runs in write mode and exposes destructive tools (`delete_project`,
  `delete_branch`, `run_sql`, …) against production.

## Decision

1. The kit ships no MCP servers, provider skills or credentials (C2/C3).
2. `render.mjs`: an `extraTools` entry may name a capability from the project's `claude.json`, so a
   project declares an MCP tool group once and grants it to several roles.
3. README + `CLAUDE.template.md` document: account-level vs project-level integrations, granting MCP
   tools per role, and denying destructive tools in the project's `.claude/settings.json`.
4. Version 1.6.0.

Rejected (an earlier draft of this brief, kept in `git stash` "gemini 1.6.0 mcp+skills draft"):

- Kit skills `frontend-design` and `debug-protocol`, template `deploy-checklist`: duplicate the
  synced plugins (`frontend-design` even clashes by name) — more context, two sources of truth.
- `mcp.template.json` seeding GitHub/Figma servers into every project: duplicates the connectors;
  `@modelcontextprotocol/server-github` is deprecated and Figma's MCP is remote, not an npm server.
- `env.mcp.template`: Claude Code does not read `.env.mcp`; `${VAR}` in `.mcp.json` comes from the
  shell env. It also named Neon/Render/Cloudflare inside `core/`.
- `"mcp": ["mcp__*"]` capability: unused by any role.
- Premise "local harnesses cannot use claude.ai connectors": false (see above).

## Change list (agent-kit)

1. `adapters/claude/render.mjs` — `extraTools` entries expand capability names.
2. `adapters/claude/CLAUDE.template.md` — MCP tools and plugins bullet.
3. `README.md` — section "MCP tools, skills and plugins"; `tools/testgen.sh` in Layout.
4. `CHANGELOG.md`, `VERSION` — 1.6.0.

## Consuming project (`videogames-manager`)

After `install.sh ../videogames-manager --adapter claude --update`:

- `.agents/adapters/claude.json`: capability groups `browser` (Playwright), `infra-read` (read-only
  Neon/Render/Cloudflare tools); `extraTools`: architect/developer/reviewer/documenter as needed,
  commiter and lead none.
- `.claude/settings.json`: allow the read tools; deny destructive Neon/Cloudflare tools; every other
  write tool keeps asking.
- `CLAUDE.md` + `docs/12-operate-api.md`: note the connectors and the guard.

## Limitation

claude.ai connectors are account-wide; no project can hide them. Per project only permissions and
role grants differ. To keep them out of other repos entirely, disconnect them on claude.ai and
declare local servers in that project's `.mcp.json` instead.

## Verification

```bash
bash -n install.sh
node --check adapters/claude/render.mjs
TMP=$(mktemp -d) && ./install.sh "$TMP" --adapter claude && ls "$TMP/.claude/agents" && rm -rf "$TMP"
```
