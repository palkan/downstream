# frozen_string_literal: true

module Downstream
  class AbstractPubsub
    def reset
      raise NotImplementedError
    end

    def subscribe(identifier, callable)
      raise NotImplementedError
    end

    def subscribed(identifier, callable, &block)
      raise NotImplementedError
    end

    def publish(identifier, event)
      raise NotImplementedError
    end
  end
end
