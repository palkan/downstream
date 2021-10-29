require "active_support/notifications"
require_relative "subscriber"

module Downstream
  module Stateless
    class Pubsub < AbstractPubsub
      def subscribe(identifier, callable)
        ActiveSupport::Notifications.subscribe(
          identifier,
          Subscriber.new(callable)
        )
      end

      def subscribed(identifier, callable, &block)
        ActiveSupport::Notifications.subscribed(
          Subscriber.new(callable),
          identifier,
          &block
        )
      end

      def publish(identifier, event)
        ActiveSupport::Notifications.publish(identifier, event)
      end
    end
  end
end
