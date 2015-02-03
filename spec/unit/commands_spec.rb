require 'spec_helper'

describe ROM::SQL::Commands do
  include_context 'users and tasks'

  subject(:users) { rom.commands.users }

  before do
    setup.relation(:users)

    setup.commands(:users) do
      define(:create) do
        result :one
      end
    end
  end

  context 'postgres' do
    it 'create instance of PostgreSQL create command' do
      expect(ROM::SQL::Commands::Postgres::Create)
        .to receive(:new).and_call_original

      users.try { create(id: 1, name: 'Foo') }
    end
  end

  context 'others' do
    it 'create instance of default create command' do
      type = double(database_type: :foo)
      allow_any_instance_of(ROM::Relation).to receive(:db).and_return(type)

      expect(ROM::SQL::Commands::Create).to receive(:new).and_call_original

      users.try { create(id: 1, name: 'Foo') }
    end
  end
end
