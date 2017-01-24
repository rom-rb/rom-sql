RSpec.describe 'ROM::SQL::Types' do
  describe 'ROM::SQL::Types::SQLite::Object' do
    let(:type) { ROM::SQL::Types::SQLite::Object }

    it 'passes an object of any type' do
      [Object.new, 1, true, BasicObject.new].each do |obj|
        expect(type[obj]).to be obj
      end
    end
  end
end
