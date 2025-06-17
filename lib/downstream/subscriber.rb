# frozen_string_literal: true

module Downstream
  class Subscriber
    class << self
      # All public names are considered event handlers
      # (same concept as action_names in controllers/mailers)
      def event_names
        @event_names ||= begin
          # All public instance methods of this class, including ancestors
          methods = (public_instance_methods(true) -
            # Except for public instance methods of Base and its ancestors
            Downstream.public_instance_methods(true) +
            # Be sure to include shadowed public instance methods of this class
            public_instance_methods(false)).uniq.map(&:to_s)
          methods.to_set
        end
      end

      # Downstream subscriber interface
      def call(event)
        new.process_event(event)
      end
    end

    def process_event(event)
      # TODO: callbacks? instrumentation?
      # TODO: namespaced events?
      public_send(event.type, event)
    end
  end
end
