# frozen_string_literal: true

RSpec.describe ROM::SQL::Associations::ManyToOne, helpers: true do
  with_adapters do
    context 'common name conventions' do
      include_context 'users and tasks'
      include_context 'accounts'

      subject(:assoc) do
        build_assoc(:many_to_one, :tasks, :users)
      end

      before do
        conf.relation(:tasks) do
          schema(infer: true)
        end
      end

      describe '#name' do
        it 'uses target by default' do
          expect(assoc.name).to be(:users)
        end
      end

      describe '#result' do
        specify { expect(assoc.result).to be(:one) }
      end

      describe '#combine_keys' do
        specify { expect(assoc.combine_keys).to eql(user_id: :id) }
      end

      describe '#call' do
        it 'prepares joined relations' do
          relation = assoc.(preload: false)

          expect(relation.schema.map(&:to_sql_name)).to eql([
            Sequel.qualify(:users, :id),
            Sequel.qualify(:users, :name),
            Sequel.qualify(:tasks, :id).as(:task_id)
          ])

          expect(relation.where(user_id: 1).one).to eql(id: 1, task_id: 2, name: 'Jane')

          expect(relation.where(user_id: 2).one).to eql(id: 2, task_id: 1, name: 'Joe')

          expect(relation.to_a).to eql([
            { id: 1, task_id: 2, name: 'Jane' },
            { id: 2, task_id: 1, name: 'Joe' }
          ])
        end
      end

      describe '#eager_load' do
        it 'preloads relation based on association' do
          relation = users.eager_load(assoc).call(tasks.call)

          expect(relation.to_a).to eql([{ id: 1, name: 'Jane' }, { id: 2, name: 'Joe' }])
        end

        it 'maintains original relation' do
          users.accounts.insert(user_id: 2, number: '31', balance: 0)

          relation = users
            .join(:accounts, user_id: :id)
            .select_append(users.accounts[:number].as(:account_num))
            .order(:account_num)
            .eager_load(assoc).call(tasks.call)

          expect(relation.to_a).to eql([
            { id: 2, name: 'Joe', account_num: '31' },
            { id: 1, name: 'Jane', account_num: '42' }
          ])
        end
      end
    end

    context 'arbitrary name conventions' do
      include_context 'users'
      include_context 'posts'

      let(:articles_name) { ROM::Relation::Name[:articles, :posts] }
      let(:articles) { container.relations[:articles] }

      subject(:assoc) do
        build_assoc(:many_to_one, articles_name, :users)
      end

      before do
        conf.relation(:articles) do
          schema(:posts, infer: true)
        end
      end

      describe '#call' do
        it 'prepares joined relations' do
          relation = assoc.()

          expect(relation.schema.map(&:to_sql_name)).to eql([
            Sequel.qualify(:users, :id),
            Sequel.qualify(:users, :name),
            Sequel.qualify(:posts, :post_id)
          ])

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
