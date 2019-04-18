require 'rom/mapper_compiler'

module ROM
  module SQL
    class MapperCompiler < ROM::MapperCompiler
      def visit_attribute(node)
        name, _, meta = node

        if meta[:wrapped]
          [name, from: self.alias]
        else
          [name]
        end
      end
    end
  end
end
