module ROM
  module SQL
    # @private
    class Header
      include Charlatan.new(:columns)
      include Equalizer.new(:columns, :table)

      attr_reader :table

      def initialize(columns, table)
        super
        @table = table
      end

      def to_ary
        columns
      end
      alias_method :to_a, :to_ary

      def to_h
        columns.each_with_object({}) do |col, h|
          left, right = col.to_s.split('___')
          h[left.to_sym] = (right || left).to_sym
        end
      end

      def names
        map { |col| :"#{col.to_s.split('___').last}" }
      end

      def project(*names)
        find_all { |col| names.include?(col) }
      end

      def qualified
        map { |col| :"#{table}__#{col}" }
      end

      def rename(options)
        map do |col|
          new_name = options[col]

          if new_name
            :"#{col}___#{new_name}"
          else
            col
          end
        end
      end

      def prefix(col_prefix)
        rename(Hash[map { |col| [col, :"#{col_prefix}_#{col}"] }])
      end
    end
  end
end
