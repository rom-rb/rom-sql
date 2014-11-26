require 'spec_helper'

describe 'Commands / Create' do
  include_context 'users and tasks'

  before do
    UserValidator = Class.new do
      def self.call(input)
        new
      end

      def success?
        true
      end
    end
  end

  it 'works' do
    setup.relation(:users)

    setup.commands(:users) do
      define(:create) do
        input Hash
        validator UserValidator
      end
    end

    command = rom.command(:users).create

    result = command.execute(id: 2, name: 'Jane')

    expect(result).to eql(id: 2, name: 'Jane')
  end
end
