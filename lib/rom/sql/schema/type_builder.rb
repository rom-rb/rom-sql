# frozen_string_literal: true

module ROM
  module SQL
    class Schema
      # @api private
      class TypeBuilder
        extend Dry::Core::ClassAttributes

        defines :registry

        def self.register(db_type, builder)
          registry[db_type] = builder
        end

        def self.[](db_type)
          registry[db_type]
        end

        registry Hash.new(new.freeze)

        defines :ruby_type_mapping, :numeric_pk_type

        DECIMAL_REGEX = /(?:decimal|numeric)\((\d+)(?:,\s*(\d+))?\)/.freeze

        ruby_type_mapping(
          integer: Types::Integer,
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

        def call(primary_key:, db_type:, type:, allow_null:, **rest)
          if primary_key
            map_pk_type(type, db_type, **rest)
          else
            mapped_type = map_type(type, db_type, **rest)

            if mapped_type
              read_type = mapped_type.meta[:read]

              if read_type && allow_null
                mapped_type.optional.meta(read: read_type.optional)
              elsif allow_null
                mapped_type.optional
              else
                mapped_type
              end
            end
          end
        end

        # @api private
        def map_pk_type(_ruby_type, _db_type, **)
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
