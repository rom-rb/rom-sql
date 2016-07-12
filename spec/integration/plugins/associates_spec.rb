RSpec.describe 'Plugins / :associates' do
  include_context 'relations'

  context 'with Create command' do
    subject(:users) { container.commands[:users] }
    subject(:tasks) { container.commands[:tasks] }

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
      include_context 'automatic FK setting', schema: true do
        before do
          configuration.relation_classes[1].class_eval do
            schema do
              attribute :id, ROM::SQL::Types::Serial
              attribute :user_id, ROM::SQL::Types::ForeignKey(:users)
              attribute :title, ROM::SQL::Types::String

              associate do
                belongs :users, as: :user
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
