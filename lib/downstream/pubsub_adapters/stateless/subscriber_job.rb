module Downstream
  module Stateless
    class SubscriberJob < ActiveJob::Base
      def perform(event, callable)
        callable.constantize.call(event)
      end
    end
  end
end
