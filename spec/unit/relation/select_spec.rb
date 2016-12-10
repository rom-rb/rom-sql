RSpec.describe ROM::Relation, '#select' do
  subject(:relation) { container.relations.tasks }

  include_context 'users and tasks'

  before do
    conf.relation(:tasks) { schema(infer: true) }
  end

  with_adapters do
    it 'projects a relation using a list of symbols' do
      expect(relation.select(:id, :title).to_a)
        .to eql([{ id: 1, title: "Joe's task" }, { id: 2, title: "Jane's task"}])
    end

    it 'projects a relation using a schema' do
      expect(relation.select(*relation.schema.project(:id, :title)).to_a)
        .to eql([{ id: 1, title: "Joe's task" }, { id: 2, title: "Jane's task"}])
    end
  end
end
