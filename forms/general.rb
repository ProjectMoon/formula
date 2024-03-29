module FormulaE
  module Web
    module Forms

      # A mixin module that replaces the constructor with one that
      # guards against unknown hash values.
      module ConstructorGuard
        def initialize(*args)
          if args.size > 0
            args[0].each_key do |key, value|
              raise ArgumentError, key unless respond_to?("#{key}=")
            end

            super(*args)
          end
        end
      end

    end
  end
end
