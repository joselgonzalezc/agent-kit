# Brief: <title>

| id                  | track              | size        | status                             |
| ------------------- | ------------------ | ----------- | ---------------------------------- |
| <YYYY-MM-DD>-<slug> | brief \| spec:<id> | S \| M \| L | draft → reviewed → approved → done |

## Goal

<1–3 lines: the outcome, from the user's point of view.>

## Current behaviour / root cause

<What happens now. For a bug: root cause with evidence `path:line`, the reproduce command and its
current output.>

## Decision

<Chosen approach in 2–5 lines.>

Rejected:

- <alternative> — <why not, one line>

## Change list

Ordered. Each item is executable as written.

1. `path/to/file.ext` — modify — <exact edit>.
   ```ts
   // signatures / types / schema the developer must produce
   ```
2. `path/to/new-file.ext` — create — <contents in terms of exports + responsibilities>.

## Tests

| File                | Case                            | Asserts            |
| ------------------- | ------------------------------- | ------------------ |
| `path/to/x.test.ts` | <name describing the behaviour> | <input → expected> |

## Applicable rules

- `<rule id>` — <the rule in one line, copied from the constitution>.

## Edge cases

- <input/state> → <expected result>.

## Doc impact

- `<doc path>` — <what changes>. (or: `none` — <why nothing observable changed>)

## Verification

```bash
<test command>
<lint command>
```

<UI: route(s), viewports, reference to compare against.>

## Review focus

<correctness, rules, security, data-safety, performance, a11y, tests, docs — only what applies>

## Out of scope

- <thing that looks related but is not part of this change>

## Open questions

1. <question> — recommended: <answer>.

<!-- Reviewer writes <this-file>.review.md. Developer appends "## Implementation notes" below. -->
