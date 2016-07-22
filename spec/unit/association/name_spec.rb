RSpec.describe ROM::SQL::Association::Name do
  describe '.[]' do
    it 'returns a name object from a relation name' do
      rel_name = ROM::Relation::Name[:users]
      assoc_name = ROM::SQL::Association::Name[rel_name]

      expect(assoc_name).to eql(ROM::SQL::Association::Name.new(rel_name, :users))
    end

    it 'returns a name object from a relation and a dataset symbols' do
      rel_name = ROM::Relation::Name[:users, :people]
      assoc_name = ROM::SQL::Association::Name[:users, :people]

      expect(assoc_name).to eql(ROM::SQL::Association::Name.new(rel_name, :people))
    end

    it 'returns a name object from a relation and a dataset symbols and an alias' do
      rel_name = ROM::Relation::Name[:users, :people]
      assoc_name = ROM::SQL::Association::Name[:users, :people, :author]

      expect(assoc_name).to eql(ROM::SQL::Association::Name.new(rel_name, :author))
    end

    it 'caches names' do
      name = ROM::SQL::Association::Name[:users]

      expect(name).to be(ROM::SQL::Association::Name[:users])

      name = ROM::SQL::Association::Name[:users, :people]

      expect(name).to be(ROM::SQL::Association::Name[:users, :people])

      name = ROM::SQL::Association::Name[:users, :people, :author]

      expect(name).to be(ROM::SQL::Association::Name[:users, :people, :author])
    end
  end

  describe '#aliased?' do
    it 'returns true if a name has an alias' do
      expect(ROM::SQL::Association::Name[:users, :people, :author]).to be_aliased
    end

    it 'returns false if a name has no alias' do
      expect(ROM::SQL::Association::Name[:users, :people]).to_not be_aliased
    end
  end

  describe '#inspect' do
    it 'includes info about the relation name' do
      expect(ROM::SQL::Association::Name[:users].inspect).to eql(
        "ROM::SQL::Association::Name(users)"
      )
    end

    it 'includes info about the relation name and its dataset' do
      expect(ROM::SQL::Association::Name[:users, :people].inspect).to eql(
        "ROM::SQL::Association::Name(users on people)"
      )
    end

    it 'includes info about the relation name, its dataset and alias' do
      expect(ROM::SQL::Association::Name[:users, :people, :author].inspect).to eql(
        "ROM::SQL::Association::Name(users on people as author)"
      )
    end
  end
end
