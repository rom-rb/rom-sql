require 'rom/sql/types'

RSpec.describe 'ROM::SQL::Types', :postgres do
  describe 'ROM::SQL::Types::Serial' do
    it 'accepts ints > 0' do
      expect(ROM::SQL::Types::Serial[1]).to be(1)
    end

    it 'raises when input is <= 0' do
      expect { ROM::SQL::Types::Serial[0] }.to raise_error(Dry::Types::ConstraintError)
    end
  end
end
