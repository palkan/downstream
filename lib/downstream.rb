# frozen_string_literal: true

require "active_support"
require "active_model"

require "downstream/config"
require "downstream/event"
require "downstream/rspec" if defined?(RSpec)

module Downstream
  class << self
    def config
      @config ||= Config.new
    end

    def subscribe(subscriber = nil, to: nil, &block)
      to ||= infer_event_from_subscriber(subscriber) if subscriber.is_a?(Module)

      if to.nil?
        raise ArgumentError, "Couldn't infer event from subscriber. " \
                              "Please, specify event using `to:` option"
      end

      subscriber ||= block if block

      if subscriber.nil?
        raise ArgumentError, "Subsriber must be present"
      end

      identifier =
        if to.is_a?(Class) && Event >= to
          to.identifier
        else
          to
        end

      ActiveSupport::Notifications.subscribe("#{config.namespace}.#{identifier}", subscriber)
    end

    # temporary subscriptions
    def subscribed(subscriber, to: nil, &block)
      to ||= infer_event_from_subscriber(subscriber) if subscriber.is_a?(Module)

      if to.nil?
        raise ArgumentError, "Couldn't infer event from subscriber. " \
                              "Please, specify event using `to:` option"
      end

      identifier =
        if to.is_a?(Class) && Event >= to
          to.identifier
        else
          to
        end

      ActiveSupport::Notifications.subscribed(subscriber, "#{config.namespace}.#{identifier}", &block)
    end

    def publish(event)
      ActiveSupport::Notifications.publish("#{config.namespace}.#{event.type}", event)
    end

    private

    def infer_event_from_subscriber(subscriber)
      event_class_name = subscriber.name.split("::").yield_self do |parts|
        # handle explicti top-level name, e.g. ::Some::Event
        parts.shift if parts.first.empty?
        # drop last part – it's a unique subscriber name
        parts.pop

        parts.last.sub!(/^On/, "")

        parts.join("::")
      end

      event_class_name.safe_constantize
    end
  end
end

require "downstream/engine"
