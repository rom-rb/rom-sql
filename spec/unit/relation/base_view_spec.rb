RSpec.describe 'Relation / Base View' do
  include_context 'database setup'

  with_adapters do
    it 'defines base view' do
      module Test
        class Users < ROM::Relation[:sql]
          schema(:users, infer: true)
          register_as :users
        end
      end

      conf.register_relation(Test::Users)

      expect(container.relation(:users).base.attributes.map(&:name)).to match_array([:id, :name])
    end
  end
end
