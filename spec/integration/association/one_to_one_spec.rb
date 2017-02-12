RSpec.describe ROM::SQL::Association::OneToOne do
  include_context 'users'
  include_context 'accounts'

  subject(:assoc) {
    ROM::SQL::Association::OneToOne.new(:users, :accounts)
  }

  with_adapters do
    before do
      conn[:accounts].insert user_id: 1, number: '43', balance: -273.15.to_d

      conf.relation(:accounts) do
        schema do
          attribute :id, ROM::SQL::Types::Serial
          attribute :user_id, ROM::SQL::Types::ForeignKey(:users)
          attribute :number, ROM::SQL::Types::String
          attribute :balance, ROM::SQL::Types::Decimal
        end
      end
    end

    describe '#result' do
      specify { expect(ROM::SQL::Association::OneToOne.result).to be(:one) }
    end

    describe '#call' do
      it 'prepares joined relations' do |example|
        relation = assoc.call(container.relations)

        expect(relation.schema.map(&:name)).to eql(%i[id user_id number balance])

        # TODO: this if caluse should be removed when (and if) https://github.com/xerial/sqlite-jdbc/issues/112
        # will be resolved. See https://github.com/rom-rb/rom-sql/issues/49 for details
        if jruby? && sqlite?(example)
          expect(relation.to_a).
            to eql([{ id: 1, user_id: 1, number: '42', balance: 10_000 },
                    { id: 2, user_id: 1, number: '43', balance: -273.15 }])
        else
          expect(relation.to_a).
            to eql([{ id: 1, user_id: 1, number: '42', balance: 10_000.to_d },
                    { id: 2, user_id: 1, number: '43', balance: -273.15.to_d }])
        end
      end
    end

    describe ROM::Plugins::Relation::SQL::AutoCombine, '#for_combine' do
      it 'preloads relation based on association' do |example|
        relation = accounts.for_combine(assoc).call(users.call)

        # TODO: this if caluse should be removed when (and if) https://github.com/xerial/sqlite-jdbc/issues/112
        # will be resolved. See https://github.com/rom-rb/rom-sql/issues/49 for details
        if jruby? && sqlite?(example)
          expect(relation.to_a).
            to eql([{ id: 1, user_id: 1, number: '42', balance: 10_000 },
                    { id: 2, user_id: 1, number: '43', balance: -273.15 }])
        else
          expect(relation.to_a).
            to eql([{ id: 1, user_id: 1, number: '42', balance: 10_000.to_d },
                    { id: 2, user_id: 1, number: '43', balance: -273.15.to_d }])
        end
      end
    end
  end
end
