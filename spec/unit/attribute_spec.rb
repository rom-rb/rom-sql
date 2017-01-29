require 'spec_helper'

RSpec.describe ROM::SQL::Attribute, :postgres do
  describe '#concat' do
    include_context 'users and tasks'

    let(:users) { relations[:users] }
    let(:ds) { users.dataset }

    it 'returns a concat function attribute' do
      expect(users[:id].concat(users[:name]).as(:uid).sql_literal(ds)).
        to eql(%(CONCAT("id", ' ', "name") AS "uid"))
    end
  end
end
