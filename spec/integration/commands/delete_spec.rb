RSpec.describe 'Commands / Delete' do
  include_context 'users and tasks'

  let(:delete_user) { user_commands.delete }

  with_adapters do
    before do
      conf.relation(:users) do
        def by_name(name)
          where(name: name)
        end
      end

      conf.commands(:users) do
        define(:delete) do
          result :one
        end
      end

      users.insert(id: 3, name: 'Jade')
      users.insert(id: 4, name: 'John')
    end

    describe '#transaction' do
      it 'deletes in normal way if no error raised' do
        expect {
          delete_user.transaction do
            delete_user.by_name('Jade').call
          end
        }.to change { users.count }.by(-1)
      end

      it 'deletes nothing if error was raised' do
        expect {
          delete_user.transaction do
            delete_user.by_name('Jade').call
            raise ROM::SQL::Rollback
          end
        }.to_not change { users.count }
      end
    end

    describe '#call' do
      it 'deletes all tuples in a restricted relation' do
        result = user_commands.try { delete_user.by_name('Jade').call }

        expect(result.value).to eql(id: 3, name: 'Jade')
      end

      it 're-raises database error' do
        command = delete_user.by_name('Jade')

        expect(command.relation).to receive(:delete).and_raise(
          Sequel::DatabaseError, 'totally wrong'
        )

        expect {
          user_commands.try { command.call }
        }.to raise_error(ROM::SQL::DatabaseError, /totally wrong/)
      end
    end

    describe '#execute' do
      context 'with a single record' do
        it 'materializes the result' do
          result = container.command(:users).delete.by_name(%w(Jade)).execute
          expect(result).to eq([
            { id: 3, name: 'Jade' }
          ])
        end
      end

      context 'with multiple records' do
        it 'materializes the results' do
          result = container.command(:users).delete.by_name(%w(Jade John)).execute
          expect(result).to eq([
            { id: 3, name: 'Jade' },
            { id: 4, name: 'John' }
          ])
        end
      end
    end
  end
end
