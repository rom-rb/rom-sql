require 'spec_helper'

RSpec.describe ROM::SQL::Association::ManyToMany, '#call' do
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

  it 'prepares joined relations' do
    relation = assoc.call(container.relations)

    expect(relation.to_a).to eql([id: 1, name: 'important', task_id: 1])
  end
end
