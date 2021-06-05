require "spec_helper"

RSpec.describe ROM::SQL::Attribute, :postgres do
  include_context "users and tasks"

  let(:ds) { users.dataset }

  describe "#is" do
    context "with a standard value" do
      it "returns a boolean expression" do
        expect(users[:id].is(1).sql_literal(ds)).to eql('("users"."id" = 1)')
      end

      it "returns a boolean equality expression for attribute" do
        expect((users[:id].is(1)).sql_literal(ds)).to eql('("users"."id" = 1)')
      end
    end

    context "with a nil value" do
      it "returns an IS NULL expression" do
        expect(users[:id].is(nil).sql_literal(ds)).to eql('("users"."id" IS NULL)')
      end

      it "returns an IS NULL expression for attribute" do
        expect((users[:id].is(nil)).sql_literal(ds)).to eql('("users"."id" IS NULL)')
      end
    end

    context "with a boolean true" do
      it "returns an IS TRUE expression" do
        expect(users[:id].is(true).sql_literal(ds)).to eql('("users"."id" IS TRUE)')
      end

      it "returns an IS TRUE expression for attribute" do
        expect((users[:id].is(true)).sql_literal(ds)).to eql('("users"."id" IS TRUE)')
      end
    end

    context "with a boolean false" do
      it "returns an IS FALSE expression" do
        expect((users[:id].is(false)).sql_literal(ds)).to eql('("users"."id" IS FALSE)')
      end
    end
  end

  describe "#not" do
    context "with a standard value" do
      it "returns a negated boolean equality expression" do
        expect((users[:id].not(1)).sql_literal(ds)).to eql('("users"."id" != 1)')
      end
    end

    context "with a nil value" do
      it "returns an IS NOT NULL expression" do
        expect(users[:id].not(nil).sql_literal(ds)).to eql('("users"."id" IS NOT NULL)')
      end
    end

    context "with a boolean true" do
      it "returns an IS NOT TRUE expression" do
        expect((users[:id].not(true)).sql_literal(ds)).to eql('("users"."id" IS NOT TRUE)')
      end
    end

    context "with a boolean false" do
      it "returns an IS NOT FALSE expression" do
        expect(users[:id].not(false).sql_literal(ds)).to eql('("users"."id" IS NOT FALSE)')
      end
    end
  end

  describe "#!" do
    it "returns a new attribute with negated sql expr" do
      expect((!users[:id].is(1)).sql_literal(ds)).to eql('("users"."id" != 1)')
    end
  end

  describe "#concat" do
    it "returns a concat function attribute" do
      expect(users[:id].concat(users[:name]).as(:uid).sql_literal(ds)).
        to eql(%(CONCAT("users"."id", ' ', "users"."name") AS "uid"))
    end
  end

  describe "#case" do
    it "builds a CASE expression based on attribute" do
      string_type = ROM::SQL::Attribute[ROM::SQL::Types::String]
      mapping = {
        1 => string_type.value("first"),
        else: string_type.value("second")
      }
      expect(users[:id].case(mapping).as(:mapped_id).sql_literal(ds)).
        to eql(%[(CASE "users"."id" WHEN 1 THEN 'first' ELSE 'second' END) AS "mapped_id"])
    end
  end

  describe "#aliased" do
    it "can alias a previously aliased attribute" do
      expect(users[:id].as(:uid).as(:uuid).sql_literal(ds)).
        to eql(%("users"."id" AS "uuid"))
    end
  end

  describe "extensions" do
    before do
      ROM::SQL::TypeExtensions.instance_variable_get(:@types)["sqlite"].delete("custom")

      ROM::SQL::TypeExtensions.register(type) do
        def custom(_type, _expr, value)
          ROM::SQL::Attribute[ROM::SQL::Types::Bool].
            meta(sql_expr: Sequel::SQL::BooleanExpression.new(:'=', 1, value))
        end
      end
    end

    let(:equality_expr) { Sequel::SQL::BooleanExpression.new(:'=', 1, 2) }

    shared_context "type methods" do
      it "successfully invokes type-specific methods" do
        expect(attribute.custom(2)).
          to eql(ROM::SQL::Attribute[ROM::SQL::Types::Bool].meta(sql_expr: equality_expr))
      end
    end

    let(:type) { Dry::Types["integer"].meta(database: "sqlite", db_type: "custom") }

    context "plain type" do
      subject(:attribute) { ROM::SQL::Attribute[type] }

      include_context "type methods"
    end

    context "optional type" do
      subject(:attribute) { ROM::SQL::Attribute[type.optional] }

      include_context "type methods"
    end

    context "default type" do
      subject(:attribute) { ROM::SQL::Attribute[type.default(42)] }

      include_context "type methods"
    end

    context "optional with default" do
      subject(:attribute) { ROM::SQL::Attribute[type.optional.default(42)] }

      include_context "type methods"
    end
  end
end
