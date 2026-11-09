RSpec.describe Parakey::Keys::Index do
  let(:result) { described_class.new.call(**args) }

  let(:args) { { skip:, take: 2 } }

  let(:skip) { 0 }
  let(:page) { 1 }
  let(:items) do
    [
      { id: 'access-lock-1', name: 'Flat 1', devices: [{ id: 'lock-1', name: 'lgh 1608' }] },
      { id: 'access-lock-2', devices: [{ id: 'lock-2', name: 'Front door' }] }
    ]
  end

  before do
    allow(Parakey).to receive(:request)
      .with(:get, 'accesses', params: { domainId: 'test-domain-id', limit: 2, page:, allowedOrigins: 'api', enabled: true })
      .and_return(items:)
  end

  context 'with valid arguments' do
    it_behaves_like 'successful call', value: [
      { external_id: 'access-lock-1', name: 'Flat 1', device_ids: ['lock-1'] },
      { external_id: 'access-lock-2', device_ids: ['lock-2'] }
    ]

    context 'with a skip of one page' do
      let(:skip) { 2 }
      let(:page) { 2 }
      let(:items) { [{ id: 'access-lock-3', devices: [{ id: 'lock-3', name: 'Side entrance' }] }] }

      it_behaves_like 'successful call', value: [{ external_id: 'access-lock-3', device_ids: ['lock-3'] }]
    end
  end
end
