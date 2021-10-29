module Downstream
  class AbstractPubsub
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
