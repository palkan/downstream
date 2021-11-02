# frozen_string_literal: true

module Downstream
  class SubscriberJob < ActiveJob::Base
    def perform(event, callable)
      callable.constantize.call(event)
    end
  end
end
