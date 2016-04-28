require 'spec_helper'

RSpec.describe ROM::SQL::Association::ManyToOne do
  subject(:assoc) {
    ROM::SQL::Association::ManyToOne.new(:tasks, :users)
  }

  include_context 'users and tasks'

  let(:users) { container.relations[:users] }
  let(:tasks) { container.relations[:tasks] }

  before do
    configuration.relation(:tasks) do
      schema do
        attribute :id, ROM::SQL::Types::Serial
        attribute :user_id, ROM::SQL::Types::ForeignKey(:users)
        attribute :title, ROM::SQL::Types::String
      end
    end
  end

  describe '#call' do
    it 'prepares joined relations' do
      relation = assoc.call(container.relations)

      expect(relation.attributes).to eql(%i[id name task_id])
      expect(relation.to_a).to eql([id: 1, task_id: 1, name: 'Piotr'])
    end
  end

  describe '#combine_keys' do
    it 'returns key-map used for in-memory tuple-combining' do
      expect(assoc.combine_keys(container.relations)).to eql(id: :user_id)
    end
  end

  describe ROM::Plugins::Relation::SQL::AutoCombine, '#for_combine' do
    it 'preloads relation based on association' do
      relation = users.for_combine(assoc).call(tasks.call)

      expect(relation.to_a).to eql([id: 1, task_id: 1, name: 'Piotr'])
    end
  end
end
