module ROM
  module SQL
    module Postgres
      module Values
        Label = ::Struct.new(:path) do
          def segments
            path.split('.')
          end
        end
      end

      # @api public
      module Types
        # @see https://www.postgresql.org/docs/current/static/ltree.html

        Ltree = SQL::Types.define(Values::Label) do
          input do |label|
            label.path
          end

          output do |label|
            Values::Label.new(label.to_s)
          end
        end
      end
    end
  end
end
