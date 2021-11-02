# frozen_string_literal: true

require "active_support/notifications"
require_relative "subscriber"

module Downstream
  module Stateless
    class Pubsub < AbstractPubsub
      def subscribe(identifier, callable, async: false)
        Subscriber.new(callable, async: async).tap { |s| s.subscribe(identifier) }
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
