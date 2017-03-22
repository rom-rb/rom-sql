RSpec.describe ROM::Relation, '#qualified' do
  subject(:relation) { relations[:users] }

  include_context 'users and tasks'

  with_adapters do
    it 'qualifies all attributes' do
      qualified = relation.qualified

      expect(qualified.schema.all?(&:qualified)).to be(true)
    end

    it 'qualifies virtual attributes' do
      qualified = relation.
                    left_join(:tasks, tasks[:user_id].qualified => relation[:id].qualified).
                    select(:id, tasks[:id].func { int::count(id).as(:count) }).
                    qualified.
                    group(:id)

      expect(qualified.schema.all?(&:qualified)).to be(true)

      expect(qualified.to_a).to eql([{ id: 1, count: 1 }, { id: 2, count: 1 }])
    end
  end
end
