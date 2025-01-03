# frozen_string_literal: true

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
            id: 2, user_id: 1, title: "Jane's task", users_name: 'Jane', users_id: 1
          )
        end

        it 'works with by_pk' do
          task_with_user = tasks
            .wrap(name)
            .by_pk(1)
            .one

          expect(task_with_user).to eql(
            id: 1, user_id: 2, title: "Joe's task", users_name: 'Joe', users_id: 2
          )
        end
      end

      context 'using association with inferred relation name' do
        before do
          conf.relation(:tasks) do
            auto_map false

            schema(infer: true) do
              associations do
                belongs_to :user
              end
            end
          end
        end

        include_context 'joined tuple' do
          let(:name) { :user }
        end
      end

      context 'using association with an alias' do
        before do
          conf.relation(:tasks) do
            auto_map false

            schema(infer: true) do
              associations do
                belongs_to :users, as: :assignee
              end
            end
          end
        end

        include_context 'joined tuple' do
          let(:name) { :assignee }
        end
      end

      context 'using association with an aliased relation' do
        before do
          conf.relation(:tasks) do
            auto_map false

            schema(infer: true) do
              associations do
                belongs_to :users, as: :assignee, relation: :people
              end
            end
          end

          conf.relation(:people) do
            auto_map false

            schema(:users, infer: true)
          end
        end

        include_context 'joined tuple' do
          let(:users) { relations[:people] }
          let(:name) { :assignee }
        end
      end

      context 'using association with a view' do
        before do
          conf.relation(:users) do
            auto_map false

            schema(infer: true)

            def with_extra_attributes
              select { `'testing'`.as(:extra_attribute) }
            end

            def with_extra_attributes_from_function
              select { string.coalesce(`'testing'`, `'test'`).as(:extra_attribute) }
            end

            def with_renamed_attribute
              select { [name.as(:new_name)] }
            end
          end

          conf.relation(:tasks) do
            auto_map true

            schema(infer: true) do
              associations do
                belongs_to :users, view: :with_extra_attributes, as: :enhanced_user
                belongs_to :users, view: :with_extra_attributes_from_function, as: :enhanced_user_func
                belongs_to :users, view: :with_renamed_attribute, as: :with_renamed_attribute
              end
            end
          end
        end

        it 'includes the extra attributes' do
          result = tasks.wrap(:enhanced_user).to_a

          expect(result.length).to be > 0

          result.each do |task|
            expect(task[:enhanced_user]).to eql(extra_attribute: 'testing')
          end
        end

        it 'works with functions' do
          result = tasks.wrap(:enhanced_user_func).to_a

          expect(result.length).to be > 0

          result.each do |task|
            expect(task[:enhanced_user_func]).to eql(extra_attribute: 'testing')
          end
        end

        it 'allows aliasing attributes' do
          result = tasks.wrap(:with_renamed_attribute).to_a
          values = result.map { |item| item[:with_renamed_attribute][:new_name] }

          expect(values).to contain_exactly('Jane', 'Joe')
        end
      end
    end
  end
end
