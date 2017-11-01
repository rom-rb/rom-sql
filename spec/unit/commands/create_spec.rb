require 'rom/sql/commands/create'

RSpec.describe ROM::SQL::Commands::Create do
  subject(:command) do
    relations[:books].command(:create)
  end

  include_context 'database setup'

  with_adapters do
    after do
      conn.drop_table?(:books)
    end

    describe '#call' do
      before do
        conn.create_table :books do
          primary_key :id
          column :author, String
          column :title, String
        end

        conf.relation(:books) do
          schema do
            attribute :id, ROM::SQL::Types::Serial
            attribute :title, ROM::SQL::Types::String
          end
        end
      end

      it 'returns a tuple matching custom schema' do
        expect(command.call(title: 'Hello World')).to eql(id: 1, title: 'Hello World')
      end
    end
  end
end
