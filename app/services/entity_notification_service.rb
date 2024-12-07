# frozen_string_literal: true

class EntityNotificationService < SupplierNotificationServerService
  require 'faraday'

  attr_reader :model, :model_type, :model_id, :notification_type, :channel_id

  # Acceptable types - fetch|comment|adjustment
  def initialize(model = nil, type = 'fetch')
    @model = model

    if @model
      raise "#{@model.model_name.name} does not have a supplier association" unless @model.respond_to?(:supplier)

      @model_type = @model.model_name.name
      @model_id   = @model&.uuid || @model&.id
      super([@model.supplier], type)
    end
  end

  private

  def notification_content
    {
      entity_type: @model_type,
      entity_id: @model_id,
      notification_type: @notification_type
    }
  end
end
