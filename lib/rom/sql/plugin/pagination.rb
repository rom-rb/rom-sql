module ROM
  module SQL
    module Plugin
      module Pagination
        class Pager
          include Options

          option :current_page, reader: true
          option :per_page, reader: true

          attr_reader :dataset
          attr_reader :current_page

          def initialize(dataset, options = {})
            @dataset = dataset
            super
          end

          def next_page
            num = current_page + 1
            num if total_pages >= num
          end

          def prev_page
            num = current_page - 1
            num if num > 0
          end

          def total
            dataset.unlimited.count
          end

          def total_pages
            (total / per_page) + 1
          end
        end

        def self.included(klass)
          super

          klass.class_eval do
            defines :per_page

            option :current_page

            option :pager, reader: true, default: proc { |relation|
              Pager.new(
                relation.dataset,
                current_page: relation.options[:current_page],
                per_page: relation.class.per_page
              )
            }
          end
        end

        def page(num)
          per_page = self.class.per_page
          paginated = dataset.offset((num-1)*per_page).limit(per_page)
          self.class.new(paginated, current_page: num)
        end
      end
    end
  end
end
