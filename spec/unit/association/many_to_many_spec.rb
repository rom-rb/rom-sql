require 'spec_helper'

RSpec.describe ROM::SQL::Association::ManyToMany do
  subject(:assoc) {
    ROM::SQL::Association::ManyToMany.new(:tasks, :tags, through: :task_tags)
  }

  include_context 'users and tasks'

  let(:tasks) { container.relations[:tasks] }

  before do
    configuration.relation(:task_tags) do
      schema do
        attribute :task_id, ROM::SQL::Types::ForeignKey(:tasks)
        attribute :tag_id, ROM::SQL::Types::ForeignKey(:tags)
      end
    end
  end

  describe '#call' do
    it 'prepares joined relations' do
      relation = assoc.call(container.relations)

      expect(relation.attributes).to eql(%i[id name task_id])
      expect(relation.to_a).to eql([id: 1, name: 'important', task_id: 1])
    end
  end

  describe '#combine_keys' do
    it 'returns key-map used for in-memory tuple-combining' do
      expect(assoc.combine_keys(container.relations)).to eql(id: :task_id)
    end
  end
end
