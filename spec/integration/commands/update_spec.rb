require 'spec_helper'

describe 'Commands / Update' do
  include_context 'users and tasks'

  subject(:users) { rom.commands.users }

  it 'works' do
    setup.relation(:users) do
      def by_name(name)
        where(name: name)
      end
    end

    setup.commands(:users) do
      define(:update) do
        input Hash
        validator proc {}
      end
    end

    result = users.try { update(:by_name, 'Piotr').set(name: 'Peter') }

    expect(result.value.to_a).to match_array([{ id: 1, name: 'Peter' }])
  end
end
