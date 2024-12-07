class ExternalAPIV1::Entities::Shipment < Grape::Entity
  format_with(:iso_timestamp) { |dt| dt&.iso8601 }

  expose :uuid, as: :id
  expose :state

  expose :delivery_method do
    expose :type, &:shipping_type
  end

  expose :supplier, with: ExternalAPIV1::Entities::Supplier
  expose :order_items, with: ExternalAPIV1::Entities::OrderItem
  expose :packages, with: ExternalAPIV1::Entities::Package
  expose :comments, with: Shared::Entities::Comment

  expose :tracking_details do |shipment|
    {
      carrier: shipment.tracking_detail&.carrier,
      tracking_number: shipment.tracking_detail&.reference
    }
  end

  expose :scheduled
  expose :scheduled_for, format_with: :iso_timestamp
  expose :includes_engraving
  expose :exception

  private

  def scheduled
    object.scheduled_for.present?
  end

  def includes_engraving
    object.engraving?
  end

  def exception
    exception = object.shipment_transitions.find_by(to_state: 'exception')

    return nil if exception.nil?

    metadata = exception.metadata

    {
      type: metadata['type'],
      description: metadata['description'],
      metadata: metadata['metadata'],
      created_at: exception.created_at.iso8601
    }
  end
end
