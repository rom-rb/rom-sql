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

    it 'sets foreign key prior execution for many tuples' do
      configuration.commands(:tasks) do
        define(:create) do
          associates :user, key: [:user_id, :id]
        end
      end

      create_user = users[:create].with(name: 'Jade')
      create_task = tasks[:create].with([{ title: 'Task one' }, { title: 'Task two' }])

      command = create_user >> create_task

      result = command.call

      expect(result).to match_array([
        { id: 1, user_id: 1, title: 'Task one' },
        { id: 2, user_id: 1, title: 'Task two' }
      ])
    end

    it 'sets foreign key prior execution for one tuple' do
      configuration.commands(:tasks) do
        define(:create) do
          result :one
          associates :user, key: [:user_id, :id]
        end
      end

      create_user = users[:create].with(name: 'Jade')
      create_task = tasks[:create].with(title: 'Task one')

      command = create_user >> create_task

      result = command.call

      expect(result).to match_array(id: 1, user_id: 1, title: 'Task one')
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
