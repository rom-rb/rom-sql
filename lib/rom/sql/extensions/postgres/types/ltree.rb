# frozen_string_literal: true

require 'rom/types/values'

module ROM
  module SQL
    module Postgres
      # @api public
      module Types
        # @see https://www.postgresql.org/docs/current/static/ltree.html

        LTree = Type('ltree') do
          SQL::Types.define(ROM::Types::Values::TreePath) do
            input do |label_path|
              label_path.to_s
            end

            output do |label_path|
              ROM::Types::Values::TreePath.new(label_path.to_s) if label_path
            end
          end
        end

        # @!parse
        #   class SQL::Attribute
        #     # @!method match(value)
        #     #   Check whether the LTree match a lquery value
        #     #   Translates to the ~ operator
        #     #
        #     #   @example
        #     #     people.select(:name).where { ltree_tags.match('Bottom.Cities') }
        #     #
        #     #   @param [String] value
        #     #
        #     #   @return [SQL::Attribute<Types::Bool>]
        #     #
        #     #   @api public
        #
        #     # @!method match_any(value)
        #     #   Check whether the LTree match any of the lquery values
        #     #   Translates to the ? operator
        #     #
        #     #   @example
        #     #     people.select(:name).where { ltree_tags.match_any(['Bottom', 'Bottom.Cities.*']) }
        #     #     people.select(:name).where { ltree_tags.match_any('Bottom,Bottom.Cities.*') }
        #     #
        #     #   @param [Array,String] value
        #     #
        #     #   @return [SQL::Attribute<Types::Bool>]
        #     #
        #     #   @api public
        #
        #     # @!method match_ltextquery(value)
        #     #   Check whether the LTree match a ltextquery
        #     #   Translates to the @ operator
        #     #
        #     #   @example
        #     #     people.select(:name).where { ltree_tags.match_ltextquery('Countries & Brasil') }
        #     #
        #     #   @param [String] value
        #     #
        #     #   @return [SQL::Attribute<Types::Bool>]
        #     #
        #     #   @api public
        #
        #     # @!method contain_descendant(value)
        #     #   Check whether the LTree is a descendant of the LTree values
        #     #   Translates to the <@ operator
        #     #
        #     #   @example
        #     #     people.select(:name).where { ltree_tags.contain_descendant(['Bottom.Cities']) }
        #     #     people.select(:name).where { ltree_tags.contain_descendant('Bottom.Cities, Bottom.Parks') }
        #     #
        #     #   @param [Array<String>, String] value
        #     #
        #     #   @return [SQL::Attribute<Types::Bool>]
        #     #
        #     #   @api public
        #
        #     # @!method descendant(value)
        #     #   Check whether the LTree is a descendant of the LTree value
        #     #   Translates to the <@ operator
        #     #
        #     #   @example
        #     #     people.select(:name).where { ltree_tags.descendant('Bottom.Cities') }
        #     #
        #     #   @param [String] value
        #     #
        #     #   @return [SQL::Attribute<Types::Bool>]
        #     #
        #     #   @api public
        #
        #     # @!method contain_ascendant(value)
        #     #   Check whether the LTree is a ascendant of the LTree values
        #     #   Translates to the @> operator
        #     #
        #     #   @example
        #     #     people.select(:name).where { ltree_tags.contain_ascendant(['Bottom.Cities']) }
        #     #     people.select(:name).where { ltree_tags.contain_ascendant('Bottom.Cities, Bottom.Parks') }
        #     #
        #     #   @param [Array<String>, String] value
        #     #
        #     #   @return [SQL::Attribute<Types::Bool>]
        #     #
        #     #   @api public
        #
        #     # @!method ascendant(value)
        #     #   Check whether the LTree is a ascendant of the LTree value
        #     #   Translates to the @> operator
        #     #
        #     #   @example
        #     #     people.select(:name).where { ltree_tags.ascendant('Bottom.Cities') }
        #     #
        #     #   @param [String] value
        #     #
        #     #   @return [SQL::Attribute<Types::Bool>]
        #     #
        #     #   @api public
        #
        #     # @!method +(value)
        #     #   Concatenate two LTree values
        #     #   Translates to ||
        #     #
        #     #   @example
        #     #     people.select { (ltree_tags + ROM::Types::Values::TreePath.new('Moscu')).as(:ltree_tags) }.where { name.is('Jade Doe') }
        #     #     people.select { (ltree_tags + 'Moscu').as(:ltree_tags) }.where { name.is('Jade Doe') }
        #     #
        #     #   @param [LTree, String] keys
        #     #
        #     #   @return [SQL::Attribute<Types::LTree>]
        #     #
        #     #   @api public
        #
        #     # @!method contain_any_ltextquery(value)
        #     #   Does LTree array contain any path matching ltxtquery
        #     #   Translates to @
        #     #
        #     #   @example
        #     #     people.select(:name).where { parents_tags.contain_any_ltextquery('Parks')}
        #     #
        #     #   @param [String] value
        #     #
        #     #   @return [SQL::Attribute<Types::Bool>]
        #     #
        #     #   @api public
        #
        #     # @!method contain_ancestor(value)
        #     #   Does LTree array contain an ancestor of ltree
        #     #   Translates to @>
        #     #
        #     #   @example
        #     #     people.select(:name).where { parents_tags.contain_ancestor('Top.Building.EmpireState.381')}
        #     #
        #     #   @param [String] value
        #     #
        #     #   @return [SQL::Attribute<Types::PG::Bool>]
        #     #
        #     #   @api public
        #
        #     # @!method contain_descendant(value)
        #     #   Does LTree array contain an descendant of ltree
        #     #   Translates to <@
        #     #
        #     #   @example
        #     #     people.select(:name).where { parents_tags.contain_descendant('Top.Building.EmpireState.381')}
        #     #
        #     #   @param [String] value
        #     #
        #     #   @return [SQL::Attribute<Types::PG::Bool>]
        #     #
        #     #   @api public
        #
        #     # @!method find_ancestor(value)
        #     #   Return first LTree array entry that is an ancestor of ltree, NULL if none
        #     #   Translates to ?@>
        #     #
        #     #   @example
        #     #     people.select(:name).where { parents_tags.find_ancestor('Left.Parks').not(nil)}
        #     #
        #     #   @param [String] value
        #     #
        #     #   @return [SQL::Attribute<Types::PG::LTree>]
        #     #
        #     #   @api public
        #
        #     # @!method find_descendant(value)
        #     #   Return first LTree array entry that is an descendant of ltree, NULL if none
        #     #   Translates to ?<@
        #     #
        #     #   @example
        #     #     people.select(:name).where { parents_tags.find_descendant('Left.Parks').not(nil)}
        #     #
        #     #   @param [String] value
        #     #
        #     #   @return [SQL::Attribute<Types::PG::LTree>]
        #     #
        #     #   @api public
        #
        #     # @!method match_any_lquery(value)
        #     #   Return first LTree array entry that matches lquery, NULL if none
        #     #   Translates to ?~
        #     #
        #     #   @example
        #     #     people.select(:name).where { parents_tags.match_any_lquery('Right.*').not(nil)}
        #     #
        #     #   @param [String] value
        #     #
        #     #   @return [SQL::Attribute<Types::PG::LTree>]
        #     #
        #     #   @api public
        #
        #     # @!method match_any_ltextquery(value)
        #     #   Return first LTree array entry that matches ltextquery, NULL if none
        #     #   Translates to ?@
        #     #
        #     #   @example
        #     #     people.select(:name).where { parents_tags.match_any_ltextquery('EmpireState').not(nil)}
        #     #
        #     #   @param [String] value
        #     #
        #     #   @return [SQL::Attribute<Types::PG::LTree>]
        #     #
        #     #   @api public
        #
        #   end
        module LTreeMethods
          ASCENDANT = ['(', ' @> ', ')'].freeze
          FIND_ASCENDANT = ['(', ' ?@> ', ')'].freeze
          DESCENDANT = ['(', ' <@ ', ')'].freeze
          FIND_DESCENDANT = ['(', ' ?<@ ', ')'].freeze
          MATCH_ANY = ['(', ' ? ', ')'].freeze
          MATCH_ANY_LQUERY = ['(', ' ?~ ', ')'].freeze
          MATCH_LTEXTQUERY = ['(', ' @ ', ')'].freeze
          MATCH_ANY_LTEXTQUERY = ['(', ' ?@ ', ')'].freeze

          def match(_type, expr, query)
            Attribute[SQL::Types::Bool].meta(sql_expr: Sequel::SQL::BooleanExpression.new(:'~', expr, query))
          end

          def match_any(_type, expr, query)
            array = build_array_query(query)
            Attribute[SQL::Types::Bool].meta(sql_expr: custom_operator_expr(MATCH_ANY, expr, array))
          end

          private

          def custom_operator_expr(string, expr, query)
            Sequel::SQL::PlaceholderLiteralString.new(string, [expr, query])
          end

          def build_array_query(query, array_type = 'lquery')
            case query
            when ::Array
              ROM::SQL::Types::PG::Array(array_type)[query]
            when ::String
              ROM::SQL::Types::PG::Array(array_type)[query.split(',')]
            end
          end
        end

        TypeExtensions.register(ROM::SQL::Types::PG::Array('ltree', LTree)) do
          include LTreeMethods

          def contain_any_ltextquery(_type, expr, query)
            Attribute[SQL::Types::Bool].meta(sql_expr: custom_operator_expr(LTreeMethods::MATCH_LTEXTQUERY, expr, query))
          end

          def contain_ancestor(_type, expr, query)
            Attribute[SQL::Types::Bool].meta(sql_expr: custom_operator_expr(LTreeMethods::ASCENDANT, expr, query))
          end

          def contain_descendant(_type, expr, query)
            Attribute[SQL::Types::Bool].meta(sql_expr: custom_operator_expr(LTreeMethods::DESCENDANT, expr, query))
          end

          def find_ancestor(_type, expr, query)
            Attribute[LTree].meta(sql_expr: custom_operator_expr(LTreeMethods::FIND_ASCENDANT, expr, query))
          end

          def find_descendant(_type, expr, query)
            Attribute[LTree].meta(sql_expr: custom_operator_expr(LTreeMethods::FIND_DESCENDANT, expr, query))
          end

          def match_any_lquery(_type, expr, query)
            Attribute[LTree].meta(sql_expr: custom_operator_expr(LTreeMethods::MATCH_ANY_LQUERY, expr, query))
          end

          def match_any_ltextquery(_type, expr, query)
            Attribute[LTree].meta(sql_expr: custom_operator_expr(LTreeMethods::MATCH_ANY_LTEXTQUERY, expr, query))
          end
        end

        TypeExtensions.register(LTree) do
          include LTreeMethods

          def match_ltextquery(_type, expr, query)
            Attribute[SQL::Types::Bool].meta(sql_expr: custom_operator_expr(LTreeMethods::MATCH_LTEXTQUERY, expr, query))
          end

          def contain_descendant(_type, expr, query)
            array = build_array_query(query, 'ltree')
            Attribute[SQL::Types::Bool].meta(sql_expr: custom_operator_expr(LTreeMethods::DESCENDANT, expr, array))
          end

          def descendant(_type, expr, query)
            Attribute[SQL::Types::Bool].meta(sql_expr: custom_operator_expr(LTreeMethods::DESCENDANT, expr, query))
          end

          def contain_ascendant(_type, expr, query)
            array = build_array_query(query, 'ltree')
            Attribute[SQL::Types::Bool].meta(sql_expr: custom_operator_expr(LTreeMethods::ASCENDANT, expr, array))
          end

          def ascendant(_type, expr, query)
            Attribute[SQL::Types::Bool].meta(sql_expr: custom_operator_expr(LTreeMethods::ASCENDANT, expr, query))
          end

          def +(_type, expr, other)
            other_value = case other
                          when ROM::Types::Values::TreePath
                            other
                          else
                            ROM::Types::Values::TreePath.new(other)
                          end
            Attribute[LTree].meta(sql_expr: Sequel::SQL::StringExpression.new(:'||', expr, other_value.to_s))
          end
        end
      end
    end
  end
end
