RSpec.describe ROM::Relation, '#where' do
  subject(:relation) { relations[:tasks].select(:id, :title) }

  include_context 'users and tasks'

  before do
    conf.relation(:tasks) { schema(infer: true) }
  end

  with_adapters do
    it 'restricts relation using provided conditions' do
      expect(relation.where(id: 1).to_a).
        to eql([{ id: 1, title: "Joe's task" }])
    end

    it 'restricts relation using provided conditions and block' do
      expect(relation.where(id: 1) { title.like("%Jane%") }.to_a).to be_empty
    end

    it 'restricts relation using provided conditions in a block' do
      expect(relation.where { (id > 2) & title.like("%Jane%") }.to_a).to be_empty
    end

    it 'restricts relation using canonical attributes' do
      expect(relation.rename(id: :user_id).where { id > 3 }.to_a).to be_empty
    end
  end
end
