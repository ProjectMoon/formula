module FormulaE
  module Services

    # The result of a service object operation.
    class ServiceResult
      attr_reader :errors
      def success?; @success; end

      def initialize(success, errors = [])
        @success = success
        @errors = errors if errors.is_a? Array
        @errors = [ errors ] if errors.is_a? String
      end
    end
  end
end
