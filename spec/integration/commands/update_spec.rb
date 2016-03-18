require 'spec_helper'
require 'anima'

describe 'Commands / Update' do
  include_context 'database setup'

  subject(:users) { container.command(:users) }

  let(:update) { container.commands[:users][:update] }

  let(:relation) { container.relations.users }
  let(:piotr) { relation.by_name('Piotr').one }
  let(:peter) { { name: 'Peter' } }

  context 'with a schema' do
    before do
      configuration.relation(:users) do
        schema do
          attribute :id, ROM::SQL::Types::Serial
          attribute :name, ROM::SQL::Types::String
        end
      end
    end

    it 'uses relation schema for the default input handler' do
      configuration.commands(:users) do
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
      configuration.relation(:users) do
        def by_id(id)
          where(id: id).limit(1)
        end

        def by_name(name)
          where(name: name)
        end
      end

      configuration.commands(:users) do
        define(:update)
      end

      User = Class.new { include Anima.new(:id, :name) }

      configuration.mappers do
        register :users, entity: -> tuples { tuples.map { |tuple| User.new(tuple) } }
      end

      relation.insert(name: 'Piotr')
    end

    after { Object.send(:remove_const, :User) }

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

        expect(relation.one[:name]).to eql('Piotr')
      end
    end

    it 'updates everything when there is no original tuple' do
      result = users.try do
        users.update.by_id(piotr[:id]).call(peter)
      end

      expect(result.value.to_a).to match_array([{ id: 1, name: 'Peter' }])
    end

    it 'updates when attributes changed' do
      result = users.try do
        users.as(:entity).update.by_id(piotr[:id]).change(User.new(piotr)).call(peter)
      end

      expect(result.value.to_a).to match_array([User.new(id: 1, name: 'Peter')])
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
  end
end
