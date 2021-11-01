# frozen_string_literal: true

require "active_support/inflections"

module Downstream
  class Config
    attr_accessor :async_queue
    attr_writer :namespace

    def namespace
      @namespace ||= "downstream-events"
    end

    def pubsub
      @pubsub ||= lookup_pubsub(:stateless)
    end

    def pubsub=(value)
      @pubsub = case value
        when String, Symbol
          lookup_pubsub(value)
        else
          value
      end
    end

    private

    def lookup_pubsub(name)
      klass = name.camelize.safe_constantize if name.is_a?(String)

      klass ||= begin
        require "downstream/pubsub_adapters/#{name}/pubsub"
        "Downstream::#{name.to_s.camelize}::Pubsub".safe_constantize
      end

      raise ArgumentError, "Uknown downstream pubsub adapter: #{name}" unless klass

      klass.new
    end
  end
end
