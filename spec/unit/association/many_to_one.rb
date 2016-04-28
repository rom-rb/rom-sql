require 'spec_helper'

RSpec.describe ROM::SQL::Association::ManyToOne, '#call' do
  subject(:assoc) {
    ROM::SQL::Association::ManyToOne.new(:tasks, :users)
  }

  include_context 'users and tasks'

  before do
    configuration.relation(:tasks) do
      schema do
        attribute :id, ROM::SQL::Types::Serial
        attribute :user_id, ROM::SQL::Types::ForeignKey(:users)
        attribute :title, ROM::SQL::Types::String
      end
    end
  end

  it 'prepares joined relations' do
    relation = assoc.call(container.relations)

    expect(relation.attributes).to eql(%i[id name])
    expect(relation.to_a).to eql([id: 1, name: 'Piotr'])
  end
end
