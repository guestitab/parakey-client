RSpec.describe Parakey do
  describe '.request' do
    let(:endpoint) { 'https://api.parakey.co/devices' }

    context 'when Parakey answers' do
      before do
        stub_request(:get, /devices/)
          .to_return(status: 200, body: { items: [{ id: 'lock-1' }] }.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns the parsed body' do
        expect(described_class.request(:get, 'devices', params: { domainId: 'test-domain-id' })).to eq(items: [{ id: 'lock-1' }])
      end

      it 'authenticates with the access token' do
        described_class.request(:get, 'devices')

        expect(WebMock).to have_requested(:get, endpoint).with(headers: { 'Access-Token' => 'test-access-token' })
      end
    end

    context 'when Parakey refuses the request' do
      before do
        stub_request(:get, endpoint)
          .to_return(status: 422, body: { message: 'invalid recipient' }.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'raises an ApiError carrying the status and the wire message' do
        expect { described_class.request(:get, 'devices') }
          .to raise_error(Parakey::ApiError, 'invalid recipient') { |error| expect(error.status).to eq(422) }
      end
    end

    context 'when Parakey glitches on a read' do
      let(:refusal) { { status: 503, body: '', headers: { 'Content-Type' => 'application/json' } } }

      before do
        stub_request(:get, endpoint).to_return(refusal, refusal, { status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' } })
      end

      it 'retries the request' do
        expect(described_class.request(:get, 'devices')).to eq({})
        expect(WebMock).to have_requested(:get, endpoint).times(3)
      end
    end

    context 'when Parakey glitches on a write' do
      before do
        stub_request(:post, /access-keys/)
          .to_return(status: 503, body: '', headers: { 'Content-Type' => 'application/json' })
      end

      it 'does not retry the write' do
        expect { described_class.request(:post, 'access-keys', params: { access: { id: 'a1' } }) }
          .to raise_error(Parakey::ApiError)
        expect(WebMock).to have_requested(:post, 'https://api.parakey.co/access-keys').once
      end
    end

    context 'without an access token' do
      before { described_class.config.access_token = nil }

      it 'refuses the call' do
        expect { described_class.request(:get, 'devices') }.to raise_error(Parakey::Error, 'Parakey access token is required.')
      end
    end
  end

  describe Parakey::ApiError do
    def api_error(status)
      Parakey::ApiError.new('nope', status:)
    end

    describe '#unapplied?' do
      it 'holds for a refusal that proves the write never took' do
        expect(api_error(400).unapplied?).to be(true)
        expect(api_error(422).unapplied?).to be(true)
      end

      it 'leaves a timeout, a conflict and a server error unknown' do
        expect(api_error(408).unapplied?).to be(false)
        expect(api_error(409).unapplied?).to be(false)
        expect(api_error(500).unapplied?).to be(false)
      end
    end
  end
end
