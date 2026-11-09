RSpec.describe Parakey::Locks::Index do
  let(:result) { described_class.new.call(**args) }

  let(:args) { { skip:, take: 2 } }

  let(:skip) { 0 }

  context 'with valid arguments', vcr: { cassette_name: 'locks/index/first_page' } do
    it_behaves_like 'successful call', value_containing: -> {
      contain_exactly(
        a_hash_including(
          external_id: 'lock-1',
          name: 'Flat 1',
          status: 'online',
          charge: 100,
          keys: [a_hash_including(external_id: 'access-lock-1')]
        ),
        a_hash_including(
          external_id: 'lock-2',
          name: 'Front door',
          status: 'online',
          charge: 50,
          keys: [a_hash_including(external_id: 'access-lock-2')]
        )
      )
    }

    context 'with a skip of one page', vcr: { cassette_name: 'locks/index/second_page' } do
      let(:skip) { 2 }

      it_behaves_like 'successful call', value_containing: -> {
        contain_exactly(
          a_hash_including(
            external_id: 'lock-3',
            name: 'Side entrance',
            status: 'online',
            charge: 75,
            keys: [a_hash_including(external_id: 'access-lock-3')]
          )
        )
      }
    end
  end
end
