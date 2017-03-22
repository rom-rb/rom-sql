require 'dry-struct'

RSpec.describe 'Commands / Create', :postgres, seeds: false do
  include_context 'relations'

  let(:create_user) { user_commands.create }
  let(:create_users) { user_commands.create_many }
  let(:create_task) { task_commands.create }

  before do |ex|
    module Test
      class Params < Dry::Struct
        attribute :name, Types::Strict::String.optional

        def self.[](input)
          new(input)
        end
      end
    end

    conn.add_index :users, :name, unique: true

    if sqlite?(ex)
      conn.add_index :tasks, :title, unique: true
    else
      conn.execute "ALTER TABLE tasks add CONSTRAINT tasks_title_key UNIQUE (title)"
    end

    conf.commands(:users) do
      define(:create) do
        input Test::Params

        result :one
      end

      define(:create_many, type: :create) do
        result :many
      end
    end

    conf.commands(:tasks) do
      define(:create)
    end
  end

  with_adapters do
    describe '#transaction' do
      it 'creates record if nothing was raised' do
        result = create_user.transaction {
          create_user.call(name: 'Jane')
        }

        expect(result.value).to eql(id: 1, name: 'Jane')
      end

      it 'creates multiple records if nothing was raised' do
        result = create_user.transaction {
          create_users.call([{ name: 'Jane' }, { name: 'Jack' }])
        }

        expect(result.value).to match_array([
          { id: 1, name: 'Jane' }, { id: 2, name: 'Jack' }
        ])
      end

      it 'allows for nested transactions' do
        result = create_user.transaction {
          create_user.transaction {
            create_user.call(name: 'Jane')
          }
        }

        expect(result.value).to eql(id: 1, name: 'Jane')
      end

      it 'creates nothing if command error was raised' do
        expect {
          begin
            create_user.transaction {
              create_user.call(name: 'Jane')
              create_user.call(name: nil)
            }
          rescue ROM::SQL::Error
          end
        }.to_not change { container.relations.users.count }
      end

      it 'creates nothing if rollback was raised' do
        expect {
          passed = false

          result = create_user.transaction {
            create_user.call(name: 'Jane')
            create_user.call(name: 'John')
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

            create_user.transaction {
              create_user.call(name: 'Jane')
              create_user.call(name: 'Jane')
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
            create_user.transaction {
              create_user.call(name: 'John')
              create_user.transaction {
                create_user.call(name: 'Jane')
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
      result = user_commands.try { create_user.call(name: 'Jane') }

      expect(result.value).to eql(id: 1, name: 'Jane')
    end

    it 'returns tuples when result is set to :many' do
      result = user_commands.try do
        create_users.call([{ name: 'Jane' }, { name: 'Jack' }])
      end

      expect(result.value.to_a).to match_array([
        { id: 1, name: 'Jane' }, { id: 2, name: 'Jack' }
      ])
    end

    it 're-raises not-null constraint violation error' do
      expect {
        user_commands.try { create_user.call(name: nil) }
      }.to raise_error(ROM::SQL::NotNullConstraintError)
    end

    # Because Oracle doesn't have boolean in SQL
    if !metadata[:oracle]
      context 'with puppies' do
        include_context 'puppies'

        before do
          conf.relation(:puppies) do
            schema(infer: true)
          end


          conf.commands(:puppies) do
            define(:create)
          end
        end

        it 're-raises not-null constraint violation error with nil boolean' do
          puppies = commands[:puppies]

          expect {
            puppies.try { puppies.create.call(name: 'Charlie', cute: nil) }
          }.to raise_error(ROM::SQL::NotNullConstraintError)
        end
      end
    end

    it 're-raises uniqueness constraint violation error' do
      expect {
        user_commands.try {
          create_user.call(name: 'Jane')
        } >-> user {
          user_commands.try { create_user.call(name: user[:name]) }
        }
      }.to raise_error(ROM::SQL::UniqueConstraintError)
    end

    it 're-raises fk constraint violation error' do |ex|
      expect {
        task_commands.try {
          create_task.call(user_id: 918_273_645)
        }
      }.to raise_error(ROM::SQL::ForeignKeyConstraintError)
    end

    it 're-raises database errors' do
      expect {
        user_commands.try { create_user.call(name: nil) }
      }.to raise_error(ROM::SQL::NotNullConstraintError)
    end

    describe '#execute' do
      context 'with a single record' do
        it 'materializes the result' do
          result = create_user.execute(name: 'Jane')
          expect(result).to eq([
            { id: 1, name: 'Jane' }
          ])
        end
      end

      context 'with multiple records' do
        it 'materializes the results' do
          result = create_user.execute([
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
          inferrable_relations.concat %i(user_group)
        end

        before do
          conn.create_table(:user_group) do
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

        # with a composite pk sequel returns 0 when inserting for MySQL
        if !metadata[:mysql]
          it 'materializes the result' do |ex|
            command = container.commands[:user_group][:create]
            result = command.call(user_id: 1, group_id: 2)

            pending "if sequel could use Oracle's RETURNING statement, that would be possible" if oracle?(ex)
            expect(result).to eql(user_id: 1, group_id: 2)
          end
        end
      end
    end
  end

  describe '#call' do
    it 're-raises check constraint violation error' do
      expect {
        user_commands.try {
          create_user.call(name: 'J')
        }
      }.to raise_error(ROM::SQL::CheckConstraintError, /name/)
    end

    it 're-raises constraint violation error' do
      expect {
        user_commands.try {
          create_task.call(title: '')
        }
      }.to raise_error(ROM::SQL::ConstraintError, /title/)
    end
  end

  describe '#upsert' do
    let(:task) { { title: 'task 1' } }

    before { create_task.call(task) }

    it 'raises error without upsert marker' do
      expect {
        create_task.call(task)
      }.to raise_error(ROM::SQL::UniqueConstraintError)
    end

    it 'raises no error for duplicated data' do
      expect { create_task.upsert(task) }.to_not raise_error
    end

    it 'returns record data' do
      expect(create_task.upsert(task, constraint: :tasks_title_key, update: { user_id: nil })).to eql([
        id: 1, user_id: nil, title: 'task 1'
      ])
    end
  end if PG_LTE_95
end
