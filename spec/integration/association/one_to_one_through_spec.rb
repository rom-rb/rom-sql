require 'spec_helper'

RSpec.describe ROM::SQL::Association::OneToOneThrough do
  subject(:assoc) {
    ROM::SQL::Association::OneToOneThrough.new(:users, :cards, through: :accounts)
  }

  include_context 'users and accounts'

  let(:users) { container.relations[:users] }
  let(:cards) { container.relations[:cards] }

  before do
    configuration.relation(:accounts) do
      schema do
        attribute :id, ROM::SQL::Types::Serial
        attribute :user_id, ROM::SQL::Types::ForeignKey(:users)
        attribute :number, ROM::SQL::Types::String
        attribute :balance, ROM::SQL::Types::Decimal
      end
    end

    configuration.relation(:cards) do
      schema do
        attribute :id, ROM::SQL::Types::Serial
        attribute :account_id, ROM::SQL::Types::ForeignKey(:accounts)
        attribute :pan, ROM::SQL::Types::String
      end
    end
  end

  describe '#call' do
    it 'prepares joined relations' do
      relation = assoc.call(container.relations)

      expect(relation.attributes).to eql(%i[id account_id pan user_id])
      expect(relation.to_a).to eql([id: 1, account_id: 1, pan: '*6789', user_id: 1])
    end
  end

  describe '#combine_keys' do
    it 'returns key-map used for in-memory tuple-combining' do
      expect(assoc.combine_keys(container.relations)).to eql(id: :user_id)
    end
  end

  describe ROM::Plugins::Relation::SQL::AutoCombine, '#for_combine' do
    it 'preloads relation based on association' do
      relation = cards.for_combine(assoc).call(users.call)

      expect(relation.to_a).to eql([id: 1, account_id: 1, pan: '*6789', user_id: 1])
    end
  end
end
