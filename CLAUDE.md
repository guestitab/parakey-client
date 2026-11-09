# Repository Guidelines

`parakey-client` (module `Parakey`, `require 'parakey'`) is a host-agnostic Ruby client for the Parakey API,
extracted from Guestit's app and published on RubyGems. It has no Rails dependency; the host injects the
access token and the domain id via `Parakey.configure`. README is the public guide and holds the release steps.

## Project Structure

- `lib/parakey.rb` — entry point: requires, and the `Parakey.configure`/`Parakey.config` accessors.
- `lib/parakey/client.rb` — the module-level wire API: `Parakey.connection`, `Parakey.request`, the retry policy,
  the `Access-Token` auth header and the `ApiError` wrap.
- `lib/parakey/config.rb` — injected `access_token`, `domain_id`, `base_url`, `timeout`.
- `lib/parakey/operation.rb` — the monadic base (`#call` returns a Result, `#call!` unwraps/raises).
- `lib/parakey/<resource>/<action>.rb` — one operation per file, namespaced `Parakey::<Resource>::<Action>`.
- `spec/` — RSpec + VCR; cassettes in `spec/fixtures/cassettes`.

## Boundary

- Domain mapping and persistence stay in the host: it translates grants, locks and events onto its own models,
  which is host vocabulary. The gem speaks wire vocabulary plus its own normalized constants (`Parakey::AccessGrants::KIND_*`,
  `STATUS_*`).
- Credentials stay in the host: the access token, the domain id and the webhook key are injected or read from the
  host's own store. The webhook token check lives in the host's controller.
- Error reporting stays in the host: an operation returns `Failure(error)`; the host's operation wrapper decides
  what to report.

## Build, Test, and Development Commands

- Setup: `bundle install`.
- Test: `bundle exec rspec` (offline, VCR-backed) or `bundle exec rake` (spec + rubocop).
- Lint: `bundle exec rubocop` (or `-A` to autocorrect — review every change).

## Coding Style & Conventions

- Ruby: 2-space indent; `snake_case` methods/vars; `CamelCase` classes.
- Operations: `Parakey::<Resource>::<Action>`, `include Parakey::Operation`, `def call(...)`, return
  `Dry::Monads::Result`, invoke with a fresh instance (`Op.new.call(...)` / `Op.new.call!(...)`).
- Validate arguments up front with `argument!` (e.g. `argument! access_id: :required`), one guard per line, before
  any network call.
- Keep all HTTP and response normalization in `Parakey`'s module functions and the operations; never leak wire
  decisions past the operation boundary.
- No `Rails`, no app constants — the gem stays framework-free (host injects config). ActiveSupport core extensions
  are fine.
- Parakey behaviour notes live in the `parakey` skill (`.agents/skills/parakey`); read it before changing
  endpoints, pagination or event handling.

## Testing Guidelines

- Stack: RSpec + VCR + WebMock, offline against recorded cassettes. A cassette folder keeps the wire name:
  `access_keys/` for `AccessGrants`.
- An operation spec sets `let(:result) { described_class.new.call(**args) }` and asserts through the
  `successful call` (`value:` or `value_containing:`) and `failed call` (`failure_class:`, optional `let(:message)`)
  shared examples.
- Configure `Parakey` in the `spec_helper` `before` hook with the cassette-matching test credentials
  (`[PARAKEY_TOKEN]`, `[PARAKEY_DOMAIN_ID]`).
- Mirror the source tree: `spec/parakey/<resource>/<action>_spec.rb`.
- This repo is public: scrub real emails, names and unit identifiers from a cassette before committing it.

## Commit & Pull Request Guidelines

- Commits: short, imperative subject with a conventional prefix: `feat:`, `fix:`, `chore:`, `dev:`, `misc:`,
  `test:`, `docs:`. Use scoped subjects when useful (e.g., `feat(access-grants): …`).
- PRs: clear description, linked issues, and a brief test plan. Ensure `bundle exec rake` passes.
- `staging` is the default branch; `production` tracks released gems.
