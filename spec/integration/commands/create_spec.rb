require 'dry-struct'

RSpec.describe 'Commands / Create', :postgres do
  include_context 'relations'

  let(:users) { commands[:users] }
  let(:tasks) { commands[:tasks] }

  before do
    module Test
      class Params < Dry::Struct
        attribute :name, Types::Strict::String.optional

        def self.[](input)
          new(input)
        end
      end
    end

    conn.add_index :users, :name, unique: true

    conf.relation(:puppies) do
      schema(infer: true)
    end

    conf.commands(:users) do
      define(:create) do
        input Test::Params

        validator -> tuple {
          raise ROM::CommandError, 'name cannot be empty' if tuple[:name] == ''
        }

        result :one
      end

      define(:create_many, type: :create) do
        result :many
      end
    end

    conf.commands(:tasks) do
      define(:create)
    end

    conf.commands(:puppies) do
      define(:create)
    end
  end

  with_adapters do
    describe '#transaction' do
      it 'creates record if nothing was raised' do
        result = users.create.transaction {
          users.create.call(name: 'Jane')
        }

        expect(result.value).to eq(id: 1, name: 'Jane')
      end

      it 'creates multiple records if nothing was raised' do
        result = users.create.transaction {
          users.create_many.call([{ name: 'Jane' }, { name: 'Jack' }])
        }

        expect(result.value).to match_array([
          { id: 1, name: 'Jane' }, { id: 2, name: 'Jack' }
        ])
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
          } >-> _value {
            passed = true
          }

          expect(result.value).to be(nil)
          expect(result.error.message).to eql('name cannot be empty')
          expect(passed).to be(false)
        }.to_not change { container.relations.users.count }
      end

      it 'creates nothing if rollback was raised' do
        expect {
          passed = false

          result = users.create.transaction {
            users.create.call(name: 'Jane')
            users.create.call(name: 'John')
            raise ROM::SQL::Rollback
          } >-> _value {
            passed = true
          }

          expect(result.value).to be(nil)
          expect(result.error).to be(nil)
          expect(passed).to be(false)
        }.to_not change { container.relations.users.count }
      end

      it 'creates nothing if constraint error was raised' do
        expect {
          begin
            passed = false

            users.create.transaction {
              users.create.call(name: 'Jane')
              users.create.call(name: 'Jane')
            } >-> _value {
              passed = true
            }
          rescue => error
            expect(error).to be_instance_of(ROM::SQL::UniqueConstraintError)
            expect(passed).to be(false)
          end
        }.to_not change { container.relations.users.count }
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
        }.to_not change { container.relations.users.count }
      end
    end

    it 'uses relation schema for the default input handler' do
      conf.relation(:users) do
        register_as :users_with_schema

        schema do
          attribute :id, ROM::SQL::Types::Serial
          attribute :name, ROM::SQL::Types::String
        end
      end

      conf.commands(:users_with_schema) do
        define(:create) do
          result :one
        end
      end

      create = container.commands[:users_with_schema][:create]

      expect(create.input[foo: 'bar', id: 1, name: 'Jane']).to eql(
        id: 1, name: 'Jane'
      )
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
      }.to raise_error(ROM::SQL::NotNullConstraintError)
    end

    it 're-raises not-null constraint violation error with nil boolean' do
      puppies = commands[:puppies]

      expect {
        puppies.try { puppies.create.call(name: 'Charlie', cute: nil) }
      }.to raise_error(ROM::SQL::NotNullConstraintError)
    end

    it 're-raises uniqueness constraint violation error' do
      expect {
        users.try {
          users.create.call(name: 'Jane')
        } >-> user {
          users.try { users.create.call(name: user[:name]) }
        }
      }.to raise_error(ROM::SQL::UniqueConstraintError)
    end

    it 're-raises fk constraint violation error' do
      expect {
        tasks.try {
          tasks.create.call(user_id: 918_273_645)
        }
      }.to raise_error(ROM::SQL::ForeignKeyConstraintError)
    end

    it 're-raises database errors' do
      expect {
        Test::Params.attribute :bogus_field, Types::Int
        users.try { users.create.call(name: 'some name', bogus_field: 23) }
      }.to raise_error(ROM::SQL::DatabaseError)
    end

    it 'supports [] syntax instead of call' do
      expect {
        Test::Params.attribute :bogus_field, Types::Int
        users.try { users.create[name: 'some name', bogus_field: 23] }
      }.to raise_error(ROM::SQL::DatabaseError)
    end

    describe '#execute' do
      context 'with a single record' do
        it 'materializes the result' do
          result = container.command(:users).create.execute(name: 'Jane')
          expect(result).to eq([
            { id: 1, name: 'Jane' }
          ])
        end
      end

      context 'with multiple records' do
        it 'materializes the results' do
          result = container.command(:users).create.execute([
            { name: 'Jane' },
            { name: 'John' }
          ])
          expect(result).to eq([
            { id: 1, name: 'Jane' },
            { id: 2, name: 'John' }
          ])
        end
      end

      context 'with a composite pk' do
        before do
          conn.create_table?(:user_group) do
            primary_key [:user_id, :group_id]
            column :user_id, Integer, null: false
            column :group_id, Integer, null: false
          end

          conf.relation(:user_group) do
            schema(infer: true)
          end

          conf.commands(:user_group) do
            define(:create) { result :one }
          end
        end

        after do
          conn.drop_table(:user_group)
        end

        # with a composite pk sequel returns 0 when inserting for MySQL
        if !metadata[:mysql]
          it 'materializes the result' do
            command = container.commands[:user_group][:create]
            result = command.call(user_id: 1, group_id: 2)

            expect(result).to eql(user_id: 1, group_id: 2)
          end
        end
      end
    end
  end

  describe '#call' do
    it 're-raises check constraint violation error' do
      expect {
        users.try {
          users.create.call(name: 'J')
        }
      }.to raise_error(ROM::SQL::CheckConstraintError, /name/)
    end

    it 're-raises constraint violation error' do
      expect {
        users.try {
          tasks.create.call(title: '')
        }
      }.to raise_error(ROM::SQL::ConstraintError, /title/)
    end
  end

  describe '#upsert' do
    let(:task) { { title: 'task 1' } }

    before { tasks.create.call(task) }

    it 'raises error without upsert marker' do
      expect {
        tasks.create.call(task)
      }.to raise_error(ROM::SQL::UniqueConstraintError)
    end

    it 'raises no error for duplicated data' do
      expect { tasks.create.upsert(task) }.to_not raise_error
    end

    it 'returns record data' do
      expect(tasks.create.upsert(task, constraint: :tasks_title_key, update: { user_id: nil })).to eql([
        id: 1, user_id: nil, title: 'task 1'
      ])
    end
  end if PG_LTE_95
end
