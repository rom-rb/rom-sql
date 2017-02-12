require 'spec_helper'

RSpec.describe 'Using legacy sequel api', :sqlite do
  include_context 'users'

  let(:users) { relations[:users] }

  before do
    conf.relation(:users) do
      include ROM::SQL::Relation::SequelAPI
    end

    users.insert(name: 'Jane')
  end

  describe '#select' do
    it 'selects columns' do
      expect(users.select(:users__id, :users__name).first).to eql(id: 1, name: 'Jane')
    end

    it 'supports legacy blocks' do
      expect(users.select { count(id).as(:count) }.group(:id).first).to eql(count: 1)
    end
  end

  describe '#where' do
    it 'restricts relation' do
      expect(users.where(name: 'Jane').first).to eql(id: 1, name: 'Jane')
    end
  end
end
