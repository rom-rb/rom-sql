# frozen_string_literal: true

require 'rom/mapper_compiler'

module ROM
  module SQL
    class MapperCompiler < ROM::MapperCompiler
      def visit_attribute(node)
        name, _, meta_options = node

        if meta_options[:wrapped]
          [extract_wrapped_name(node), from: meta_options[:alias]]
        else
          [name]
        end
      end

      private

      def extract_wrapped_name(node)
        _, _, meta_options = node
        unwrapped_name = meta_options[:alias].to_s.dup
        unwrapped_name.slice!("#{meta_options[:wrapped]}_")
        unwrapped_name.to_sym
      end
    end
  end
end
