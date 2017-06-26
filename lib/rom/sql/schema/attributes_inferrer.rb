require 'dry/core/class_attributes'

module ROM
  module SQL
    class Schema < ROM::Schema
      # @api private
      class AttributesInferrer
        extend Dry::Core::ClassAttributes
        extend Initializer

        defines :ruby_type_mapping, :numeric_pk_type, :db_type, :registry

        class << self
          def inherited(klass)
            super

            registry[klass.db_type] = klass.new.freeze unless klass.name.nil?
          end

          def [](type)
            Class.new(self) { db_type(type) }
          end

          def get(db_type)
            registry[db_type]
          end
        end

        CONSTRAINT_DB_TYPE = 'add_constraint'.freeze
        DECIMAL_REGEX = /(?:decimal|numeric)\((\d+)(?:,\s*(\d+))?\)/.freeze

        registry Hash.new(new.freeze)

        ruby_type_mapping(
          integer: Types::Int,
          string: Types::String,
          time: Types::Time,
          date: Types::Date,
          datetime: Types::Time,
          boolean: Types::Bool,
          decimal: Types::Decimal,
          float: Types::Float,
          blob: Types::Blob
        ).freeze

        numeric_pk_type Types::Serial

        option :attr_class, optional: true

        # @api private
        def call(schema, gateway)
          dataset = schema.name.dataset

          columns = filter_columns(gateway.connection.schema(dataset))
          fks = fks_for(gateway, dataset)

          inferred = columns.map do |(name, definition)|
            type = build_type(**definition, foreign_key: fks[name])

            attr_class.new(type.meta(name: name, source: schema.name)) if type
          end.compact

          missing = columns.map(&:first) - inferred.map { |attr| attr.meta[:name] }

          [inferred, missing]
        end

        # @api private
        def with(new_options)
          self.class.new(options.merge(new_options))
        end


        # @api private
        def filter_columns(schema)
          schema.reject { |(_, definition)| definition[:db_type] == CONSTRAINT_DB_TYPE }
        end

        # @api private
        def build_type(primary_key:, db_type:, type:, allow_null:, foreign_key:, **rest)
          if primary_key
            map_pk_type(type, db_type)
          else
            mapped_type = map_type(type, db_type, rest)

            if mapped_type
              read_type = mapped_type.meta[:read]
              mapped_type = mapped_type.optional if allow_null
              mapped_type = mapped_type.meta(foreign_key: true, target: foreign_key) if foreign_key

              if read_type && allow_null
                mapped_type.meta(read: read_type.optional)
              elsif read_type
                mapped_type.meta(read: read_type)
              else
                mapped_type
              end
            end
          end
        end

        # @api private
        def map_pk_type(_ruby_type, _db_type)
          self.class.numeric_pk_type.meta(primary_key: true)
        end

        # @api private
        def map_type(ruby_type, db_type, **kw)
          type = self.class.ruby_type_mapping[ruby_type]

          if db_type.is_a?(String) && db_type.include?('numeric') || db_type.include?('decimal')
            map_decimal_type(db_type)
          elsif db_type.is_a?(String) && db_type.include?('char') && kw[:max_length]
            type.meta(limit: kw[:max_length])
          else
            type
          end
        end

        # @api private
        def fks_for(gateway, dataset)
          gateway.connection.foreign_key_list(dataset).each_with_object({}) do |definition, fks|
            column, fk = build_fk(definition)

            fks[column] = fk if fk
          end
        end

        # @api private
        def column_indexes(indexes, column)
          indexes.each_with_object(Set.new) do |(name, idx), set|
            set << name if idx[:columns][0] == column
          end
        end

        # @api private
        def build_fk(columns: , table: , **rest)
          if columns.size == 1
            [columns[0], table]
          else
            # We don't have support for multicolumn foreign keys
            columns[0]
          end
        end

        # @api private
        def map_decimal_type(type)
          precision = DECIMAL_REGEX.match(type)

          if precision
            prcsn, scale = precision[1..2].map(&:to_i)

            self.class.ruby_type_mapping[:decimal].meta(
              precision: prcsn,
              scale: scale
            )
          else
            self.class.ruby_type_mapping[:decimal]
          end
        end
      end
    end
  end
end
