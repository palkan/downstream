# frozen_string_literal: true

module Downstream
  class Config
    attr_writer :namespace

    def namespace
      @namespace ||= "downstream-events"
    end
  end
end
