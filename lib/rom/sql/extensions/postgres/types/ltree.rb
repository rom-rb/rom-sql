module ROM
  module SQL
    module Postgres
      module Values
        LabelPath = ::Struct.new(:path) do
          def labels
            path.split('.')
          end
        end
      end

      # @api public
      module Types
        # @see https://www.postgresql.org/docs/current/static/ltree.html

        LTree = SQL::Types.define(Values::LabelPath) do
          input do |label_path|
            label_path.path
          end

          output do |label_path|
            Values::LabelPath.new(label_path.to_s)
          end
        end
      end
    end
  end
end
