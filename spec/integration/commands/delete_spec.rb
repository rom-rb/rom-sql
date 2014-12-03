require 'spec_helper'

describe 'Commands / Delete' do
  include_context 'users and tasks'

  subject(:users) { rom.commands.users }

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
    result = users.try { delete }

    expect(result.value.to_a).to match_array([])
  end

  it 'deletes all tuples in a restricted relation' do
    result = users.try { delete(:by_name, 'Jane').execute }

    expect(result.value.to_a).to match_array([{ id: 2, name: 'Jane' }])
  end
end
