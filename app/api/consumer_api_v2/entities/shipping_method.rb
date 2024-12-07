class ConsumerAPIV2::Entities::ShippingMethod < Grape::Entity
  format_with(:iso_timestamp) { |dt| dt&.iso8601 }

  expose :id
  expose :allows_tipping
  expose :delivery_fee
  expose :delivery_minimum
  expose :delivery_threshold, as: :free_delivery_threshold, expose_nil: false
  expose :hours do
    expose :always_open?, as: :always_open
    expose :closes_at, format_with: :iso_timestamp, unless: ->(object, _options) { object.shipped? }
    expose :opens_at,  format_with: :iso_timestamp, unless: ->(object, _options) { object.shipped? }
  end
  expose :next_delivery
  expose :per_item_delivery_fee
  expose :scheduling_mode
  expose :shipping_type, as: :type
  expose :supplier_id

  # Island of the deprecated toys
  expose :allows_scheduling
  expose :get_delivery_expectation, as: :delivery_expectation
  expose :name
  expose :next_scheduling_window, with: ConsumerAPIV2::Entities::SchedulingWindow, unless: ->(object, _options) { !object.allows_scheduling }
  expose :get_maximum_delivery_expectation, as: :maximum_delivery_expectation
  expose :default do |shipping_method|
    # TODO: Remove or rewrite this for Shipping
    shipping_method.id == options[:shipping_methods].find { |sm| sm.supplier_id == shipping_method.supplier_id }.id
  end
  # END

  private

  def per_item_delivery_fee # TODO: remove this when real logic implemented
    false
  end
end
