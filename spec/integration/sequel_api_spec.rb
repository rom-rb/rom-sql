require 'spec_helper'

RSpec.describe 'Using legacy sequel api', :sqlite do
  include_context 'users'

  before do
    conf.relation(:users) do
      include ROM::SQL::Relation::SequelAPI
    end

    users.insert(name: 'Jane')
  end

  describe '#select' do
    it 'selects columns' do
      expect(users.select(Sequel.qualify(:users, :id), Sequel.qualify(:users, :name)).first).
        to eql(id: 1, name: 'Jane')
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

  describe '#order' do
    it 'orders relation' do
      expect(users.order(Sequel.qualify(:users, :name)).first).to eql(id: 1, name: 'Jane')
    end
  end
end
