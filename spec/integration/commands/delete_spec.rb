require 'spec_helper'

describe 'Commands / Delete' do
  include_context 'users and tasks'

  before do
    setup.relation(:users) do
      def by_name(name)
        where(name: 'Piotr')
      end
    end

    setup.commands(:users) do
      define(:delete)
    end

    rom.relations.users.insert(id: 2, name: 'Jane')
  end

  it 'deletes all tuples' do
    command = rom.command(:users).delete

    result = command.execute

    expect(result.to_a).to match_array([])
  end

  it 'deletes all tuples in a restricted relation' do
    command = rom.command(:users).delete(:by_name, 'Jane')

    result = command.execute

    expect(result.to_a).to match_array([{ id: 2, name: 'Jane' }])
  end
end
