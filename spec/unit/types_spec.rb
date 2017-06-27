require 'rom/sql/types'

RSpec.describe ROM::SQL::Types, :postgres do
  describe ROM::SQL::Types::Blob do
    it 'coerces strings to Sequel::SQL::Blob' do
      input = 'sutin'
      output = described_class[input]

      expect(output).to be_instance_of(Sequel::SQL::Blob)
      expect(output).to eql('sutin')
    end
  end

  describe '#sql_literal', helpers: true do
    subject(:base) { define_attribute(:age, :Int, source: ROM::Relation::Name.new(:users)) }

    include_context 'database setup'

    let(:ds) { container.gateways[:default][:users] }
    let(:sql_literal) { type.sql_literal(ds) }

    context 'when qualified' do
      subject(:type) { base.qualified }

      specify do
        expect(sql_literal).to eql(%("users"."age"))
      end
    end

    context 'when aliased' do
      subject(:type) { base.as(:user_age) }

      specify do
        expect(sql_literal).to eql(%("age" AS "user_age"))
      end
    end

    context 'when qualified and aliased' do
      subject(:type) { base.qualified.as(:user_age) }

      specify do
        expect(sql_literal).to eql(%("users"."age" AS "user_age"))
      end
    end

    context 'when aliased and qualified' do
      subject(:type) { base.as(:user_age).qualified }

      specify do
        expect(sql_literal).to eql(%("users"."age" AS "user_age"))
      end
    end

    context 'when qualified with a function expr' do
      subject(:type) { base.meta(sql_expr: func).qualified }

      let(:func) { Sequel::SQL::Function.new(:count, :age) }

      specify do
        expect { sql_literal }.
          to raise_error(ROM::SQL::Attribute::QualifyError, "can't qualify :age (#{func.inspect})")
      end
    end
  end
end
