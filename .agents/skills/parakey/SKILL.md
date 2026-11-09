---
name: parakey
description: "Parakey API behaviour: auth, paging, filters, retries, access keys, devices and events. Load before changing an endpoint, pagination or event handling, and before a live Parakey call or a cassette."
---

# Parakey

Parakey is an access-control API: locks (devices), reusable keys (accesses), grants (access keys) and members, with
unlock events delivered by webhook. This gem is its wire client; the host app maps the results onto its own models.

## Calls and credentials

- Auth is one static token per account sent as the `Access-Token` header; there is no OAuth minting and no token
  store. A token reaches a live account: a call with real credentials reads and writes real keys.
- Every list call scopes by `domainId` and pages 1-based with `page` and `limit`; the gem operations take
  `skip`/`take` and derive the page (`skip.div(take) + 1`).
- Filterable parameters take `field=a,b`, `field[gte]=`, `field[ne]=`, a nested `field[in]=...` list (sent as
  `deviceIds: { in: [...] }` in the gem) and `orderBy=<field>:asc|desc`.
- The endpoint reference is the apiDoc bundle `https://api-doc.parakey.co/assets/main.bundle.js` (search
  `url:"/event-logs"`); there is no rendered reference doc.
- A write never retries on a response status; a read retries 429/502/503/504 with backoff, and a connection-level
  failure retries on reads only — `POST /access-keys` has no provider idempotency key. After a failed write,
  `Parakey::ApiError#unapplied?` (a 4xx other than 408/409) means it did not land and a retry is safe; anything
  else leaves delivery unknown.

## Access keys, accesses, devices

- Parakey upserts an access key by access, user and window: re-creating an identical grant resolves to the existing
  key. Before deleting a key, check that no other active grant on the host owns it, or the delete strands that
  grant.
- A key with both `startDate` and `expirationDate` is time-controlled (`tca`); any other is permanent (`regular`).
  Creating a time-controlled key without the window, or a permanent one with one, is refused before the wire.
- Deletes accept a 404: the key or member is gone either way.
- `Locks::Index` joins `GET /devices` with `GET /accesses` filtered by `deviceIds[in]`, batched 500 at a time. The
  wire reports no device status; a listed device reads as online. `batteryStatus` maps `high`/`medium`/`low`/
  `veryLow` to 100/75/50/25 percent.
- `GET /accesses` is always filtered to `allowedOrigins=api` and `enabled=true`: portal-created or disabled keys
  never reach the host.

## Events

- Parakey POSTs one event-log item to `/webhooks/parakey/event?token=<webhook_key>`. `Normalize` maps `activity`
  to `event_type` (the maintenance activities `calibrate`, `dfu` and `setTime` become `synced`), `timestamp` to
  `occurred_at`, and keeps the raw item under `metadata[:payload]`.
- A webhook delivery gets six attempts over about five hours and is then dropped, and Parakey switches a webhook
  off after 10 failures in five days or 100 in a day. Recover dropped events from `GET /event-logs`
  (`Accept-Version: 2.0`), polling by `createdAt` — the time the log reached Parakey; `timestamp` is the unlock
  itself, which offline phones upload days late. No event-logs operation exists in the gem yet; add one to
  `parakey-client` when a recovery flow needs it.
