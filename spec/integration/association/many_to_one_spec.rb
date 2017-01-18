RSpec.describe ROM::SQL::Association::ManyToOne, helpers: true do
  subject(:assoc) {
    ROM::SQL::Association::ManyToOne.new(:tasks, :users)
  }

  include_context 'users and tasks'

  let(:users) { container.relations[:users] }
  let(:tasks) { container.relations[:tasks] }
  let(:articles) { container.relations[:articles] }

  with_adapters do
    before do
      conf.relation(:tasks) do
        schema do
          attribute :id, ROM::SQL::Types::Serial
          attribute :user_id, ROM::SQL::Types::ForeignKey(:users)
          attribute :title, ROM::SQL::Types::String
        end
      end
    end

    describe '#result' do
      specify { expect(ROM::SQL::Association::ManyToOne.result).to be(:one) }
    end

    describe '#name' do
      it 'uses target by default' do
        expect(assoc.name).to be(:users)
      end
    end

    describe '#target' do
      it 'builds full relation name' do
        assoc = ROM::SQL::Association::ManyToOne.new(:users, :tasks, relation: :foo)

        expect(assoc.name).to be(:tasks)
        expect(assoc.target).to eql(ROM::SQL::Association::Name[:foo, :tasks])
      end
    end

    describe '#call' do
      it 'prepares joined relations' do
        relation = assoc.call(container.relations)

        expect(relation.schema.map(&:to_sym))
          .to eql(%i[users__id users__name tasks__id___task_id])

        expect(relation.where(user_id: 1).one).to eql(id: 1, task_id: 2, name: 'Jane')

        expect(relation.where(user_id: 2).one).to eql(id: 2, task_id: 1, name: 'Joe')

        expect(relation.to_a).to eql([
          { id: 2, task_id: 1, name: 'Joe' },
          { id: 1, task_id: 2, name: 'Jane' }
        ])
      end
    end

    describe ROM::Plugins::Relation::SQL::AutoCombine, '#for_combine' do
      it 'preloads relation based on association' do
        relation = users.for_combine(assoc).call(tasks.call)

        expect(relation.to_a).to eql([
          { id: 2, task_id: 1, name: 'Joe' },
          { id: 1, task_id: 2, name: 'Jane' }
        ])
      end

      it 'maintains original relation' do
        users.accounts.insert(user_id: 2, number: 'a1', balance: 0)

        relation = users.
                     join(:accounts, user_id: :id).
                     select_append(users.accounts[:number].as(:account_num)).
                     for_combine(assoc).call(tasks.call)

        expect(relation.to_a).to eql([{ id: 2, task_id: 1, name: 'Joe', account_num: 'a1' }])
      end
    end

    context 'arbitrary name conventions' do
      let(:articles_name) { ROM::Relation::Name[:articles, :posts] }

      subject(:assoc) do
        ROM::SQL::Association::ManyToOne.new(articles_name, :users)
      end

      before do
        conf.relation(:articles) do
          schema(:posts) do
            attribute :post_id, ROM::SQL::Types::Serial
            attribute :author_id, ROM::SQL::Types::ForeignKey(:users)
            attribute :title, ROM::SQL::Types::Strict::String
            attribute :body, ROM::SQL::Types::Strict::String
          end
        end
      end

      describe '#call' do
        it 'prepares joined relations' do
          relation = assoc.call(container.relations)

          expect(relation.schema.map(&:to_sym))
            .to eql(%i[users__id users__name posts__post_id])

          expect(relation.order(:id).to_a).to eql([
            { id: 1, name: 'Jane', post_id: 2 },
            { id: 2, name: 'Joe', post_id: 1 }
          ])

          expect(relation.where(author_id: 1).to_a).to eql(
            [id: 1, name: 'Jane', post_id: 2]
          )

          expect(relation.where(author_id: 2).to_a).to eql(
            [id: 2, name: 'Joe', post_id: 1]
          )
        end
      end
    end
  end
end
