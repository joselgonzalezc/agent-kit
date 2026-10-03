# Profile: offline-first with background sync

Optional rule set for clients that keep a local database and reconcile with a backend. Lessons
distilled from a local-first app syncing IndexedDB with a self-hosted backend; storage-neutral.

## OS.1 Local first — C3, C14

Every write lands in the local store first and the UI reflects it immediately (optimistic). Sync is
asynchronous and decoupled through a durable outbound queue. No user interaction ever blocks on the
network.

## OS.2 Sync engine isolation — C2, C3

All reconciliation logic lives in one sync feature that exposes commands and emits events. Nothing
else imports its internals; no other layer talks to the backend for synced entities.

## OS.3 Conflict strategy is explicit and enforced on both paths — C14

Each synced entity has a declared conflict strategy (e.g. last-write-wins on a monotonic stamp,
local-wins, remote-wins, manual). It is applied on pull **and** on push. The server rejects writes
whose stamp is older than the stored one, so a server stamp never regresses; equal stamps are
accepted so replays are idempotent. Manual conflicts are persisted and reviewable.

## OS.4 Tolerant inbound, strict outbound — C4, C14

Inbound parsing (pull, import, restore) accepts older shapes: unknown fields are stripped, newly
added fields default. A row is never rejected for missing a field that was added later. Outbound
payloads are strict and complete.

## OS.5 Absence is never inferred from failure — C14

A failed or timed-out fetch is not "the server has nothing". Adoption, first-sync overwrite and
deletion decisions require a confirmed result.

## OS.6 Owner scoping — C10

In multi-user backends every synced record carries an owner; access rules restrict list/view/
update/delete to the owner and prevent reassigning ownership from the client. Enforced as
row-level security on the backend (BE.17), never only by client-side filtering.

## OS.7 Separate device, account and never-leaves data — C10, C14

Settings and state are partitioned structurally: device-local (never synced), account-scoped
(synced), and secrets (never synced, never backed up). Secrets are unreachable from the sync and
backup paths by construction, not by convention.

## OS.8 Bulk paths share the queue — C14

Import and restore go through the same queue and conflict strategy as ordinary edits; they never
write around it.
