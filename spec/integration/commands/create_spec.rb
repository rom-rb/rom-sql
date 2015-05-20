require 'spec_helper'
require 'virtus'

describe 'Commands / Create' do
  include_context 'database setup'

  subject(:users) { rom.commands.users }
  subject(:tasks) { rom.commands.tasks }

  before do
    class Params
      include Virtus.model

      attribute :name

      def self.[](input)
        new(input)
      end
    end

    setup.commands(:users) do
      define(:create) do
        input Params

        validator -> tuple {
          raise ROM::CommandError.new('name cannot be empty') if tuple[:name] == ''
        }

        result :one
      end

      define(:create_many, type: :create) do
        result :many
      end
    end

    setup.commands(:tasks) do
      define(:create)
    end

    setup.relation(:users)
    setup.relation(:tasks)
  end

  context '#transaction' do
    it 'creates record if nothing was raised' do
      result = users.create.transaction {
        users.create.call(name: 'Jane')
      }

      expect(result.value).to eq(id: 1, name: 'Jane')
    end

    it 'allows for nested transactions' do
      result = users.create.transaction {
        users.create.transaction {
          users.create.call(name: 'Jane')
        }
      }

      expect(result.value).to eq(id: 1, name: 'Jane')
    end

    it 'creates nothing if command error was raised' do
      expect {
        passed = false

        result = users.create.transaction {
          users.create.call(name: 'Jane')
          users.create.call(name: '')
        } >-> value {
          passed = true
        }

        expect(result.value).to be(nil)
        expect(result.error.message).to eql('name cannot be empty')
        expect(passed).to be(false)
      }.to_not change { rom.relations.users.count }
    end

    it 'creates nothing if rollback was raised' do
      expect {
        passed = false

        result = users.create.transaction {
          users.create.call(name: 'Jane')
          users.create.call(name: 'John')
          raise ROM::SQL::Rollback
        } >-> value {
          passed = true
        }

        expect(result.value).to be(nil)
        expect(result.error).to be(nil)
        expect(passed).to be(false)
      }.to_not change { rom.relations.users.count }
    end

    it 'creates nothing if constraint error was raised' do
      expect {
        begin
          passed = false

          users.create.transaction {
            users.create.call(name: 'Jane')
            users.create.call(name: 'Jane')
          } >-> value {
            passed = true
          }
        rescue => error
          expect(error).to be_instance_of(ROM::SQL::UniqueConstraintError)
          expect(passed).to be(false)
        end
      }.to_not change { rom.relations.users.count }
    end

    it 'creates nothing if anything was raised in any nested transaction' do
      expect {
        expect {
          users.create.transaction {
            users.create.call(name: 'John')
            users.create.transaction {
              users.create.call(name: 'Jane')
              raise Exception
            }
          }
        }.to raise_error(Exception)
      }.to_not change { rom.relations.users.count }
    end
  end

  it 'returns a single tuple when result is set to :one' do
    result = users.try { users.create.call(name: 'Jane') }

    expect(result.value).to eql(id: 1, name: 'Jane')
  end

  it 'returns tuples when result is set to :many' do
    result = users.try do
      users.create_many.call([{ name: 'Jane' }, { name: 'Jack' }])
    end

    expect(result.value.to_a).to match_array([
      { id: 1, name: 'Jane' }, { id: 2, name: 'Jack' }
    ])
  end

  it 're-raises not-null constraint violation error' do
    expect {
      users.try { users.create.call(name: nil) }
    }.to raise_error(ROM::SQL::NotNullConstraintError, /not-null/)
  end

  it 're-raises uniqueness constraint violation error' do
    expect {
      users.try {
        users.create.call(name: 'Jane')
      } >-> user {
        users.try { users.create.call(name: user[:name]) }
      }
    }.to raise_error(ROM::SQL::UniqueConstraintError, /unique/)
  end

  it 're-raises check constraint violation error' do
    expect {
      users.try {
        users.create.call(name: 'J')
      }
    }.to raise_error(ROM::SQL::CheckConstraintError, /name/)
  end

  it 're-raises fk constraint violation error' do
    expect {
      tasks.try {
        tasks.create.call(user_id: 918273645)
      }
    }.to raise_error(ROM::SQL::ForeignKeyConstraintError, /user_id/)
  end

  it 're-raises database errors' do
    expect {
      Params.attribute :bogus_field
      users.try { users.create.call(name: 'some name', bogus_field: 23) }
    }.to raise_error(ROM::SQL::DatabaseError)
  end

  describe '.associates' do
    it 'sets foreign key prior execution for many tuples' do
      setup.commands(:tasks) do
        define(:create) do
          associates :user, key: [:user_id, :id]
        end
      end

      create_user = rom.command(:users).create.with(name: 'Jade')

      create_task = rom.command(:tasks).create.with([
        { title: 'Task one' }, { title: 'Task two' }
      ])

      command = create_user >> create_task

      result = command.call

      expect(result).to match_array([
        { id: 1, user_id: 1, title: 'Task one' },
        { id: 2, user_id: 1, title: 'Task two' }
      ])
    end

    it 'sets foreign key prior execution for one tuple' do
      setup.commands(:tasks) do
        define(:create) do
          result :one
          associates :user, key: [:user_id, :id]
        end
      end

      create_user = rom.command(:users).create.with(name: 'Jade')
      create_task = rom.command(:tasks).create.with(title: 'Task one')

      command = create_user >> create_task

      result = command.call

      expect(result).to match_array(id: 1, user_id: 1, title: 'Task one')
    end
  end
end
