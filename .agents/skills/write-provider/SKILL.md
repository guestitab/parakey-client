---
name: write-provider
description: "Add or change a Parakey endpoint: the wire operation in the parakey-client gem, with VCR or WebMock specs."
---

# Write provider

## Choose where the change goes

- Wire calls, request shapes, retries, auth and response normalization live in this gem as
  `Parakey::<Resource>::<Action>`. Domain mapping, persistence, imports, jobs and the webhook controller live in
  the host app. A new or changed endpoint is a gem change; a new use of an existing endpoint is a host change.
- Load the `parakey` skill for the API behaviour facts before changing endpoints, pagination or event handling.

## Gem operation

```ruby
module Parakey
  module AccessGrants
    class Create
      include Parakey::Operation

      # @rbs (attributes: ::Hash[::Symbol, untyped]) -> Dry::Monads::Result[::Hash[::Symbol, untyped]]
      def call(attributes:)
        argument! 'Access ID is required.' if attributes[:access_id].blank?

        body = Parakey.request(:post, 'access-keys', params: payload(attributes))

        Success(external_id: body.fetch(:id), metadata: { raw: body })
      end
    end
  end
end
```

- `#call` returns a `Dry::Monads::Result` and never raises; `#call!` unwraps and raises. Invoke with a fresh
  instance: `Op.new.call(...)` / `Op.new.call!(...)`.
- Validate arguments up front with `argument!`, one guard per line, before any network call. A refusal is a
  sentence the host can show as it is.
- `Parakey.request` owns the Faraday connection, retries, the `Access-Token` header and the `ApiError` wrap; an
  operation never builds its own client. A delete that tolerates a missing record passes
  `accepted_statuses: [404]`. A list operation takes `skip:` and `take:` and passes `page_params(skip, take)`, which
  refuses a non-positive `take` and builds `domainId`, `limit` and the 1-based `page`.
- Normalize the response inside the operation (snake_case keys; kinds and statuses from the
  `Parakey::AccessGrants` constants) so the host reads one shape. The two deliberate exceptions are
  `Members::Index`, which returns the raw wire items, and `AccessEvents::Normalize`, which keeps the raw item
  under `metadata[:payload]`.
- A non-idempotent write sends once: the retry middleware retries only `get` and `delete`. After a failed write, `ApiError#unapplied?` separates "did not land"
  from "delivery unknown" — the host records an explicit state and reconciles by exact provider identity before
  retrying.
- Declare the public API in `sig/parakey.rbs`.

## Spec

```ruby
RSpec.describe Parakey::AccessGrants::Create do
  let(:result) { described_class.new.call(**args) }

  let(:args) { { attributes: } }
  let(:attributes) { { kind: 'regular', access_id:, recipient_email:, start_date: nil, end_date: nil } }

  context 'with valid arguments', vcr: { cassette_name: 'access_keys/create' } do
    it_behaves_like 'successful call', value_containing: -> { a_hash_including(external_id: 'G8qgAQSP9s') }
  end

  context 'when the connection fails during creation' do
    let(:endpoint) { 'https://api.parakey.co/access-keys' }
    let(:message) { 'creation connection failed' }

    before do
      stub_request(:post, endpoint).to_raise(Faraday::ConnectionFailed.new(message))

      result
    end

    it_behaves_like 'failed call', failure_class: Faraday::ConnectionFailed

    it 'does not retry the access-key creation' do
      expect(WebMock).to have_requested(:post, endpoint).once
    end
  end

  context 'with invalid arguments' do
    context 'when the access_id is blank' do
      let(:attributes) { super().merge(access_id: nil) }
      let(:message) { 'Access ID is required.' }

      it_behaves_like 'failed call', failure_class: Parakey::ArgumentError
    end
  end
end
```

- Stack: RSpec + VCR + WebMock, offline. Mirror the source tree: `spec/parakey/<resource>/<action>_spec.rb`,
  cassettes in `spec/fixtures/cassettes/<wire-name>/...` (the cassette keeps the wire path's name, e.g.
  `access_keys/` for `AccessGrants`).
- Cover blank-argument refusals, the happy path against a cassette or an exact WebMock stub (status, body and
  content type mirror the transport) and the absence of retries on a write. Status refusals and `unapplied?` are
  covered once in `spec/parakey_spec.rb`; an operation spec does not repeat them.
- Cassette recording makes live Parakey calls and needs the owner's go-ahead first. An unmatched
  VCR interaction is evidence of request drift until a comparison of method, path, query, body and response
  envelope explains it. After authorized recording, keep only the interactions the spec uses; the `spec_helper`
  filters replace the token and domain id with `[PARAKEY_TOKEN]` / `[PARAKEY_DOMAIN_ID]`, and scrub any real
  emails, names or unit identifiers from the cassette before committing — this repo is public.

## Verify

```bash
bundle exec rspec spec/parakey/<resource>/<action>_spec.rb
bundle exec rake   # spec + rubocop
```
