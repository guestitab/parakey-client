# `value:` pins the exact value; `value_containing:` takes a matcher or a hash, or a lambda building one.
RSpec.shared_examples 'successful call' do |**expectation|
  it 'completes successfully and returns the expected data' do
    expect(result).to be_success_monad

    expected = expectation.values.first
    expected = instance_exec(&expected) if expected.is_a?(Proc)

    if expectation.key?(:value)
      expect(result.value!).to eq(expected)
    else
      expect(result.value!).to match(expected)
    end
  end
end
