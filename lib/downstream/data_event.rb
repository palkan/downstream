# frozen_string_literal: true

module Downstream
  class DataEvent < Event
    class << self
      attr_writer :data_class

      def data_class
        return @data_class if @data_class

        @data_class = superclass.data_class
      end

      undef_method :attributes
      undef_method :defined_attributes
    end

    def initialize(event_id: nil, **attrs)
      @event_id = event_id || SecureRandom.hex(10)
      @data = self.class.data_class.new(**attrs)
      freeze
    end

    def to_h
      {
        type:,
        event_id:,
        data: data.to_h.freeze
      }.freeze
    end
  end
end
