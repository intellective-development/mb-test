class ConsumerAPIV2::Entities::SupplierProfile < Grape::Entity
  # DEPRICATED: There isn't really a need for this entity - all of it's content has
  # been incorporated into `Supplier` and `ShippingMethod`. As soon as it is no longer
  # used by the Web client, it can be removed.

  expose :name
  expose :id
  expose :type do |supplier|
    supplier.supplier_type.name
  end
  expose :opens_at do |supplier|
    supplier.opens_at&.iso8601
  end
  expose :closes_at do |supplier|
    supplier.closes_at&.iso8601
  end
  expose :timezone, as: :time_zone
  expose :best_delivery_minimum do |_supplier|
    top_delivery_method&.delivery_minimum
  end
  expose :best_delivery_fee do |_supplier|
    top_delivery_method&.delivery_fee
  end
  expose :best_delivery_estimate do |_supplier|
    top_delivery_method&.delivery_expectation
  end
  expose :next_scheduling_window, with: ConsumerAPIV2::Entities::SchedulingWindow do |_supplier|
    top_delivery_method&.next_scheduling_window
  end
  expose :tag_list, as: :tags
  expose :categories

  private

  def top_delivery_method
    if options[:shipping_methods]
      supplier_options = options[:shipping_methods].where(supplier_id: object.id)
      BestShippingMethodService.new(supplier_options).best_shipping_methods.first
    end
  end
end
