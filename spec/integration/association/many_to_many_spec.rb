RSpec.describe ROM::SQL::Association::ManyToMany do
  include_context 'users and tasks'

  with_adapters do
    context 'through a relation with a composite PK' do
      subject(:assoc) {
        ROM::SQL::Association::ManyToMany.new(:tasks, :tags, through: :task_tags)
      }

      let(:tags) { container.relations[:tags] }

      before do
        conf.relation(:task_tags) do
          schema do
            attribute :task_id, ROM::SQL::Types::ForeignKey(:tasks)
            attribute :tag_id, ROM::SQL::Types::ForeignKey(:tags)

            primary_key :task_id, :tag_id

            associations do
              many_to_one :tasks
              many_to_one :tags
            end
          end
        end

        conf.relation(:tasks) do
          schema do
            attribute :id, ROM::SQL::Types::Serial
            attribute :user_id, ROM::SQL::Types::ForeignKey(:users)
            attribute :title, ROM::SQL::Types::String

            associations do
              one_to_many :task_tags
              one_to_many :tags, through: :task_tags
            end
          end
        end
      end

      describe '#result' do
        specify { expect(ROM::SQL::Association::ManyToMany.result).to be(:many) }
      end

      describe '#call' do
        it 'prepares joined relations' do
          relation = assoc.call(container.relations)

          expect(relation.schema.map(&:to_sql_name)).
            to eql([Sequel.qualify(:tags, :id),
                    Sequel.qualify(:tags, :name),
                    Sequel.qualify(:task_tags, :task_id)])
          expect(relation.to_a).to eql([id: 1, name: 'important', task_id: 1])
        end
      end

      describe ':through another assoc' do
        subject(:assoc) do
          ROM::SQL::Association::ManyToMany.new(:users, :tags, through: :tasks)
        end

        it 'prepares joined relations through other association' do
          relation = assoc.call(container.relations)

          expect(relation.schema.map(&:to_sql_name)).
            to eql([Sequel.qualify(:tags, :id),
                    Sequel.qualify(:tags, :name),
                    Sequel.qualify(:tasks, :user_id)])
          expect(relation.to_a).to eql([id: 1, name: 'important', user_id: 2])
        end
      end

      describe ROM::Plugins::Relation::SQL::AutoCombine, '#for_combine' do
        it 'preloads relation based on association' do
          relation = tags.for_combine(assoc).call(tasks.call)

          expect(relation.to_a).to eql([id: 1, name: 'important', task_id: 1])
        end

        it 'maintains original relation' do
          relation = tags.
                       select_append(tags[:name].as(:tag)).
                       for_combine(assoc).call(tasks.call)

          expect(relation.to_a).to eql([id: 1, tag: 'important', name: 'important', task_id: 1])
        end

        it 'respects custom order' do
          conn[:tags].insert id: 2, name: 'boring'
          conn[:task_tags].insert(tag_id: 2, task_id: 1)

          relation = tags.
                       order(tags[:name].qualified).
                       for_combine(assoc).call(tasks.call)

          expect(relation.to_a).
            to eql([
                     { id: 2, name: 'boring', task_id: 1 },
                     { id: 1, name: 'important', task_id: 1 }
                   ])
        end
      end
    end

    context 'with two associations pointing to the same target relation' do
      before do
        inferrable_relations.concat %i(users_tasks)
      end

      before do
        conn.create_table(:users_tasks) do
          foreign_key :user_id, :users
          foreign_key :task_id, :tasks
          primary_key [:user_id, :task_id]
        end

        conf.relation(:users) do
          schema(infer: true) do
            associations do
              has_many :users_tasks
              has_many :tasks, through: :users_tasks
              has_many :tasks, as: :priv_tasks
            end
          end
        end

        conf.relation(:users_tasks) do
          schema(infer: true) do
            associations do
              belongs_to :user
              belongs_to :task
            end
          end
        end

        conf.relation(:tasks) do
          schema(infer: true) do
            associations do
              has_many :users_tasks
              has_many :users, through: :users_tasks
            end
          end
        end
      end

      it 'does not conflict with two FKs' do
        users = container.relations[:users]
        tasks = container.relations[:tasks]
        assoc = users.associations[:tasks]

        relation = tasks.for_combine(assoc).call(users.call)

        expect(relation.to_a).to be_empty
      end

      it 'preloads using FK' do
        users = container.relations[:users]
        tasks = container.relations[:tasks]
        assoc = users.associations[:priv_tasks]

        relation = tasks.for_combine(assoc).call(users.where(id: 2).call)

        expect(relation.to_a).to eql([id: 1, user_id: 2, title: "Joe's task"])
      end
    end
  end
end
