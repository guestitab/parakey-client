RSpec.describe Parakey::AccessGrants::Delete do
  let(:result) { described_class.new.call(**args) }

  let(:args) { { attributes: } }

  let(:attributes) { { external_id: } }
  let(:external_id) { 'G8qgAQSP9s' }

  context 'with valid arguments', vcr: { cassette_name: 'access_keys/delete' } do
    it_behaves_like 'successful call', value: true

    context 'when the remote access key is already missing', vcr: { cassette_name: 'access_keys/delete/missing' } do
      let(:external_id) { 'NotFound00' }

      it_behaves_like 'successful call', value: true
    end
  end

  context 'with invalid arguments' do
    context 'when the external_id is blank' do
      let(:external_id) { nil }
      let(:message) { 'External ID is required.' }

      it_behaves_like 'failed call', failure_class: Parakey::ArgumentError
    end
  end
end
