RSpec.describe 'Plugins / :associates' do
  include_context 'relations'

  context 'with Create command' do
    let(:users) { container.commands[:users] }
    let(:tasks) { container.commands[:tasks] }
    let(:tags) { container.commands[:tags] }

    before do
      configuration.commands(:users) do
        define(:create) { result :one }
      end
    end

    shared_context 'automatic FK setting' do
      it 'sets foreign key prior execution for many tuples' do
        create_user = users[:create].with(name: 'Jade')
        create_task = tasks[:create_many].with([{ title: 'Task one' }, { title: 'Task two' }])

        command = create_user >> create_task

        result = command.call

        expect(result).to match_array([
          { id: 1, user_id: 1, title: 'Task one' },
          { id: 2, user_id: 1, title: 'Task two' }
        ])
      end

      it 'sets foreign key prior execution for one tuple' do
        create_user = users[:create].with(name: 'Jade')
        create_task = tasks[:create_one].with(title: 'Task one')

        command = create_user >> create_task

        result = command.call

        expect(result).to match_array(id: 1, user_id: 1, title: 'Task one')
      end
    end

    context 'without a schema' do
      include_context 'automatic FK setting' do
        before do
          configuration.commands(:tasks) do
            define(:create) do
              register_as :create_many
              associates :user, key: [:user_id, :id]
            end

            define(:create) do
              register_as :create_one
              result :one
              associates :user, key: [:user_id, :id]
            end
          end
        end
      end
    end

    context 'with a schema' do
      include_context 'automatic FK setting'

      before do
        configuration.relation_classes[1].class_eval do
          schema do
            attribute :id, ROM::SQL::Types::Serial
            attribute :user_id, ROM::SQL::Types::ForeignKey(:users)
            attribute :title, ROM::SQL::Types::String

            associations do
              many_to_one :users, as: :user
              one_to_many :task_tags
              one_to_many :tags, through: :task_tags
            end
          end
        end

        configuration.commands(:tasks) do
          define(:create) do
            register_as :create_many
            associates :user
          end

          define(:create) do
            register_as :create_one
            result :one
            associates :user
          end
        end
      end

      context 'with many-to-many association' do
        before do
          configuration.relation(:tags) do
            schema do
              attribute :id, ROM::SQL::Types::Serial
              attribute :name, ROM::SQL::Types::String

              associations do
                one_to_many :task_tags
                one_to_many :tasks, through: :task_tags
              end
            end
          end

          configuration.relation(:task_tags) do
            schema do
              attribute :tag_id, ROM::SQL::Types::ForeignKey(:tags)
              attribute :task_id, ROM::SQL::Types::ForeignKey(:tasks)

              primary_key :tag_id, :task_id

              associations do
                many_to_one :tags
                many_to_one :tasks
              end
            end
          end

          configuration.commands(:tasks) do
            define(:create) do
              result :one
              associates :user
            end
          end

          configuration.commands(:tags) do
            define(:create) do
              associates :tasks
            end
          end
        end

        it 'sets FKs for the join table' do
          create_user = users[:create].with(name: 'Jade')
          create_task = tasks[:create].with(title: "Jade's task")
          create_tags = tags[:create].with([{ name: 'red' }, { name: 'blue' }])

          command = create_user >> create_task >> create_tags

          result = command.call
          tags = relations[:tasks].schema.associations[:tags].call(relations).to_a

          expect(result).to eql([
            { id: 1, name: 'red' }, { id: 2, name: 'blue' }
          ])

          expect(tags).to eql([
            { id: 1, task_id: 1, name: 'red' },
            { id: 2, task_id: 1, name: 'blue' }
          ])
        end
      end
    end

    it 'raises when already defined' do
      expect {
        configuration.commands(:tasks) do
          define(:create) do
            result :one
            associates :user, key: [:user_id, :id]
            associates :user, key: [:user_id, :id]
          end
        end
      }.to raise_error(ArgumentError, /user/)
    end
  end
end
