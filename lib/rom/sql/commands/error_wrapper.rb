module ROM
  module SQL
    module Commands
      module ErrorWrapper
        def call(*args)
          super
        rescue *ERROR_MAP.keys => e
          raise ERROR_MAP[e.class], e
        end
      end
    end
  end
end
