# frozen_string_literal: true

require 'rom/sql/type_extensions'

module ROM
  module SQL
    module Postgres
      module Types
        # @api private
        class ArrayTypes
          attr_reader :elements

          attr_reader :constructor

          attr_reader :base_write_type

          attr_reader :base_read_type

          def initialize(base_write_type, base_read_type)
            @elements = {}
            @base_write_type = base_write_type
            @base_read_type = base_read_type
            @constructor = proc { |db_type, member|
              if member
                -> arr { Sequel.pg_array(arr.map { |v| member[v] }, db_type) }
              else
                -> arr { Sequel.pg_array(arr, db_type) }
              end
            }
          end

          def [](db_type, member_type = nil)
            elements.fetch(db_type) do
              name = "#{db_type}[]"

              write_type = build_write_type(db_type, member_type)
              read_type = build_read_type(db_type, member_type)

              array_type = Types.Type(name, write_type).meta(type: db_type, read: read_type)

              register_extension(array_type)

              elements[db_type] = array_type
            end
          end

          private

          def build_write_type(db_type, member_type)
            if member_type
              base_write_type.constructor(constructor[db_type, member_type])
            else
              base_write_type.constructor(constructor[db_type])
            end
          end

          def build_read_type(_db_type, member_type)
            if member_type && member_type.meta[:read]
              base_read_type.of(member_type.meta[:read])
            else
              base_read_type
            end
          end

          def register_extension(type)
            TypeExtensions.register(type) { include ArrayMethods }
          end
        end
      end
    end
  end
end
