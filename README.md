# parakey-client

A Ruby client for the [Parakey API](https://api.parakey.co/). Each endpoint is one operation class that returns a
[dry-monads](https://dry-rb.org/gems/dry-monads/) `Result`. The gem handles authentication, retries and response
normalization. It does not depend on Rails, only on ActiveSupport and Faraday. Your app supplies the access token
and the domain id.

[Guestit](https://guestit.se) built it and runs it in production.

Requires Ruby 4.0 or later.

## Installation

```ruby
# Gemfile
gem 'parakey-client'
```

Bundler loads it for you. Outside Bundler, `require 'parakey'`.

## Configuration

```ruby
Parakey.configure do |config|
  config.access_token = ENV.fetch('PARAKEY_ACCESS_TOKEN')
  config.domain_id    = ENV.fetch('PARAKEY_DOMAIN_ID')
end
```

| Setting | Default | What it does |
| --- | --- | --- |
| `access_token` | `nil` | The account's static API token, sent as the `Access-Token` header. Parakey issues one per account; there is no OAuth minting and no token store. |
| `domain_id` | `nil` | The domain every list and member call scopes to (the `domainId` parameter). |
| `base_url` | `https://api.parakey.co/` | API root. |
| `timeout` | `nil` | Faraday request timeout in seconds. |

## Usage

Operations live under `Parakey::<Resource>::<Action>`. Build a fresh instance for every call:

```ruby
result = Parakey::AccessGrants::Index.new.call(skip: 0, take: 100)

if result.success?
  result.value!   # => [{ external_id: 'f163gXNFWc', recipient_email: '...', kind: 'regular', ... }]
else
  result.failure  # => a Parakey::Error or a Faraday::Error
end
```

`call` never raises. It returns `Success(value)` or `Failure(error)`. `call!` returns the `Success` and raises the
error where `call` would return a `Failure`. Response bodies come back as hashes with symbol keys.

The gem covers access grants (create, delete, index), accesses (`Keys::Index`), devices (`Locks::Index`, joining
the accesses that reach each device), members (index, destroy) and access events (`AccessEvents::Normalize`, which
maps one event-log item or webhook delivery to plain attributes). [CHANGELOG.md](CHANGELOG.md) lists every
operation.

### Grants, keys and locks

An access key (a grant) points at an access (a reusable key) and a user. A key with both `startDate` and
`expirationDate` is time-controlled (`kind: 'tca'`); any other is permanent (`kind: 'regular'`). Creating a
time-controlled grant without the window, or a permanent one with one, is refused before any request:

```ruby
Parakey::AccessGrants::Create.new.call(
  attributes: {
    access_id: 'hJ7Jt5aPIL',
    recipient_email: 'guest@example.com',
    kind: 'tca',
    start_date: Time.utc(2026, 11, 10),
    end_date: Time.utc(2026, 11, 12)
  }
)
```

Parakey upserts an access key by access, user and window: re-creating an identical grant resolves to the existing
key. Deletes answer 404 for an already-missing key or member, which the gem reads as success.

Lists page 1-based with `page` and `limit` on the wire; the operations take `skip` and `take` and derive the page.
`Keys::Index` is always filtered to API-enabled accesses; `Locks::Index` reports `batteryStatus` as a percentage
(`high`/`medium`/`low`/`veryLow` → 100/75/50/25).

### Errors

| Class | Raised when |
| --- | --- |
| `Parakey::ArgumentError` | The arguments are unusable. Raised before any request, with a message the host can show as it is. |
| `Parakey::ApiError` | Parakey answered with an error status. `#status` holds the HTTP status. |
| `Parakey::Error` | The parent of the two above, also raised when no access token is configured. |

### Retries and delivery

Reads retry 429/502/503/504 and connection-level failures with backoff. A write never retries on a status, and a
connection-level failure retries on reads only — `POST /access-keys` has no provider idempotency key. After a
failed write:

```ruby
error.is_a?(Parakey::ApiError) && error.unapplied? # the write certainly did not take, so a retry is safe
```

Anything else (a server error, a timeout after the request left) leaves delivery unknown: read back before
retrying.

### Webhooks

Parakey POSTs event-log items to your webhook URL with the account's webhook key in the `?token=` query parameter.
Verify it in your app (a `secure_compare` against your stored key), then normalize the payload:

```ruby
Parakey::AccessEvents::Normalize.new.call(item: params)
# => Success({ external_id:, event_type:, occurred_at:, grant_external_id:, provider_lock_id:, access_id:, metadata: })
```

A delivery gets six attempts over about five hours and is then dropped, and Parakey disables a webhook after 10
failures in five days or 100 in a day. Dropped events can be recovered from `GET /event-logs`
(`Accept-Version: 2.0`), polling by `createdAt`.

## Type signatures

The gem ships RBS for its public API in `sig/parakey.rbs`. `rbs collection install` picks it up from your
`Gemfile.lock`, so Steep sees it with no extra setup.

## Development

```sh
bundle install
bundle exec rake        # specs and RuboCop
bundle exec rspec       # specs only
bundle exec rubocop -A  # autocorrect; review every change
```

The specs run offline against recorded VCR cassettes in `spec/fixtures/cassettes`. Recording a new cassette needs
live credentials for a Parakey account. Scrub the token, the domain id (the spec_helper filters handle both) and
any real emails, names or unit identifiers from the cassette before you commit it — this repo is public.

## Releasing

1. Bump `Parakey::VERSION` in `lib/parakey/version.rb` and move the `Unreleased` notes in `CHANGELOG.md` under the
   new version.
2. Commit on `staging` and run `bundle exec rake`.
3. Run `gem signin` once per machine. The gem requires MFA, so every push asks for a one-time code.
4. Run `bundle exec rake release`. It builds `pkg/parakey-client-<version>.gem`, tags `v<version>`, pushes the
   branch and the tag, and pushes the gem to RubyGems.
5. Fast-forward `production` to the release tag.

## License

MIT. See [LICENSE](LICENSE).
