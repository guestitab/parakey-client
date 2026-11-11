RSpec.describe Parakey::AccessGrants::Index do
  let(:result) { described_class.new.call(**args) }

  let(:args) { { take: 5 } }

  context 'with valid arguments', vcr: { cassette_name: 'access_keys/index' } do
    it_behaves_like 'successful call', value_containing: -> {
      include(
        {
          external_id: 'f163gXNFWc',
          label: nil,
          recipient_email: 'test.user.0@example.com',
          recipient_name: 'Test User 0',
          status: 'active',
          kind: 'regular',
          access_id: 'RyzEm42xit',
          start_date: '2024-03-30T17:20:54.821Z',
          end_date: nil
        },
        {
          external_id: 'w4BeLWBfrU',
          label: nil,
          recipient_email: 'test.user.1@example.com',
          recipient_name: 'Test User 1',
          status: 'active',
          kind: 'tca',
          access_id: 'LVAPp9DTHW',
          start_date: '2025-05-08T08:51:01.908Z',
          end_date: '2028-05-08T08:50:24.111Z'
        }
      )
    }
  end

  context 'with invalid arguments' do
    context 'when take is not positive' do
      let(:args) { { take: 0 } }
      let(:message) { 'Take must be a positive number.' }

      it_behaves_like 'failed call', failure_class: Parakey::ArgumentError
    end
  end
end
