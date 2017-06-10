RSpec.describe ROM::SQL::Wrap do
  with_adapters do
    include_context 'users and tasks'

    describe '#wrap' do
      shared_context 'joined tuple' do
        it 'returns nested tuples' do
          task_with_user = tasks
            .wrap(name)
            .where { id.qualified.is(2) }
            .one

          expect(task_with_user).to eql(
            id: 2, user_id: 1, title: "Jane's task", users_name: "Jane", users_id: 1
          )
        end

        it 'works with by_pk' do
          task_with_user = tasks
                             .wrap(name)
                             .by_pk(1)
                             .one

          expect(task_with_user).
            to eql(id: 1, user_id: 2, title: "Joe's task", users_name: "Joe", users_id: 2)
        end
      end

      context 'using association with inferred relation name' do
        before do
          conf.relation(:tasks) do
            schema(infer: true) do
              associations do
                belongs_to :user
              end
            end
          end

          conf.relation(:users) do
            schema(infer: true)
          end
        end

        include_context 'joined tuple' do
          let(:name) { :user }
        end
      end

      context 'using association with an alias' do
        before do
          conf.relation(:tasks) do
            schema(infer: true) do
              associations do
                belongs_to :users, as: :assignee
              end
            end
          end

          conf.relation(:users) do
            schema(infer: true)
          end
        end

        include_context 'joined tuple' do
          let(:name) { :assignee }
        end
      end

      context 'using association with an aliased relation' do
        before do
          conf.relation(:tasks) do
            schema(infer: true) do
              associations do
                belongs_to :users, as: :assignee, relation: :people
              end
            end
          end

          conf.relation(:people) do
            schema(:users, infer: true)
          end
        end

        include_context 'joined tuple' do
          let(:users) { relations[:people] }
          let(:name) { :assignee }
        end
      end
    end
  end
end
