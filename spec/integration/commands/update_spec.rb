require 'spec_helper'

describe 'Commands / Update' do
  include_context 'users and tasks'

  before do
    UserUpdateValidator = Class.new do
      attr_reader :errors

      def self.call(input)
        new
      end

      def initialize
        @errors = errors
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

    command.execute(name: 'Peter').on_success { |tuples|
      expect(tuples.to_a).to match_array([{ id: 1, name: 'Peter' }])
    }
  end
end
