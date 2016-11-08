require 'dry-struct'

RSpec.describe 'Commands / Update' do
  include_context 'database setup'

  subject(:users) { container.command(:users) }

  let(:update) { container.commands[:users][:update] }

  let(:relation) { container.relations.users }
  let(:piotr) { relation.by_name('Piotr').one }
  let(:peter) { { name: 'Peter' } }

  with_adapters do
    context 'with a schema' do
      before do
        conf.relation(:users) do
          schema do
            attribute :id, ROM::SQL::Types::Serial
            attribute :name, ROM::SQL::Types::String
          end
        end
      end

      it 'uses relation schema for the default input handler' do
        conf.commands(:users) do
          define(:update) do
            result :one
          end
        end

        expect(update.input[foo: 'bar', id: 1, name: 'Jane']).to eql(
          id: 1, name: 'Jane'
        )
      end
    end

    context 'without a schema' do
      before do
        Test::User = Class.new(Dry::Struct) {
          attribute :id, Types::Strict::Int
          attribute :name, Types::Strict::String
        }

        conf.relation(:users) do
          def by_id(id)
            where(id: id).limit(1)
          end

          def by_name(name)
            where(name: name)
          end
        end

        conf.commands(:users) do
          define(:update)
        end

        conf.mappers do
          register :users, entity: -> tuples { tuples.map { |tuple| Test::User.new(tuple) } }
        end

        relation.insert(name: 'Piotr')
        relation.insert(name: 'Jane')
      end

      it 'respects configured input handler' do
        expect(update.input[foo: 'bar', id: 1, name: 'Jane']).to eql(
          foo: 'bar', id: 1, name: 'Jane'
        )
      end

      context '#transaction' do
        it 'update record if there was no errors' do
          result = users.update.transaction do
            users.update.by_id(piotr[:id]).call(peter)
          end

          expect(result.value).to eq([{ id: 1, name: 'Peter' }])
        end

        it 'updates nothing if error was raised' do
          users.update.transaction do
            users.update.by_id(piotr[:id]).call(peter)
            raise ROM::SQL::Rollback
          end

          expect(relation.first[:name]).to eql('Piotr')
        end
      end

      describe '#call' do
        it 'updates everything when there is no original tuple' do
          result = users.try do
            users.update.by_id(piotr[:id]).call(peter)
          end

          expect(result.value.to_a).to match_array([{ id: 1, name: 'Peter' }])
        end

        it 'updates when attributes changed' do
          result = users.try do
            users.as(:entity).update.by_id(piotr[:id]).change(Test::User.new(piotr)).call(peter)
          end

          expect(result.value.to_a).to match_array([Test::User.new(id: 1, name: 'Peter')])
        end

        it 'does not update when attributes did not change' do
          result = users.try do
            command = users.update.by_id(piotr[:id]).change(piotr)

            expect(command.relation).not_to receive(:update)

            command.call(name: piotr[:name])
          end

          expect(result.value.to_a).to be_empty
        end

        it 're-reaises database errors' do
          expect {
            users.try { users.update.by_id(piotr[:id]).call(bogus_field: '#trollface') }
          }.to raise_error(ROM::SQL::DatabaseError, /bogus_field/)
        end

        describe '#execute' do
          context 'with a single record' do
            it 'materializes the result' do
              result = users.update.by_name('Piotr').execute(name: 'Pete')
              expect(result).to eq([
                { id: 1, name: 'Pete' }
              ])
            end
          end

          context 'with multiple records' do
            it 'materializes the results' do
              result = users.update.by_name(%w(Piotr Jane)).execute(name: 'Josie')
              expect(result).to eq([
                { id: 1, name: 'Josie' },
                { id: 2, name: 'Josie' }
              ])
            end
          end
        end
      end
    end
  end
end
