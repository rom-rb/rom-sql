RSpec.describe ROM::SQL::Association::OneToOneThrough do
  include_context 'users'
  include_context 'accounts'

  subject(:assoc) {
    ROM::SQL::Association::OneToOneThrough.new(:users, :cards, through: :accounts)
  }

  with_adapters do
    before do
      conf.relation(:accounts) do
        schema do
          attribute :id, ROM::SQL::Types::Serial
          attribute :user_id, ROM::SQL::Types::ForeignKey(:users)
          attribute :number, ROM::SQL::Types::String
          attribute :balance, ROM::SQL::Types::Decimal

          associations do
            one_to_many :cards
            one_to_many :subscriptions, through: :cards
          end
        end
      end

      conf.relation(:cards) do
        schema do
          attribute :id, ROM::SQL::Types::Serial
          attribute :account_id, ROM::SQL::Types::ForeignKey(:accounts)
          attribute :pan, ROM::SQL::Types::String

          associations do
            one_to_many :subscriptions
          end
        end
      end

      conf.relation(:subscriptions) do
        schema do
          attribute :id, ROM::SQL::Types::Serial
          attribute :card_id, ROM::SQL::Types::ForeignKey(:cards)
          attribute :service, ROM::SQL::Types::String

          associations do
            many_to_one :cards
          end
        end
      end
    end

    describe '#result' do
      specify { expect(ROM::SQL::Association::OneToOneThrough.result).to be(:one) }
    end

    describe '#call' do
      it 'prepares joined relations' do
        relation = assoc.call(container.relations)

        expect(relation.schema.map(&:name)).to eql(%i[id account_id pan user_id])
        expect(relation.to_a).to eql([id: 1, account_id: 1, pan: '*6789', user_id: 1])
      end
    end

    describe ':through another assoc' do
      subject(:assoc) do
        ROM::SQL::Association::OneToOneThrough.new(:users, :subscriptions, through: :accounts)
      end

      let(:account_assoc) do
        ROM::SQL::Association::OneToOneThrough.new(:accounts, :subscriptions, through: :cards)
      end

      it 'prepares joined relations through other association' do
        relation = assoc.call(container.relations)

        expect(relation.schema.map(&:name)).to eql(%i[id card_id service user_id])
        expect(relation.to_a).to eql([id: 1, card_id: 1, service: 'aws', user_id: 1])
      end
    end

    describe ROM::Plugins::Relation::SQL::AutoCombine, '#for_combine' do
      it 'preloads relation based on association' do
        relation = cards.for_combine(assoc).call(users.call)

        expect(relation.to_a).to eql([id: 1, account_id: 1, pan: '*6789', user_id: 1])
      end
    end
  end
end
