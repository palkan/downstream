# frozen_string_literal: true

require "rails/engine"

module Downstream
  class Engine < ::Rails::Engine
    config.downstream = Downstream.config

    ::GlobalID::Locator.use "downstream" do |gid|
      params = gid.params.each_with_object({}) do |(key, value), memo|
        memo[key.to_sym] = if value.is_a?(String) && value.start_with?("gid://")
          GlobalID::Locator.locate(value)
        else
          value
        end
      end

      gid.model_name.constantize
        .new(event_id: gid.model_id, **params)
    end

    config.to_prepare do
      Downstream.pubsub.reset
      ActiveSupport.run_load_hooks("downstream-events", Downstream)
    end
  end
end
