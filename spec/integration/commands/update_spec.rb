require 'spec_helper'

describe 'Commands / Update' do
  include_context 'users and tasks'

  before do
    UserUpdateValidator = Class.new do
      def self.call(input)
        new
      end

      def success?
        true
      end
    end
  end

  it 'works' do
    setup.relation(:users) do
      def by_name(name)
        where(name: name)
      end
    end

    setup.commands(:users) do
      define(:update) do
        input Hash
        validator UserUpdateValidator
      end
    end

    command = rom.command(:users).update(:by_name, 'Piotr')

    result = command.execute(name: 'Peter')

    expect(result.to_a).to match_array([{ id: 1, name: 'Peter' }])
  end
end
