require 'fizzbuzz'

RSpec.describe Fizzbuzz do
  it 'fizz buzzes' do
    expect(Fizzbuzz::fizzbuzz(3)).to eq("fizz")
    expect(Fizzbuzz::fizzbuzz(5)).to eq("buzz")
    expect(Fizzbuzz::fizzbuzz(15)).to eq("fizzbuzz")
  end
end
