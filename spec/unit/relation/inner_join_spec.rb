RSpec.describe ROM::Relation, '#inner_join' do
  subject(:relation) { relations[:users] }

  let(:puzzles) { relations[:puzzles] }

  include_context 'users and tasks'

  with_adapters do
    it 'joins relations using inner join' do
      relation.insert id: 3, name: 'Jade'

      result = relation
               .inner_join(:tasks, user_id: :id)
               .select(:name, tasks[:title])

      expect(result.schema.map(&:name)).to eql(%i[name title])

      expect(result.to_a).to eql([
                                   { name: 'Jane', title: "Jane's task" },
                                   { name: 'Joe', title: "Joe's task" }
                                 ])
    end

    it 'joins relations using inner join and attributes with alias set' do
      relation.insert id: 3, name: 'Jade'
      user_id = users[:id].with(alias: :key)
      id = tasks[:user_id].with(alias: :user_key)

      result = relation
               .inner_join(:tasks, user_id => id)
               .select(:name, tasks[:title])

      expect(result.schema.map(&:name)).to eql(%i[name title])

      expect(result.to_a).to eql([
                                   { name: 'Jane', title: "Jane's task" },
                                   { name: 'Joe', title: "Joe's task" }
                                 ])
    end

    it 'allows specifying table_alias with table name' do
      relation.insert id: 3, name: 'Jade'

      result = relation
               .inner_join(:tasks, { user_id: :id }, table_alias: :t1)
               .select(:name, tasks[:title].qualified(:t1))

      expect(result.schema.map(&:name)).to eql(%i[name title])

      expect(result.to_a).to eql([
                                   { name: 'Jane', title: "Jane's task" },
                                   { name: 'Joe', title: "Joe's task" }
                                 ])
    end

    context 'with associations' do
      before do
        inferrable_relations.concat %i[puzzles]
      end

      before do
        conn.create_table(:puzzles) do
          primary_key :id
          foreign_key :author_id, :users, null: false
          column :text, String, null: false
        end

        conf.relation(:users) do
          schema(infer: true) do
            associations do
              has_many :tasks
              has_many :tasks, as: :todos, relation: :tasks
            end
          end
        end

        conf.relation(:task_tags) do
          schema(infer: true) do
            associations do
              belongs_to :tasks
              belongs_to :tags
            end
          end
        end

        conf.relation(:tasks) do
          schema(infer: true) do
            associations do
              belongs_to :user
              has_many :task_tags
              has_many :tags, through: :task_tags
            end
          end
        end

        conf.relation(:puzzles) do
          schema(infer: true) do
            associations do
              belongs_to :users, as: :author
            end
          end
        end

        relation.insert id: 3, name: 'Jade'
        puzzles.insert id: 1, author_id: 1, text: 'solved by Jane'
      end

      it 'joins relation with join keys inferred' do
        result = relation
                 .inner_join(tasks)
                 .select(:name, tasks[:title])

        expect(result.schema.map(&:name)).to eql(%i[name title])

        expect(result.to_a).to eql([
                                     { name: 'Jane', title: "Jane's task" },
                                     { name: 'Joe', title: "Joe's task" }
                                   ])
      end

      let(:task_relation_proxy) {
        Class.new {
          def name
            ROM::Relation::Name.new(:tasks)
          end
        }.new
      }

      it 'joins relation with relation proxy objects' do
        result = relation
                 .inner_join(task_relation_proxy)
                 .select(:name, tasks[:title])

        expect(result.schema.map(&:name)).to eql(%i[name title])

        expect(result.to_a).to eql([
                                     { name: 'Jane', title: "Jane's task" },
                                     { name: 'Joe', title: "Joe's task" }
                                   ])
      end

      describe 'joined relation with join keys inferred for m:m-through' do
        before do
          tags.insert(id: 2, name: 'postponed')
          tasks.task_tags.insert(tag_id: 2, task_id: 2)
        end

        let(:expected_result) do
          [{ id: 1, user_id: 2, title: "Joe's task" }, { id: 2, user_id: 1, title: "Jane's task" }]
        end

        it 'using target relation' do
          result = tasks.inner_join(tags)

          expect(result.to_a).to eql(expected_result)
        end

        it 'using target relation' do
          result = tasks.inner_join(:tags)

          expect(result.to_a).to eql(expected_result)
        end
      end

      it 'joins by association name if no condition provided' do
        result = relation
                 .inner_join(:tasks)
                 .select(:name, tasks[:title])

        expect(result.schema.map(&:name)).to eql(%i[name title])

        expect(result.to_a).to eql([
                                     { name: 'Jane', title: "Jane's task" },
                                     { name: 'Joe', title: "Joe's task" }
                                   ])
      end

      it 'joins if association name differs from relation name' do
        result = relation
                 .inner_join(:todos)
                 .select(:name, tasks[:title])

        expect(result.schema.map(&:name)).to eql(%i[name title])

        expect(result.to_a).to eql([
                                     { name: 'Jane', title: "Jane's task" },
                                     { name: 'Joe', title: "Joe's task" }
                                   ])
      end

      it 'joins by relation if association name differs from relation name' do
        result = puzzles.inner_join(users).select(users[:name], puzzles[:text])

        expect(result.to_a).to eql([name: 'Jane', text: 'solved by Jane'])
      end

      it 'allows specifying table_alias with association name' do
        result = relation
                .inner_join(:tasks, { user_id: :id }, table_alias: :t1)
                .select(:name, tasks[:title].qualified(:t1))

        expect(result.schema.map(&:name)).to eql(%i[name title])

        expect(result.to_a).to eql([
                                    { name: 'Jane', title: "Jane's task" },
                                    { name: 'Joe', title: "Joe's task" }
                                  ])
      end

      it 'allows specifying table_alias with relation' do
        result = relation
                .inner_join(tasks, { user_id: :id }, table_alias: :requirements)
                .select(:name, tasks[:title].qualified(:requirements))

        expect(result.schema.map(&:name)).to eql(%i[name title])

        expect(result.to_a).to eql([
                                    { name: 'Jane', title: "Jane's task" },
                                    { name: 'Joe', title: "Joe's task" }
                                  ])
      end

      it 'allows specifying table_alias with association name different from relation name' do
        result = relation
                .inner_join(:todos, {user_id: :id}, table_alias: :requirements)
                .select(:name, tasks[:title].qualified(:requirements))

        expect(result.schema.map(&:name)).to eql(%i[name title])

        expect(result.to_a).to eql([
                                    { name: 'Jane', title: "Jane's task" },
                                    { name: 'Joe', title: "Joe's task" }
                                  ])
      end
    end
  end
end
