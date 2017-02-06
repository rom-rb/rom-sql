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

    it 'restricts with or condition' do
      expect(relation.where { id.is(1) | id.is(2) }.to_a).
        to eql([{ id: 1, title: "Joe's task" }, { id: 2, title: "Jane's task" }])
    end

    it 'restricts with a range condition' do
      expect(relation.where { id.in(-1...2) }.to_a).
        to eql([{ id: 1, title: "Joe's task" }])

      expect(relation.where { id.in(0...3) }.to_a).
        to eql([{ id: 1, title: "Joe's task" }, { id: 2, title: "Jane's task" }])
    end

    it 'restricts with an inclusive range' do
      expect(relation.where { id.in(0..2) }.to_a).
        to eql([{ id: 1, title: "Joe's task" }, { id: 2, title: "Jane's task" }])
    end

    it 'restricts with an ordinary enum' do
      expect(relation.where { id.in(2, 3) }.to_a).
        to eql([{ id: 2, title: "Jane's task" }])
    end

    it 'restricts with enum using self syntax' do
      expect(relation.where(relation[:id].in(2, 3)).to_a).
        to eql([{ id: 2, title: "Jane's task" }])
    end
  end
end
