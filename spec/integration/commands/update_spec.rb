require 'dry-struct'

RSpec.describe 'Commands / Update', seeds: false do
  include_context 'users'

  let(:profile_commands) { container.commands[:profiles] }

  let(:update_user) { user_commands[:update] }
  let(:update_profile) { profile_commands[:update] }

  let(:piotr) { users.by_name('Piotr').one }
  let(:peter) { { name: 'Peter' } }

  with_adapters do
    before do
      Test::User = Class.new(Dry::Struct) {
        attribute :id, Types::Strict::Integer
        attribute :name, Types::Strict::String
      }

      conf.relation(:users) do
        schema(infer: true)

        def by_id(id)
          where(id: id)
        end

        def by_name(name)
          where(name: name)
        end
      end

      conf.relation(:profiles) do
        schema(:users, infer: true) do
          attribute :name, Types::String.meta(alias: 'login')
        end

        def by_name(name)
          where(name: name)
        end
      end

      conf.commands(:users) do
        define(:update)
      end

      conf.commands(:profiles) do
        define(:update)
      end

      conf.mappers do
        register :users, entity: -> tuples { tuples.map { |tuple| Test::User.new(tuple) } }
      end

      users.insert(name: 'Piotr')
      users.insert(name: 'Jane')
    end

    context '#transaction' do
      it 'update record if there was no errors' do
        result = users.transaction do
          update_user.by_id(piotr[:id]).call(peter)
        end

        expect(result).to eq([{ id: 1, name: 'Peter' }])
      end

      it 'updates nothing if error was raised' do
        users.transaction do |t|
          update_user.by_id(piotr[:id]).call(peter)
          t.rollback!
        end

        expect(users.first[:name]).to eql('Piotr')
      end
    end

    describe '#call' do
      it 'updates relation tuples' do
        result = update_user.by_id(piotr[:id]).call(peter)

        expect(result.to_a).to match_array([{ id: 1, name: 'Peter' }])
      end

      it 're-raises database errors' do |example|
        expect {
          update_user.by_id(piotr[:id]).call(name: nil)
        }.to raise_error(ROM::SQL::NotNullConstraintError, /name/i)
      end

      it 'materializes single result' do
        result = update_user.by_name('Piotr').call(name: 'Pete')
        expect(result).to eq([
          { id: 1, name: 'Pete' }
        ])
      end

      it 'materializes aliased results' do
        result = update_profile.by_name('Piotr').call(name: 'Pete')

        expect(result).to eq([{login: 'Pete', id: 1}])
      end

      it 'materializes multiple results' do
        result = update_user.by_name(%w(Piotr Jane)).call(name: 'Josie')
        expect(result).to eq([
          { id: 1, name: 'Josie' },
          { id: 2, name: 'Josie' }
        ])
      end
    end
  end
end
