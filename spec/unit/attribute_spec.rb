require 'spec_helper'

RSpec.describe ROM::SQL::Attribute, :postgres do
  include_context 'users and tasks'

  let(:users) { relations[:users] }
  let(:ds) { users.dataset }

  describe '#is' do
    it 'returns a boolean expression' do
      expect(users[:id].is(1).sql_literal(ds)).to eql('("id" = 1)')
    end

    it 'returns a boolean expression for qualified attribute' do
      expect((users[:id].qualified.is(1)).sql_literal(ds)).to eql('("users"."id" = 1)')
    end
  end

  describe '#concat' do
    it 'returns a concat function attribute' do
      expect(users[:id].concat(users[:name]).as(:uid).sql_literal(ds)).
        to eql(%(CONCAT("id", ' ', "name") AS "uid"))
    end
  end
end
