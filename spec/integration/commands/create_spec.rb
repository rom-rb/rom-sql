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
    failure = false

    command.execute(id: 2, name: 'Jane').
      on_success { |tuple|
        expect(tuple).to eql(id: 2, name: 'Jane')
    }.on_errors { |errors|
      failure = true
    }

    expect(failure).to be(false)
  end

  it 'handles not-null constraint violation error' do
    success = false

    command.execute(id: nil, name: 'Jane').
      on_errors { |errors|
        expect(errors.first).to be_instance_of(Sequel::NotNullConstraintViolation)
    }.on_success { |tuple|
      success = true
    }

    expect(success).to be(false)
  end

  it 'handles uniqueness constraint violation error' do
    success = false

    command.execute(id: 2, name: 'Piotr').
      on_errors { |errors|
      expect(errors.first).to be_instance_of(Sequel::UniqueConstraintViolation)
    }.on_success { |tuples|
      success = true
    }

    expect(success).to be(false)
  end
end
