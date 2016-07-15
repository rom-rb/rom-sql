require 'spec_helper'

describe ROM::Relation do
  include_context 'users and tasks'

  let(:users) { container.relations.users }
  let(:tasks) { container.relations.tasks }

  context 'with schema', adapter: :sqlite do
    let(:uri) { SQLITE_DB_URI }

    before do
      configuration.relation(:users) do
        schema do
          attribute :id, ROM::SQL::Types::Serial
          attribute :name, ROM::SQL::Types::String
        end

        def sorted
          order(:id)
        end
      end

      configuration.relation(:tasks)
    end

    describe '#dataset' do
      it 'uses schema to infer default dataset' do
        expect(container.relations[:users].dataset).to eql(
          container.gateways[:default].dataset(:users).select(:id, :name).order(:users__id)
        )
      end
    end
  end

  context 'without schema' do
    before do
      configuration.relation(:users) do
        def sorted
          order(:id)
        end
      end

      configuration.relation(:tasks)
    end

    describe '#associations' do
      it 'returns an empty association set' do
        expect(users.associations.elements).to be_empty
      end
    end

    describe '#dataset' do
      it 'selects all qualified columns and sorts by pk' do
        expect(users.dataset).to eql(
          users.select(*users.columns).order(:users__id).dataset
        )
      end
    end

    describe '#primary_key' do
      it 'returns :id by default' do
        expect(users.primary_key).to be(:id)
      end

      it 'returns configured primary key from the schema' do
        configuration.relation(:other_users) do
          schema(:users) do
            attribute :name, ROM::SQL::Types::String.meta(primary_key: true)
          end
        end

        expect(container.relations[:other_users].primary_key).to be(:name)
      end
    end

    describe '#sum' do
      it 'returns a sum' do
        expect(users.sum(:id)).to eql(3)
      end
    end

    describe '#min' do
      it 'returns a min' do
        expect(users.min(:id)).to eql(1)
      end
    end

    describe '#max' do
      it 'delegates to dataset and return value' do
        expect(users.max(:id)).to eql(2)
      end
    end

    describe '#avg' do
      it 'delegates to dataset and return value' do
        expect(users.avg(:id)).to eql(1.5)
      end
    end

    describe '#distinct' do
      it 'delegates to dataset and returns a new relation' do
        expect(users.dataset).to receive(:distinct).with(:name).and_call_original
        expect(users.distinct(:name)).to_not eq(users)
      end
    end

    describe '#exclude' do
      it 'delegates to dataset and returns a new relation' do
        expect(users.dataset)
          .to receive(:exclude).with(name: 'Jane').and_call_original
        expect(users.exclude(name: 'Jane')).to_not eq(users)
      end
    end

    describe '#invert' do
      it 'delegates to dataset and returns a new relation' do
        expect(users.dataset).to receive(:invert).and_call_original
        expect(users.invert).to_not eq(users)
      end
    end

    describe '#map' do
      it 'yields tuples' do
        result = users.map { |tuple| tuple[:name] }
        expect(result).to eql(%w(Jane Joe))
      end
    end

    describe '#inner_join' do
      it 'joins relations using inner join' do
        result = users.inner_join(:tasks, user_id: :id).select(:name, :title)

        expect(result.to_a).to eql([
          { name: 'Jane', title: "Jane's task" },
          { name: 'Joe', title: "Joe's task" }
        ])
      end

      it 'raises error when column names are ambiguous' do
        expect {
          users.inner_join(:tasks, user_id: :id).to_a
        }.to raise_error(Sequel::DatabaseError, /column reference "id" is ambiguous/)
      end
    end

    describe '#left_join' do
      it 'joins relations using left outer join' do
        result = users.left_join(:tasks, user_id: :id).select(:name, :title)

        expect(result.to_a).to match_array([
          { name: 'Joe', title: "Joe's task" },
          { name: 'Jane', title: "Jane's task" }
        ])
      end
    end

    describe '#project' do
      it 'projects the dataset using new column names' do
        projected = users.sorted.project(:name)

        expect(projected.header).to match_array([:name])
        expect(projected.first).to eql(name: 'Jane')
      end
    end

    describe '#rename' do
      it 'projects the dataset using new column names' do
        renamed = users.sorted.rename(id: :user_id, name: :user_name)

        expect(renamed.first).to eql(user_id: 1, user_name: 'Jane')
      end
    end

    describe '#prefix' do
      it 'projects the dataset using new column names' do
        prefixed = users.sorted.prefix(:user)

        expect(prefixed.first).to eql(user_id: 1, user_name: 'Jane')
      end

      it 'uses singularized table name as the default prefix' do
        prefixed = users.sorted.prefix

        expect(prefixed.first).to eql(user_id: 1, user_name: 'Jane')
      end
    end

    describe '#qualified_columns' do
      it 'returns qualified column names' do
        columns = users.sorted.prefix(:user).qualified_columns

        expect(columns).to eql([:users__id___user_id, :users__name___user_name])
      end

      it 'returns projected qualified column names' do
        columns = users.sorted.project(:id).prefix(:user).qualified_columns

        expect(columns).to eql([:users__id___user_id])
      end
    end

    describe '#inspect' do
      it 'includes dataset' do
        expect(users.inspect).to include('dataset')
      end
    end

    describe '#unique?' do
      before { tasks.delete }

      it 'returns true when there is only one tuple matching criteria' do
        expect(tasks.unique?(title: 'Task One')).to be(true)
      end

      it 'returns true when there are more than one tuple matching criteria' do
        tasks.insert(title: 'Task One')
        expect(tasks.unique?(title: 'Task One')).to be(false)
      end
    end

    describe '#union' do
      let(:relation1) { users.where(id: 1).select(:id, :name) }
      let(:relation2) { users.where(id: 2).select(:id, :name) }

      it 'unions two relations and returns a new relation' do
        result = relation1.union(relation2)

        expect(result.to_a).to match_array([
          { id: 1, name: 'Jane' },
          { id: 2, name: 'Joe' }
        ])
      end
    end
  end
end
