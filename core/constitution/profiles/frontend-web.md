# Profile: frontend web application (TypeScript)

Optional rule set for a browser application. Copy the rules that apply into Part B of the project
constitution and bind the placeholders (`<prefix>`, paths, tools). Each rule names the core
principle it implements. Distilled from a production component-library SPA; framework-neutral
unless stated.

## FE.1 Feature folders with layered insides — C2, C3

```
src/
  app/                 # shell: bootstrapping, routing, layout
  features/<feature>/
    domain/            # entities, value objects, domain events — no framework, no infra
    application/       # facades / commands / queries
    infrastructure/    # repository + adapter implementations
    ui/<component>/    # components
  shared/              # truly cross-feature: components, domain, ports, utils
```

Forbidden: flat `components/`, `services/`, `stores/` that mix features. `shared/` never imports
from `features/`.

## FE.2 Components are presentation — C3, C5

A component renders inputs, emits events and holds only visual state. It never fetches, persists,
syncs or evaluates business rules; it calls a facade. Lifecycle hooks only wire data flow.

## FE.3 One responsibility per file — C2, C6

Per component: view, facade (if stateful), pure helpers, constants, types/enums, styles, unit tests,
component/a11y tests — each in its own co-located file. Types and enums live only in the types file;
constants only in the constants file. A private method that does not use instance state is a pure
helper and gets a unit test. A render function whose description needs "and" more than once is
split into named sub-render functions.

## FE.4 Canonical member order — readability

Inside a component: inputs/props → lifecycle → getters/setters → general functions → event
callbacks → render; alphabetical within each section, separated by a standard divider.

## FE.5 Design tokens and styling API — C11

No hardcoded colours, spacing, radii, font sizes or families in component styles; only tokens
(`--<prefix>-*`). Components expose their themeable values as CSS custom properties. Class names
follow BEM (`block__element--modifier`). Light and dark (and high-contrast, if offered) themes are
token swaps, not per-component overrides.

## FE.6 Responsive by default — C11

Mobile-first. Named breakpoints shared between styles and scripts (one source of truth). Fluid
layout: relative units, `minmax`/`clamp`, no fixed-width containers, no page-level horizontal
scroll at ≥ 320 px. Reusable components respond to their container (container queries). Controls
degrade label+icon → icon with accessible name → overflow menu; never clip or overlap. Touch
targets ≥ 44 px. Reflow at 400 % zoom; both orientations; safe-area insets; motion gated behind
`prefers-reduced-motion`.

## FE.7 Accessibility is tested at two tiers — C6, C11

Component tier: rendered component + automated a11y scan with zero violations, through a helper
that fails if the component never rendered (no vacuous passes). Route tier: real browser for
contrast, focus landing and live-region announcements. Native semantic elements over ARIA roles.

## FE.8 Performance — C5

Lists that can exceed ~50 items are virtualised. Features load lazily; the shell loads only what
the first view needs. Below-the-fold media is lazy; media declares intrinsic aspect ratio.

## FE.9 Public API per feature — C2

Each feature exposes one public entry (DTOs, facade interfaces, event types, component tags).
No barrel files inside features. Components consume DTOs mapped from domain objects, never raw
domain objects.

## FE.10 Visual verification — C7

A change to a component's markup or styles is not done until it was rendered in a real browser at
narrow, medium and wide widths and compared with the design reference. Screenshots are scratch
output (gitignored dir), deleted afterwards. Design references are read-only; when a deliberate
product change supersedes a reference, say so instead of bending the code back.

## FE.11 Documentation in code — C8

Public exports, component inputs and events carry doc comments (contract + why). Comments explain
why, never what; one line each.

## FE.12 Strict import order — readability

External (framework first) → internal features → shared → siblings. Enforced by lint.
