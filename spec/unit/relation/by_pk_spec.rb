RSpec.describe ROM::Relation, '#by_pk' do
  include_context 'users and tasks'

  with_adapters do
    context 'with a single PK' do
      subject(:relation) { relations[:users] }

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

    context 'with a composite PK' do
      subject(:relation) { relations[:task_tags] }

      it 'restricts a relation by is PK' do
        expect(relation.by_pk(1, 1).to_a).to eql([{ tag_id: 1, task_id: 1 }])
      end
    end
  end
end
