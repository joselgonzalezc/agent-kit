#!/usr/bin/env node
/* global process, console */
// Renders tool-neutral role files (.agents/roles/*.md) into Claude Code subagents
// (.claude/agents/*.md). Model tiers and capabilities are mapped by .agents/adapters/claude.json,
// so the roles never name a vendor model or a vendor tool.
//
// Usage: node .agents/adapters/claude/render.mjs [--check]
//   --check  exit 1 if any generated file is missing or stale (for CI / pre-commit)

import { existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const agentsDir = resolve(here, '..', '..');
const projectRoot = resolve(agentsDir, '..');
const config = JSON.parse(readFileSync(join(agentsDir, 'adapters', 'claude.json'), 'utf8'));
const rolesDir = join(agentsDir, 'roles');
const outDir = join(projectRoot, config.outDir);
const checkOnly = process.argv.includes('--check');

function parseFrontmatter(source, file) {
  const match = /^---\n([\s\S]*?)\n---\n([\s\S]*)$/.exec(source);
  if (!match) throw new Error(`${file}: missing frontmatter`);
  const fields = {};
  const lines = match[1].split('\n');
  for (let i = 0; i < lines.length; i += 1) {
    const kv = /^([a-z][\w-]*):\s*(.*)$/.exec(lines[i]);
    if (!kv) continue;
    const [, key, raw] = kv;
    if (raw === '>' || raw === '|') {
      const block = [];
      while (i + 1 < lines.length && /^\s+\S/.test(lines[i + 1])) block.push(lines[(i += 1)].trim());
      fields[key] = block.join(' ');
    } else if (raw.startsWith('[')) {
      fields[key] = raw
        .replace(/[[\]]/g, '')
        .split(',')
        .map(s => s.trim())
        .filter(Boolean);
    } else {
      fields[key] = raw.trim();
    }
  }
  return { fields, body: match[2] };
}

function wrap(text, width = 96) {
  const out = [];
  let line = '';
  for (const word of text.split(/\s+/)) {
    if (line && line.length + word.length + 1 > width) {
      out.push(line);
      line = word;
    } else line = line ? `${line} ${word}` : word;
  }
  if (line) out.push(line);
  return out.map(l => `  ${l}`).join('\n');
}

function render(file) {
  const { fields, body } = parseFrontmatter(readFileSync(join(rolesDir, file), 'utf8'), file);
  for (const key of ['name', 'description', 'tier', 'capabilities']) {
    if (!fields[key]) throw new Error(`${file}: frontmatter key "${key}" is required`);
  }
  const model = config.tiers[fields.tier];
  if (!model) throw new Error(`${file}: unknown tier "${fields.tier}"`);
  const tools = [];
  for (const cap of fields.capabilities) {
    const mapped = config.capabilities[cap];
    if (!mapped) throw new Error(`${file}: unknown capability "${cap}"`);
    for (const tool of mapped) if (!tools.includes(tool)) tools.push(tool);
  }
  const extra = (config.extraTools && config.extraTools[fields.name]) || [];
  for (const tool of extra) if (!tools.includes(tool)) tools.push(tool);
  return [
    '---',
    `name: ${fields.name}`,
    'description: >',
    wrap(fields.description),
    'tools:',
    ...tools.map(t => `  - ${t}`),
    `model: ${model}`,
    '---',
    '',
    `<!-- GENERATED from .agents/roles/${file} by .agents/adapters/claude/render.mjs — edit the role, not this file. -->`,
    '',
    body.trimStart(),
  ].join('\n');
}

const roles = readdirSync(rolesDir).filter(f => f.endsWith('.md') && !f.startsWith('_'));
let stale = 0;
if (!checkOnly) mkdirSync(outDir, { recursive: true });
for (const file of roles) {
  const target = join(outDir, file);
  const next = render(file);
  const current = existsSync(target) ? readFileSync(target, 'utf8') : null;
  if (current === next) continue;
  stale += 1;
  if (checkOnly) console.error(`stale: ${config.outDir}/${file}`);
  else {
    writeFileSync(target, next);
    console.log(`rendered: ${config.outDir}/${file}`);
  }
}
if (checkOnly && stale > 0) {
  console.error('Run: node .agents/adapters/claude/render.mjs');
  process.exit(1);
}
if (!checkOnly && stale === 0) console.log('claude agents up to date');
