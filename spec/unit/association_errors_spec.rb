require 'spec_helper'

describe 'Association errors' do
  include_context 'users and tasks'

  describe 'accessing an undefined association' do
    specify do
      setup.relation(:users) do
        def with_undefined
          association_join(:undefined)
        end
      end

      expect {
        rom.relations.users.with_undefined
      }.to raise_error ROM::SQL::NoAssociationError, 'Association :undefined has not been defined for relation :users'
    end
  end
end

