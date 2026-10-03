# Profile: backend service / API

Optional rule set for a server, API or worker. Language- and framework-neutral. Copy what applies
into Part B and bind placeholders. Each rule names the core principle it implements.

## BE.1 Layered by feature — C2, C3

```
src/<feature>/
  domain/          # entities, value objects, domain errors, pure rules
  application/     # use cases (one command or query each), ports (interfaces)
  infrastructure/  # repositories, external clients, queues — implement ports
  transport/       # HTTP/RPC/CLI/consumer handlers — parse, call use case, map result
```

Handlers contain no business logic; use cases contain no transport or SQL; domain imports nothing
from infrastructure or transport.

## BE.2 Contract first — C3, C8

The API contract (OpenAPI / JSON Schema / protobuf / GraphQL SDL) is the source of truth, versioned
in the repo, and reviewed before implementation. Request/response types and docs are generated from
or validated against it. Breaking changes need a new version or a deprecation window recorded in the
roadmap.

## BE.3 Validate at the edge, typed errors inside — C4

Every input (body, query, headers, params, messages, env) is parsed into a typed command at the
transport edge; unknown fields are rejected unless the contract allows them. Domain failures are
typed errors, mapped to transport errors in one place. Error responses use one format
(e.g. RFC 9457 problem details) with a stable machine-readable code; no stack traces or internals
leak to clients.

## BE.4 Authentication and authorisation — C10

Authenticate every non-public route. Authorise per resource, server-side, on every request (object-
level checks, not just route-level); ownership and tenancy come from the verified identity, never
from client input. Least privilege for service accounts, DB users and tokens. Data-level enforcement: BE.17. Secrets come from the
environment or a secret manager, rotate, and never appear in logs.

## BE.5 Idempotency and concurrency — C14

Mutations that can be retried accept an idempotency key or are naturally idempotent (upsert by a
natural key). Concurrent updates use optimistic concurrency (version/updated-at check → 409 on
stale), never silent last-write-wins unless that is the documented strategy. Monotonic stamps never
regress.

## BE.6 Transactions and side effects — C5, C14

A use case is one transaction. External side effects (emails, webhooks, events) triggered by a write
are published through an outbox (or equivalent) so they happen if and only if the write commits.
Background jobs are idempotent, retry with exponential backoff and jitter, and dead-letter after a
bound.

## BE.7 Migrations — C14

Schema changes ship as versioned, committed migrations — never manual edits in a console. Migrations
are forward-only in production, tested against a copy of real-shaped data, and expand → migrate →
contract for breaking changes so old and new code can run side by side during a deploy.

## BE.8 Resilience at every outbound call — C5

Every network call has a timeout, a bounded retry policy only for retryable errors, and a circuit
breaker or fallback for non-critical dependencies. External responses are validated (BE.3) before
use.

## BE.9 Collections and limits — C10

List endpoints paginate (cursor preferred), cap page size, and define a stable sort. Rate limits and
payload size limits protect every public endpoint. Queries avoid N+1 patterns.

## BE.10 Observability — C7

Structured logs (JSON) with a correlation/request id propagated across calls; no secrets or personal
data in logs. Metrics for rate, errors and duration per endpoint and per dependency. Health
(liveness) and readiness endpoints. Alerts on symptoms users feel.

## BE.11 Configuration — C10

Twelve-factor: configuration from the environment, validated at startup (fail fast on missing or
invalid), one typed config object passed in — no scattered environment reads.

## BE.12 Time, money and identity — C4

Store and compute time in UTC; convert at the edge. Money in integer minor units or a decimal type,
never floats. Identifiers are opaque; never expose sequential ids where enumeration matters.

## BE.13 Testing pyramid — C6

Unit tests for domain rules and use cases with fake ports. Integration tests against real
infrastructure in containers (database, queue), not mocks of them. Contract tests for every external
API (fixtures of the real shape) and for our own API (consumer-driven or schema-validated). One
end-to-end smoke test per critical flow.

## BE.14 Security hygiene — C10

Follow the OWASP API Security Top 10: object-level and function-level authorisation, mass-assignment
protection (explicit allow-lists), SSRF protection on any URL the server fetches (allow-list hosts,
block private ranges), parameterised queries only, CORS restricted to known origins, dependency and
container image scanning in CI.

## BE.15 Data lifecycle — C14

Backups are automatic, encrypted, retained per policy and restore-tested on a schedule. Deletion
semantics (soft/hard, retention, cascade) are explicit per entity. Personal data is minimised and
exportable/deletable on request.

## BE.16 Deployability — C7

The service builds into one immutable artefact (image) promoted across environments. Deploys are
repeatable, zero-downtime where the platform allows, and reversible (previous artefact + compatible
schema). The runbook for deploy, rollback and restore lives in the docs.

## BE.17 Row-level security — C10, C14

Authorisation is enforced by the data layer itself, so a bug in a handler, a forgotten filter or a
direct API call cannot read or write another tenant's rows. Application checks (BE.4) stay as a
second layer; client-side filtering is never a control.

- **Mechanism.** Use the store's native row policies: PostgreSQL/Supabase `ENABLE ROW LEVEL
SECURITY` + `CREATE POLICY`, PocketBase collection API rules, Firestore/Firebase security rules,
  or an equivalent mandatory query scope in the repository when the store has none.
- **Default deny.** RLS is enabled on every table/collection holding user or tenant data. No policy
  means no access. Know your platform's "open" value — e.g. a PocketBase rule of `""` is public,
  `null` is superuser-only; a PostgreSQL table without `ENABLE ROW LEVEL SECURITY` ignores policies.
- **Every operation.** Separate policies for read (list/view/select), create, update and delete.
  Writes check both the existing row (`USING`) and the new row (`WITH CHECK` / body checks), so a
  client can never create a row for, or reassign a row to, another owner/tenant.
- **Identity from the verified session.** Policies key on the authenticated identity
  (`auth.uid()`, `@request.auth.id`, a per-transaction `SET LOCAL app.user_id`), never on a value
  the client sends. With connection pools, set the context per transaction, not per connection.
- **No bypass in the request path.** Request handling uses a role subject to RLS. Roles that bypass
  it (superuser, `service_role`, `BYPASSRLS`, admin tokens) are confined to migrations, operator
  tooling and audited background jobs, and those jobs scope their own queries explicitly.
- **Versioned and reviewed.** Policies live in committed migrations next to the schema they
  protect; a schema change and its policy change ship together. Any policy change is a security
  review item.
- **Tested both ways.** For each policy: the owner can perform the operation; another
  authenticated identity cannot (read returns nothing/404, write is rejected); an anonymous caller
  cannot; owner reassignment is rejected. Run against the real store (container), not a mock.
- **Indexed.** Columns used in policies (`owner_id`, `tenant_id`) are indexed; policies avoid
  per-row subqueries that turn every read into a scan.
- **Shared and derived data.** Views, functions and materialised data either run with the caller's
  rights (`security_invoker`) or re-apply the same scope; aggregates never leak row existence across
  tenants. Files/blobs follow the same ownership rules as the rows that reference them.
