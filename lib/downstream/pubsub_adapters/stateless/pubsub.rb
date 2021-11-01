require "active_support/notifications"
require_relative "subscriber"

module Downstream
  module Stateless
    class Pubsub < AbstractPubsub
      def subscribe(identifier, callable, async: false)
        ActiveSupport::Notifications.subscribe(
          identifier,
          Subscriber.new(callable, async: async)
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
