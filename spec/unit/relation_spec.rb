require 'spec_helper'

describe ROM::Relation do
  include_context 'users and tasks'

  let(:users) { container.relations.users }
  let(:tasks) { container.relations.tasks }

  before do
    configuration.relation(:users) do
      def sorted
        order(:id)
      end
    end

    configuration.relation(:tasks)
  end

  describe '#dataset' do
    it 'selects all qualified columns and sorts by pk' do
      expect(users.dataset).to eql(
        users.select(*users.columns).order(:users__id).dataset
      )
    end
  end

  describe '.table_name' do
    it 'allows one to set the table name' do
      setup.relation(:my_tasks) do
        table_name :tasks
      end

      expect(rom.relations.my_tasks.model.table_name).to eq :tasks
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
        .to receive(:exclude).with(name: 'Piotr').and_call_original
      expect(users.exclude(name: 'Piotr')).to_not eq(users)
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
      expect(result).to eql(%w(Piotr))
    end
  end

  describe '#inner_join' do
    it 'joins relations using inner join' do
      conn[:users].insert(id: 2, name: 'Jane')

      result = users.inner_join(:tasks, user_id: :id).select(:name, :title)

      expect(result.to_a).to match_array([
        { name: 'Piotr', title: 'Finish ROM' }
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
      conn[:users].insert(id: 2, name: 'Jane')

      result = users.left_join(:tasks, user_id: :id).select(:name, :title)

      expect(result.to_a).to match_array([
        { name: 'Piotr', title: 'Finish ROM' },
        { name: 'Jane', title: nil }
      ])
    end
  end

  describe '#project' do
    it 'projects the dataset using new column names' do
      projected = users.sorted.project(:name)

      expect(projected.header).to match_array([:name])
      expect(projected.to_a).to eql([{ name: 'Piotr' }])
    end
  end

  describe '#rename' do
    it 'projects the dataset using new column names' do
      renamed = users.sorted.rename(id: :user_id, name: :user_name)

      expect(renamed.to_a).to eql([{ user_id: 1, user_name: 'Piotr' }])
    end
  end

  describe '#prefix' do
    it 'projects the dataset using new column names' do
      prefixed = users.sorted.prefix(:user)

      expect(prefixed.to_a).to eql([{ user_id: 1, user_name: 'Piotr' }])
    end

    it 'uses singularized table name as the default prefix' do
      prefixed = users.sorted.prefix

      expect(prefixed.to_a).to eql([{ user_id: 1, user_name: 'Piotr' }])
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
      conn[:users].insert(id: 2, name: 'Jane')

      result = relation1.union(relation2)

      expect(result.to_a).to match_array([
        { id: 1, name: 'Piotr' },
        { id: 2, name: 'Jane' }
      ])
    end
  end
end
