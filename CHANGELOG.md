# Changelog

## [Unreleased]

### Changed

- `Parakey::ArgumentError` messages are sentences the host can show as they are ("Access ID is required.") in
  place of `key: reason` pairs.

## [0.1.0] - 2026-11-10

First release as `parakey-client`, extracted from the Parakey integration Guestit runs in production. The specs are
that integration's provider specs, ported with their recorded VCR cassettes (scrubbed of emails, names and unit
identifiers — this repo is public).

### Added

- `Parakey.configure` for the access token, the domain id, the base URL and the request timeout. No Rails
  dependency.
- Wire API on the `Parakey` module: `connection` and `request` with the retry policy (reads retry 429/502/503/504
  and connection-level failures; a write never retries), the `Access-Token` auth header and the `ApiError` wrap with
  `#unapplied?` delivery classification.
- `sig/parakey.rbs` declaring the public API.
- Operations, each returning a dry-monads `Result`:
  - Access grants: `Create` (regular and time-controlled windows), `Delete` and `Index`, sharing the
    `Parakey::AccessGrants` kind and status vocabulary.
  - `Keys::Index` for the API-enabled accesses, `Locks::Index` for the devices joined with their accesses and
    battery charge.
  - Members: `Index` with wire filters and `Destroy` by email.
  - `AccessEvents::Normalize` for event-log items and webhook deliveries.

[Unreleased]: https://github.com/guestitab/parakey-client/compare/v0.1.0...staging
[0.1.0]: https://github.com/guestitab/parakey-client/releases/tag/v0.1.0
