RSpec.describe Parakey::AccessGrants::Create do
  let(:result) { described_class.new.call(**args) }

  let(:args) { { attributes: } }

  let(:attributes) { { kind:, access_id:, recipient_email:, start_date:, end_date: } }
  let(:access_id) { 'hJ7Jt5aPIL' }
  let(:recipient_email) { 'codex-stargate-parakey-provider-success@example.com' }
  let(:kind) { 'regular' }
  let(:start_date) { nil }
  let(:end_date) { nil }

  context 'with valid arguments', vcr: { cassette_name: 'access_keys/create' } do
    it_behaves_like 'successful call', value_containing: -> {
      a_hash_including(
        external_id: 'G8qgAQSP9s',
        metadata: a_hash_including(
          raw: a_hash_including(
            id: 'G8qgAQSP9s',
            user: a_hash_including(email: recipient_email)
          )
        )
      )
    }
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
    context 'when a regular grant has dates' do
      let(:start_date) { Time.zone.local(2026, 11, 1, 12) }
      let(:message) { 'A validity window is only supported for time-controlled grants.' }

      before { result }

      it_behaves_like 'failed call', failure_class: Parakey::ArgumentError
    end

    context 'when a time-controlled grant has no dates' do
      let(:kind) { 'tca' }
      let(:message) { 'Start date and end date are both required.' }

      before { result }

      it_behaves_like 'failed call', failure_class: Parakey::ArgumentError
    end

    context 'when a time-controlled grant ends before it starts' do
      let(:kind) { 'tca' }
      let(:start_date) { Time.zone.local(2026, 11, 2, 12) }
      let(:end_date) { Time.zone.local(2026, 11, 1, 12) }
      let(:message) { 'End date must be after start date.' }

      before { result }

      it_behaves_like 'failed call', failure_class: Parakey::ArgumentError
    end

    context 'when the access_id is blank' do
      let(:access_id) { nil }
      let(:message) { 'Access ID is required.' }

      it_behaves_like 'failed call', failure_class: Parakey::ArgumentError
    end

    context 'when the recipient_email is blank' do
      let(:recipient_email) { nil }
      let(:message) { 'Recipient email is required.' }

      it_behaves_like 'failed call', failure_class: Parakey::ArgumentError
    end
  end
end
