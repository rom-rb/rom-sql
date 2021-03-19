RSpec.describe ROM::Relation, '#project' do
  subject(:relation) { container.relations.users }

  include_context 'users and tasks'

  before do
    conf.relation(:users) do
      schema(infer: true)

      def sorted
        order(:id)
      end
    end
  end

  with_adapters do
    it 'projects the dataset using new column names' do
      projected = relation.sorted.project(:name)

      expect(projected.schema[:name]).to be_qualified
      expect(projected.first).to eql(name: 'Jane')
    end

    describe 'subqueries' do
      it 'supports single-column relations as attributes' do
        tasks_count = tasks.
                        project { integer::count(id).as(:id) }.
                        where(tasks[:user_id] => users[:id]).
                        where(tasks[:title].ilike('joe%')).
                        unordered.
                        query

        results = relation.project { [id, tasks_count.as(:tasks_count)] }.to_a

        expect(results).to eql([ {id: 1, tasks_count: 0}, {id: 2, tasks_count: 1} ])
      end
    end
  end
end
