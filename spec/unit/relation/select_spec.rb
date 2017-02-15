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

    it 'maintains schema' do
      expect(relation.select(:id, :title).schema.map(&:name)).to eql(%i[id title])
    end

    it 'supports args and blocks' do
      expect(relation.select(:id) { [title] }.schema.map(&:name)).to eql(%i[id title])
    end

    it 'supports blocks' do
      expect(relation.select { [id, title] }.schema.map(&:name)).to eql(%i[id title])
    end

    it 'supports selecting literal strings' do
      new_rel = relation.select { `'event'`.as(:type) }

      expect(new_rel.schema[:type].primitive).to be(String)
      expect(new_rel.first).to eql(type: 'event')
    end
  end
end
