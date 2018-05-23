RSpec.describe ROM::SQL::Associations::ManyToMany, helpers: true do
  include_context 'users and tasks'

  with_adapters do
    context 'through a relation with a composite PK' do
      subject(:assoc) do
        build_assoc(:many_to_many, :tasks, :tags, through: :task_tags)
      end

      let(:tags) { relations[:tags] }

      before do
        conf.relation(:task_tags) do
          schema(infer: true) do
            associations do
              belongs_to :task
              belongs_to :tag
            end
          end
        end

        conf.relation(:tasks) do
          schema(infer: true) do
            associations do
              has_many :task_tags
              has_many :tags, through: :task_tags
            end
          end
        end
      end

      describe '#result' do
        specify { expect(assoc.result).to be(:many) }
      end

      describe '#combine_keys' do
        specify { expect(assoc.combine_keys).to eql(id: :task_id) }
      end

      describe '#dataset' do
        it 'actually performs the correct join' do
          # get the resulting dataset from an ordinary join
          ds = tasks.join(:tags).dataset

          # now get the joins
          joins = ds.opts[:join]

          # joins should be an array of two elements
          expect(joins).to be_a Array
          expect(joins.length).to be 2

          # collect a list of join pairs
          join_coll = []
          joins.each do |j|
            # if this isn't true then this loop will crash
            expect(j).to be_a Sequel::SQL::JoinOnClause

            join_coll << j.on.args.map(&:to_sym)
          end

          # here is what the join column pairs should look like
          join_ok = [
            [:tasks__id, :task_tags__task_id],
            [:task_tags__tag_id, :tags__id],
          ].freeze

          # mkay?
          expect(join_coll).to eql join_ok
        end
      end

      describe '#call' do
        it 'prepares joined relations' do
          relation = assoc.()

          expect(relation.schema.map(&:to_sql_name)).
            to eql([Sequel.qualify(:tags, :id),
                    Sequel.qualify(:tags, :name),
                    Sequel.qualify(:task_tags, :task_id)])
          expect(relation.to_a).to eql([id: 1, name: 'important', task_id: 1])
        end
      end

      describe ':through another assoc' do
        subject(:assoc) do
          build_assoc(:many_to_many, :users, :tags, through: :tasks)
        end

        it 'prepares joined relations through other association' do
          relation = assoc.()

          expect(relation.schema.map(&:to_sql_name)).
            to eql([Sequel.qualify(:tags, :id),
                    Sequel.qualify(:tags, :name),
                    Sequel.qualify(:tasks, :user_id)])
          expect(relation.to_a).to eql([id: 1, name: 'important', user_id: 2])
        end
      end

      describe '#eager_load' do
        it 'preloads relation based on association' do
          relation = tags.eager_load(assoc).call(tasks.call)

          expect(relation.to_a).to eql([id: 1, name: 'important', task_id: 1])
        end

        it 'maintains original relation' do
          relation = tags.
                       select_append(tags[:name].as(:tag)).
                       eager_load(assoc).call(tasks.call)

          expect(relation.to_a).to eql([id: 1, tag: 'important', name: 'important', task_id: 1])
        end

        it 'respects custom order' do
          conn[:tags].insert id: 2, name: 'boring'
          conn[:task_tags].insert(tag_id: 2, task_id: 1)

          relation = tags.
                       order(tags[:name].qualified).
                       eager_load(assoc).call(tasks.call)

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

        relation = tasks.eager_load(assoc).call(users.call)

        expect(relation.to_a).to be_empty
      end

      it 'preloads using FK' do
        users = container.relations[:users]
        tasks = container.relations[:tasks]
        assoc = users.associations[:priv_tasks]

        relation = tasks.eager_load(assoc).call(users.where(id: 2).call)

        expect(relation.to_a).to eql([id: 1, user_id: 2, title: "Joe's task"])
      end
    end
  end
end
