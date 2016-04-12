require 'spec_helper'

describe 'Commands / Delete' do
  include_context 'users and tasks'

  subject(:users) { container.commands.users }

  before do
    configuration.relation(:users) do
      def by_name(name)
        where(name: name)
      end
    end

    configuration.commands(:users) do
      define(:delete) do
        result :one
      end
    end

    container.relations.users.insert(id: 2, name: 'Jane')
    container.relations.users.insert(id: 3, name: 'John')
  end

  describe '#transaction' do
    it 'deletes in normal way if no error raised' do
      expect {
        users.delete.transaction do
          users.delete.by_name('Jane').call
        end
      }.to change { container.relations.users.count }.by(-1)
    end

    it 'deletes nothing if error was raised' do
      expect {
        users.delete.transaction do
          users.delete.by_name('Jane').call
          raise ROM::SQL::Rollback
        end
      }.to_not change { container.relations.users.count }
    end
  end

  describe '#call' do
    it 'raises error when tuple count does not match expectation' do
      result = users.try { users.delete.call }

      expect(result.value).to be(nil)
      expect(result.error).to be_instance_of(ROM::TupleCountMismatchError)
    end

    it 'deletes all tuples in a restricted relation' do
      result = users.try { users.delete.by_name('Jane').call }

      expect(result.value).to eql(id: 2, name: 'Jane')
    end

    it 're-raises database error' do
      command = users.delete.by_name('Jane')

      expect(command.relation).to receive(:delete).and_raise(
        Sequel::DatabaseError, 'totally wrong'
      )

      expect {
        users.try { command.call }
      }.to raise_error(ROM::SQL::DatabaseError, /totally wrong/)
    end
  end

  describe '#execute' do
    context 'with postgres adapter' do
      context 'with a single record' do
        it 'materializes the result' do
          result = container.command(:users).delete.by_name(%w(Jane)).execute
          expect(result).to eq([
            { id: 2, name: 'Jane' }
          ])
        end
      end

      context 'with multiple records' do
        it 'materializes the results' do
          result = container.command(:users).delete.by_name(%w(Jane John)).execute
          expect(result).to eq([
            { id: 2, name: 'Jane' },
            { id: 3, name: 'John' }
          ])
        end
      end
    end

    context 'with other adapter', adapter: :sqlite do
      let(:uri) { SQLITE_DB_URI }
      
      context 'with a single record' do
        it 'materializes the result' do
          result = container.command(:users).delete.by_name(%w(Jane)).execute
          expect(result).to eq([
            { id: 2, name: 'Jane' }
          ])
        end
      end

      context 'with multiple records' do
        it 'materializes the results' do
          result = container.command(:users).delete.by_name(%w(Jane John)).execute
          expect(result).to eq([
            { id: 2, name: 'Jane' },
            { id: 3, name: 'John' }
          ])
        end
      end
    end
  end
end
