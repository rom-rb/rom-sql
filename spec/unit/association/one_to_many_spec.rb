require 'spec_helper'

RSpec.describe ROM::SQL::Association::OneToMany, '#call' do
  subject(:assoc) {
    ROM::SQL::Association::OneToMany.new(:users, :tasks)
  }

  include_context 'users and tasks'

  let(:users) { container.relations[:users] }

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

    expect(relation.attributes).to eql(%i[id user_id title])
    expect(relation.to_a).to eql([id: 1, user_id: 1, title: 'Finish ROM'])
    expect(relation.where(user_id: 1).to_a).to eql([id: 1, user_id: 1, title: 'Finish ROM'])
  end
end
