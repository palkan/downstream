module Downstream
  module Stateless
    class Subscriber
      attr_reader :callable

      def initialize(callable)
        @callable = callable
      end

      def call(name, event)
        if (callable.respond_to?(:arity) && callable.arity == 2) || callable.method(:call).arity == 2
          callable.call(name, event)
        else
          callable.call(event)
        end
      end
    end
  end
end
