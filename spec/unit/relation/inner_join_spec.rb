RSpec.describe ROM::Relation, '#inner_join' do
  subject(:relation) { relations[:users] }

  let(:tasks) { relations[:tasks] }

  include_context 'users and tasks'

  with_adapters do
    it 'joins relations using inner join' do
      relation.insert id: 3, name: 'Jade'

      result = relation.
                 inner_join(:tasks, user_id: :id).
                 select(:name, tasks[:title])

      expect(result.schema.map(&:name)).to eql(%i[name title])

      expect(result.to_a).to eql([
        { name: 'Jane', title: "Jane's task" },
        { name: 'Joe', title: "Joe's task" }
      ])
    end

    it 'allows specifying table_aliases' do
      relation.insert id: 3, name: 'Jade'

      result = relation.
                 inner_join(:tasks, {user_id: :id}, table_alias: :t1).
                 select(:name, tasks[:title])

      expect(result.schema.map(&:name)).to eql(%i[name title])

      expect(result.to_a).to eql([
        { name: 'Jane', title: "Jane's task" },
        { name: 'Joe', title: "Joe's task" }
      ])
    end

    context 'with associations' do
      before do
        conf.relation(:users) do
          schema(infer: true) do
            associations { has_many :tasks }
          end
        end

        conf.relation(:tasks) do
          schema(infer: true) do
            associations { belongs_to :user }
          end
        end

        relation.insert id: 3, name: 'Jade'
      end

      it 'joins relation with join keys inferred' do
        result = relation.
                   inner_join(tasks).
                   select(:name, tasks[:title])

        expect(result.schema.map(&:name)).to eql(%i[name title])

        expect(result.to_a).to eql([
                                     { name: 'Jane', title: "Jane's task" },
                                     { name: 'Joe', title: "Joe's task" }
                                   ])
      end
    end

    it 'raises error when column names are ambiguous' do
      expect {
        relation.inner_join(:tasks, user_id: :id).to_a
      }.to raise_error(Sequel::DatabaseError, /ambiguous/)
    end

    it 'raises error when join arg is unsupported' do
      expect {
        relation.inner_join(421)
      }.to raise_error(ArgumentError, /other/)
    end
  end
end
