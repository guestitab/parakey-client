require 'parakey'
require 'vcr'
require 'webmock/rspec'
require 'active_support/testing/time_helpers'

Dir[File.expand_path('support/**/*.rb', __dir__)].each { |file| require file }

# The time zone the cassettes were recorded in, so Time.zone.local builds the same instants.
Time.zone = 'Europe/Stockholm'

# Fake real-looking credentials, filtered into the cassettes' placeholders
# (ported from core's spec/support/vcr.rb, where the account's access token and
# domain id were scrubbed to [PARAKEY_TOKEN] and [PARAKEY_DOMAIN_ID]).
PARAKEY_TEST_CREDENTIALS = {
  access_token: 'test-access-token',
  domain_id: 'test-domain-id'
}.freeze

VCR.configure do |config|
  config.cassette_library_dir = File.expand_path('fixtures/cassettes', __dir__)
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.default_cassette_options = {
    allow_unused_http_interactions: false,
    match_requests_on: %i[method uri body]
  }

  # VCR replays buffered bodies, so recorded chunked-transfer framing no longer applies.
  config.before_playback do |interaction|
    interaction.response.headers.delete_if { |header,| header.casecmp?('Transfer-Encoding') }
  end

  config.filter_sensitive_data('[PARAKEY_TOKEN]') { PARAKEY_TEST_CREDENTIALS[:access_token] }
  config.filter_sensitive_data('[PARAKEY_DOMAIN_ID]') { PARAKEY_TEST_CREDENTIALS[:domain_id] }
end

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :expect }
  config.disable_monkey_patching!
  config.include ActiveSupport::Testing::TimeHelpers
  config.include Dry::Monads[:result]

  config.before do
    Parakey.configure do |parakey|
      parakey.access_token = PARAKEY_TEST_CREDENTIALS[:access_token]
      parakey.domain_id = PARAKEY_TEST_CREDENTIALS[:domain_id]
    end
  end
end
