module TkComponent
  module Builder
    class EventHandler
      attr_accessor :name
      attr_accessor :lambda
      attr_accessor :options

      def initialize(name, lambda, options = {})
        @name = name.to_sym
        @lambda = lambda
        @options = options
      end
    end
  end
end
