require 'spec_helper'

describe 'Commands / Create' do
  include_context 'users and tasks'

  subject(:command) { rom.command(:users).create }

  before :all do
    UserValidator = Class.new do
      attr_reader :errors

      def self.call(input)
        new
      end

      def initialize
        @errors = []
      end

      def success?
        true
      end
    end
  end

  before do
    setup.relation(:users)

    setup.commands(:users) do
      define(:create) do
        input Hash
        validator UserValidator
      end
    end
  end

  it 'works' do
    command.execute(id: 2, name: 'Jane').on_success { |tuple|
      expect(tuple).to eql(id: 2, name: 'Jane')
    }
  end

  it 'handles not-null constraint violation error' do
    command.execute(id: nil, name: 'Jane').on_errors { |errors|
      expect(errors.first).to include('null value in column "id" violates not-null constraint')
    }
  end

  it 'handles uniqueness constraint violation error' do
    command.execute(id: 2, name: 'Piotr').on_errors { |errors|
      expect(errors.first).to include('Key (name)=(Piotr) already exists')
    }
  end
end
