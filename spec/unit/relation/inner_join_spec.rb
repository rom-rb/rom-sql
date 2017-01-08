RSpec.describe ROM::Relation, '#inner_join' do
  subject(:relation) { container.relations.users }

  include_context 'users and tasks'

  with_adapters do
    it 'joins relations using inner join' do
      result = relation.inner_join(:tasks, user_id: :id).select(:name, :title)

      expect(result.schema.map(&:name)).to eql(%i[name title])

      expect(result.to_a).to eql([
        { name: 'Jane', title: "Jane's task" },
        { name: 'Joe', title: "Joe's task" }
      ])
    end

    it 'raises error when column names are ambiguous' do
      expect {
        relation.inner_join(:tasks, user_id: :id).to_a
      }.to raise_error(Sequel::DatabaseError, /ambiguous/)
    end

    it "fails gracefully when the table can't be found" do
      expect {
        relation.inner_join(:task, user_id: :id)
      }.to raise_error(ROM::SQL::Error, /\btask\b/)
    end
  end
end
