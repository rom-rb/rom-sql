RSpec.describe ROM::Relation, '#by_pk' do
  subject(:relation) { relations[:users] }

  include_context 'users and tasks'

  with_adapters do
    it 'restricts a relation by its PK' do
      expect(relation.by_pk(1).to_a).to eql([id: 1, name: 'Jane'])
    end

    it 'is available as a view' do
      expect(relation.by_pk).to be_curried
    end

    it 'qualifies pk attr' do
      expect(relation.qualified.by_pk(1).select(:id).join(:tasks, user_id: :id).one).to eql(id: 1)
    end
  end
end
