require 'spec_helper'

describe ROM::Relation do
  include_context 'users and tasks'

  subject(:users) { rom.relations.users }

  before do
    setup.relation(:users) do
      def sorted
        order(:id)
      end
    end
  end

  describe '#project' do
    it 'projects the dataset using new column names' do
      projected = users.sorted.project(:name)

      expect(projected.header).to match_array([:name])
      expect(projected.to_a).to eql([{ name: 'Piotr'}])
    end
  end

  describe '#rename' do
    it 'projects the dataset using new column names' do
      renamed = users.sorted.rename(id: :user_id, name: :user_name)

      expect(renamed.to_a).to eql([{ user_id: 1, user_name: 'Piotr'}])
    end
  end

  describe '#prefix' do
    it 'projects the dataset using new column names' do
      prefixed = users.sorted.prefix(:user)

      expect(prefixed.to_a).to eql([{ user_id: 1, user_name: 'Piotr'}])
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
end
