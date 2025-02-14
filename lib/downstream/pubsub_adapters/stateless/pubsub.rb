# frozen_string_literal: true

require "active_support/notifications"
require_relative "subscriber"

module Downstream
  module Stateless
    class Pubsub < AbstractPubsub
      def initialize
        @subscribers = []
      end

      def reset
        @subscribers.each(&:unsubscribe)
        @subscribers.clear
      end

      def subscribe(identifier, callable, async: false)
        Subscriber.new(callable, async: async).tap do |s|
          s.subscribe(identifier)
          @subscribers << s
        end
      end

      def subscribed(identifier, callable, &block)
        ActiveSupport::Notifications.subscribed(
          Subscriber.new(callable),
          identifier,
          &block
        )
      end

      def publish(identifier, event)
        ActiveSupport::Notifications.instrument(identifier, event)
      end
    end
  end
end
