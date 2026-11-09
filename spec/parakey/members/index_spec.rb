RSpec.describe Parakey::Members::Index do
  let(:result) { described_class.new.call(**args) }

  let(:args) { { filters: { status: 'emailProblem' } } }

  context 'with valid arguments', vcr: { cassette_name: 'members/index/email_problem' } do
    it_behaves_like 'successful call', value_containing: -> {
      [
        hash_including(
          name: 'Test broken',
          user: hash_including(name: 'Test broken', email: 'broken@example.example'),
          invitation: hash_including(rejectReason: 'No MX for example.example, lookup example.example. on 172.17.0.1:53: no such host')
        )
      ]
    }
  end
end
