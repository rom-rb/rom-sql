require 'spec_helper'

RSpec.describe ROM::SQL::Association::ManyToMany do
  subject(:assoc) {
    ROM::SQL::Association::ManyToMany.new(:tasks, :tags, through: :task_tags)
  }

  include_context 'users and tasks'

  let(:tasks) { container.relations[:tasks] }
  let(:tags) { container.relations[:tags] }

  before do
    configuration.relation(:task_tags) do
      schema do
        attribute :task_id, ROM::SQL::Types::ForeignKey(:tasks)
        attribute :tag_id, ROM::SQL::Types::ForeignKey(:tags)
      end
    end
  end

  describe '#result' do
    specify { expect(ROM::SQL::Association::ManyToMany.result).to be(:many) }
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

  describe ':through another assoc' do
    subject(:assoc) do
      ROM::SQL::Association::ManyToMany.new(:users, :tags, through: task_assoc)
    end

    let(:task_assoc) do
      ROM::SQL::Association::ManyToMany.new(:tasks, :tags, through: :task_tags)
    end

    before do
      configuration.relation(:tasks) do
        schema do
          attribute :id, ROM::SQL::Types::Serial
          attribute :user_id, ROM::SQL::Types::ForeignKey(:users)
          attribute :title, ROM::SQL::Types::String
        end
      end
    end

    it 'prepares joined relations through other association' do
      relation = assoc.call(container.relations)

      expect(relation.attributes).to eql(%i[id name user_id])
      expect(relation.to_a).to eql([id: 1, name: 'important', user_id: 1])
    end
  end

  describe ROM::Plugins::Relation::SQL::AutoCombine, '#for_combine' do
    it 'preloads relation based on association' do
      relation = tags.for_combine(assoc).call(tasks.call)

      expect(relation.to_a).to eql([id: 1, name: 'important', task_id: 1])
    end
  end
end
