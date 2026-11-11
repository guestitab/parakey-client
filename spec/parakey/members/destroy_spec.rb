RSpec.describe Parakey::Members::Destroy do
  let(:result) { described_class.new.call(**args) }

  let(:args) { { email: } }

  let(:email) { 'test.member@example.com' }

  context 'with valid arguments', vcr: { cassette_name: 'members/destroy' } do
    it_behaves_like 'successful call', value: true

    context 'when the remote member is already missing', vcr: { cassette_name: 'members/destroy/missing' } do
      let(:email) { 'codex-stargate-parakey-member-missing@example.com' }

      it_behaves_like 'successful call', value: true
    end
  end

  context 'with invalid arguments' do
    context 'when the email is blank' do
      let(:email) { nil }
      let(:message) { 'Email is required.' }

      it_behaves_like 'failed call', failure_class: Parakey::ArgumentError
    end

    context 'when the domain_id is blank' do
      let(:message) { 'Domain ID is required.' }

      before { Parakey.config.domain_id = nil }

      it_behaves_like 'failed call', failure_class: Parakey::ArgumentError
    end
  end
end
