RSpec.describe 'Association errors', :postgres do
  include_context 'users and tasks'

  describe 'accessing an undefined association' do
    specify do
      conf.relation(:users) do
        use :assoc_macros

        def with_undefined
          association_join(:undefined)
        end
      end

      expect {
        container.relations.users.with_undefined
      }.to raise_error ROM::SQL::NoAssociationError, 'Association :undefined has not been defined for relation :users'
    end
  end
end
