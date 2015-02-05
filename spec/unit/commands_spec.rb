require 'spec_helper'

describe ROM::SQL::Commands do
  include_context 'database setup'

  subject(:users) { rom.commands.users }

  before do
    setup.relation(:users) do
      def by_id(id)
        where(id: id)
      end
    end

    setup.commands(:users) do
      define(:create) do
        result :one
      end

      define(:update) do
        result :one
      end
    end
  end

  context 'postgres' do
    it 'creates instance of PostgreSQL create command' do
      expect(ROM::SQL::Commands::Postgres::Create)
        .to receive(:new).and_call_original

      users.try { create(id: 1, name: 'Foo') }
    end

    it 'creates instance of PostgreSQL update command' do
      expect(ROM::SQL::Commands::Postgres::Update)
        .to receive(:new).and_call_original.twice

      users.try { update(:by_id, 1).set(name: 'Foo') }
    end
  end

  context 'others' do
    it 'creates instance of default create command' do
      type = double(database_type: :foo)
      allow_any_instance_of(ROM::Relation).to receive(:db).and_return(type)

      expect(ROM::SQL::Commands::Create).to receive(:new).and_call_original

      users.try { create(id: 1, name: 'Foo') }
    end

    it 'creates instance of default update command' do
      type = double(database_type: :foo)
      allow_any_instance_of(ROM::Relation).to receive(:db).and_return(type)

      expect(ROM::SQL::Commands::Update).to receive(:new).and_call_original.twice

      users.try { update(:by_id, 1).set(name: 'Foo') }
    end
  end
end
