RSpec.describe ROM::Relation, '#dataset' do
  subject(:relation) { container.relations.users }

  include_context 'users and tasks'

  let(:dataset) { container.gateways[:default].dataset(:users) }

  with_adapters do
    context 'with schema' do
      before do
        conf.relation(:users) do
          schema do
            attribute :id, ROM::SQL::Types::Serial
            attribute :name, ROM::SQL::Types::String
          end
        end
      end

      it 'uses schema to infer default dataset' do
        expect(relation.dataset.sql).to eql(dataset.select(:id, :name).order(Sequel.qualify(:users, :id)).sql)
      end
    end

    context 'with cherry-picked attributes in schema' do
      before do
        conf.relation(:users) do
          schema do
            attribute :id, ROM::SQL::Types::Serial
          end
        end
      end

      it 'uses schema to infer default dataset' do
        expect(relation.dataset.sql).to eql(dataset.select(:id).order(Sequel.qualify(:users, :id)).sql)
      end
    end

    context 'without schema' do
      before do
        conf.relation(:users)
      end

      it 'selects all qualified columns and sorts by pk' do
        expect(relation.dataset.sql).to eql(dataset.select(*relation.columns).order(Sequel.qualify(:users, :id)).sql)
      end
    end
  end
end
