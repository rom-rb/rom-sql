require 'spec_helper'

RSpec.describe ROM::SQL::Attribute, :postgres do
  include_context 'users and tasks'

  let(:ds) { users.dataset }

  describe '#is' do
    context 'with a standard value' do
      it 'returns a boolean expression' do
        expect(users[:id].is(1).sql_literal(ds)).to eql('("users"."id" = 1)')
      end

      it 'returns a boolean equality expression for attribute' do
        expect((users[:id].is(1)).sql_literal(ds)).to eql('("users"."id" = 1)')
      end
    end

    context 'with a nil value' do
      it 'returns an IS NULL expression' do
        expect(users[:id].is(nil).sql_literal(ds)).to eql('("users"."id" IS NULL)')
      end

      it 'returns an IS NULL expression for attribute' do
        expect((users[:id].is(nil)).sql_literal(ds)).to eql('("users"."id" IS NULL)')
      end
    end

    context 'with a boolean true' do
      it 'returns an IS TRUE expression' do
        expect(users[:id].is(true).sql_literal(ds)).to eql('("users"."id" IS TRUE)')
      end

      it 'returns an IS TRUE expression for attribute' do
        expect((users[:id].is(true)).sql_literal(ds)).to eql('("users"."id" IS TRUE)')
      end
    end

    context 'with a boolean false' do
      it 'returns an IS FALSE expression' do
        expect((users[:id].is(false)).sql_literal(ds)).to eql('("users"."id" IS FALSE)')
      end
    end
  end

  describe '#not' do
    context 'with a standard value' do
      it 'returns a negated boolean equality expression' do
        expect((users[:id].not(1)).sql_literal(ds)).to eql('("users"."id" != 1)')
      end
    end

    context 'with a nil value' do
      it 'returns an IS NOT NULL expression' do
        expect(users[:id].not(nil).sql_literal(ds)).to eql('("users"."id" IS NOT NULL)')
      end
    end

    context 'with a boolean true' do
      it 'returns an IS NOT TRUE expression' do
        expect((users[:id].not(true)).sql_literal(ds)).to eql('("users"."id" IS NOT TRUE)')
      end
    end

    context 'with a boolean false' do
      it 'returns an IS NOT FALSE expression' do
        expect(users[:id].not(false).sql_literal(ds)).to eql('("users"."id" IS NOT FALSE)')
      end
    end
  end

  describe '#!' do
    it 'returns a new attribute with negated sql expr' do
      expect((!users[:id].is(1)).sql_literal(ds)).to eql('("users"."id" != 1)')
    end
  end

  describe '#concat' do
    it 'returns a concat function attribute' do
      expect(users[:id].concat(users[:name]).as(:uid).sql_literal(ds)).
        to eql(%(CONCAT("users"."id", ' ', "users"."name") AS "uid"))
    end
  end
end
