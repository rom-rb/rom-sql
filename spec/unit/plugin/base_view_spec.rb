RSpec.describe 'Plugin / Base View' do
  include_context 'database setup'

  with_adapters do
    it 'defines base view' do
      module Test
        class Users < ROM::Relation[:sql]
          dataset :users
          register_as :users
        end
      end

      configuration.register_relation(Test::Users)

      expect(container.relation(:users).base.header).to match_array([:id, :name])
    end
  end
end
