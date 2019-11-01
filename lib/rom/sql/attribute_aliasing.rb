# frozen_string_literal: true

module ROM
  module SQL
    # @api private
    module AttributeAliasing
      # Return a new attribute with an alias
      #
      # @example
      #   users[:id].aliased(:user_id)
      #
      # @return [SQL::Attribute]
      #
      # @api public
      def aliased(alias_name)
        new_name, new_alias_name = extract_alias_names(alias_name)

        super(new_alias_name).with(name: new_name).meta(
          sql_expr: alias_sql_expr(sql_expr, new_alias_name)
        )
      end
      alias as aliased

      private

      # @api private
      def alias_sql_expr(sql_expr, new_alias)
        case sql_expr
        when Sequel::SQL::AliasedExpression
          Sequel::SQL::AliasedExpression.new(sql_expr.expression, new_alias, sql_expr.columns)
        else
          sql_expr.as(new_alias)
        end
      end

      # @api private
      def extract_alias_names(alias_name)
        new_name, new_alias_name = nil

        if wrapped? && aliased?
          # If the attribute is wrapped *and* aliased, make sure that we name the
          # attribute in a way that will map the the requested alias name.
          # Without this, the attribute will silently ignore the requested alias
          # name and default to the pre-existing name.
          new_name = "#{meta[:wrapped]}_#{options[:alias]}".to_sym

          # Essentially, this makes it so "wrapped" attributes aren't true
          # aliases, in that we actually alias the wrapped attribute, we use
          # the old alias.
          new_alias_name = options[:alias]
        else
          new_name = name || alias_name
          new_alias_name = alias_name
        end

        [new_name, new_alias_name]
      end
    end
  end
end
