RSpec.describe ROM::SQL::Association::OneToMany, helpers: true do
  include_context 'users and tasks'

  subject(:assoc) do
    build_assoc(:one_to_many, :users, :tasks)
  end

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
      specify { expect(assoc.result).to be(:many) }
    end

    describe '#combine_keys' do
      specify { expect(assoc.combine_keys).to eql(id: :user_id) }
    end

    describe '#associate' do
      it 'merges FKs into tuples' do
        child = { name: 'Child' }
        parent = { id: 312, name: 'Parent '}

        expect(assoc.associate(child, parent)).to eql(user_id: 312, name: 'Child')
      end
    end

    describe '#call' do
      it 'prepares joined relations' do
        relation = assoc.()

        expect(relation.schema.map(&:name)).to eql(%i[id user_id title])

        expect(relation.order(tasks[:id].qualified).to_a).to eql([
          { id: 1, user_id: 2, title: "Joe's task" },
          { id: 2, user_id: 1, title: "Jane's task" }
        ])

        expect(relation.where(user_id: 1).to_a).to eql([
          { id: 2, user_id: 1, title: "Jane's task" }
        ])

        expect(relation.where(user_id: 2).to_a).to eql([
          { id: 1, user_id: 2, title: "Joe's task" }
        ])
      end
    end

    describe ROM::Plugins::Relation::SQL::AutoCombine, '#for_combine' do
      it 'preloads relation based on association' do
        relation = tasks.for_combine(assoc).call(users.call)

        expect(relation.to_a).to eql([
          { id: 1, user_id: 2, title: "Joe's task" },
          { id: 2, user_id: 1, title: "Jane's task" }
        ])
      end

      it 'maintains original relation' do
        relation = tasks.
                     join(:task_tags, tag_id: :id).
                     select_append(tasks.task_tags[:tag_id].qualified).
                     for_combine(assoc).call(users.call)

        expect(relation.to_a).to eql([{ id: 1, user_id: 2, title: "Joe's task", tag_id: 1 }])
      end

      it 'respects custom order' do
        relation = tasks.
                     order(tasks[:title].qualified).
                     for_combine(assoc).call(users.call)

        expect(relation.to_a).
          to eql([{ id: 2, user_id: 1, title: "Jane's task" }, { id: 1, user_id: 2, title: "Joe's task" }])
      end
    end
  end
end
