require 'spec_helper'

describe 'Sequel dataset extensions' do
  include_context 'users and tasks'

  subject(:users) { rom.relations.users }

  before { setup.relation(:users) }

  describe '#rename' do
    it 'projects the dataset using new column names' do
      renamed = users.rename(id: :user_id, name: :user_name)

      expect(renamed.to_a).to eql([{ user_id: 1, user_name: 'Piotr'}])
    end
  end

  describe '#prefix' do
    it 'projects the dataset using new column names' do
      prefixed = users.prefix(:user)

      expect(prefixed.to_a).to eql([{ user_id: 1, user_name: 'Piotr'}])
    end
  end
end
