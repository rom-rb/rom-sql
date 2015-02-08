require 'spec_helper'

describe 'Commands / Delete' do
  include_context 'users and tasks'

  subject(:users) { rom.commands.users }

  before do
    setup.relation(:users) do
      def by_name(name)
        where(name: name)
      end
    end

    setup.commands(:users) do
      define(:delete) do
        result :one
      end
    end

    rom.relations.users.insert(id: 2, name: 'Jane')
  end

  context '#transaction' do
    it 'delete in normal way if no error raised' do
      expect {
        users.delete.transaction do
          users.delete.by_name('Jane').call
        end
      }.to change { rom.relations.users.count }.by(-1)
    end

    it 'delete nothing if error was raised' do
      expect {
        users.delete.transaction do
          users.delete.by_name('Jane').call
          raise ROM::SQL::Rollback
        end
      }.to_not change { rom.relations.users.count }
    end
  end

  it 'raises error when tuple count does not match expectation' do
    result = users.try { users.delete.call }

    expect(result.value).to be(nil)
    expect(result.error).to be_instance_of(ROM::TupleCountMismatchError)
  end

  it 'deletes all tuples in a restricted relation' do
    result = users.try { users.delete.by_name('Jane').call }

    expect(result.value).to eql(id: 2, name: 'Jane')
  end
end
