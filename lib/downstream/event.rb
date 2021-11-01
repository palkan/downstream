# frozen_string_literal: true

GlobalID::Locator.use :downstream do |gid|
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

module Downstream
  class Event
    extend ActiveModel::Naming
    include GlobalID::Identification

    RESERVED_ATTRIBUTES = %i[id event_id type].freeze

    class << self
      attr_writer :identifier

      def identifier
        return @identifier if instance_variable_defined?(:@identifier)

        @identifier = name.underscore.tr("/", ".")
      end

      # define store readers
      def attributes(*fields)
        fields.each do |field|
          raise ArgumentError, "#{field} is reserved" if RESERVED_ATTRIBUTES.include?(field)

          defined_attributes << field

          # TODO: rewrite with define_method
          class_eval <<~CODE, __FILE__, __LINE__ + 1
            def #{field}
              data[:#{field}]
            end
          CODE
        end
      end

      def defined_attributes
        return @defined_attributes if instance_variable_defined?(:@defined_attributes)

        @defined_attributes =
          if superclass.respond_to?(:defined_attributes)
            superclass.defined_attributes.dup
          else
            []
          end
      end

      def i18n_scope
        :activemodel
      end

      def human_attribute_name(attr, options = {})
        attr
      end

      def lookup_ancestors
        [self]
      end
    end

    attr_reader :event_id, :data, :errors

    alias_method :id, :event_id

    def initialize(event_id: nil, **params)
      @event_id = event_id || SecureRandom.hex(10)
      validate_attributes!(params)

      @errors = ActiveModel::Errors.new(self)
      @data = params
    end

    def type
      self.class.identifier
    end

    def to_h
      {
        type: type,
        event_id: event_id,
        data: data
      }
    end

    def to_global_id
      new_data = data.each_with_object({}) do |(key, value), memo|
        memo[key] = if value.respond_to?(:to_global_id)
          value.to_global_id
        else
          value
        end
      end

      super(new_data.merge!(app: :downstream))
    end

    alias_method :to_gid, :to_global_id

    def inspect
      "#{self.class.name}<#{type}##{event_id}>, data: #{data}"
    end

    def read_attribute_for_validation(attr)
      data.fetch(attr)
    end

    def ==(other)
      super ||
        other.instance_of?(self.class) &&
          !event_id.nil? &&
          other.event_id == event_id
    end

    alias_method :eql?, :==

    private

    def validate_attributes!(params)
      unknown_fields = params.keys.map(&:to_sym) - self.class.defined_attributes
      unless unknown_fields.empty?
        raise ArgumentError, "Unknown event attributes: #{unknown_fields.join(", ")}"
      end
    end
  end
end
