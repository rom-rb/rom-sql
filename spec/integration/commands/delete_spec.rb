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

  it 'raises error when tuple count does not match expectation' do
    result = users.try { delete }

    expect(result.value).to be(nil)
    expect(result.error).to be_instance_of(ROM::TupleCountMismatchError)
  end

  it 'deletes all tuples in a restricted relation' do
    result = users.try { delete(:by_name, 'Jane') }

    expect(result.value).to eql({ id: 2, name: 'Jane' })
  end
end
