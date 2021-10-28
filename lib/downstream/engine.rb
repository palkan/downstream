# frozen_string_literal: true

require "rails/engine"

module Downstream
  class Engine < ::Rails::Engine
    config.downstream = Downstream.config

    config.to_prepare do
      ActiveSupport.run_load_hooks("downstream-events", Downstream)
    end
  end
end
