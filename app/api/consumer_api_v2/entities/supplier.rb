class ConsumerAPIV2::Entities::Supplier < Grape::Entity
  format_with(:iso_timestamp) { |dt| dt&.iso8601 }

  expose :display_name, as: :name
  expose :id
  expose :permalink
  expose :supplier_type, as: :type
  expose :birthdate_required
  expose :show_substitution_ok
  expose :type_attributes, with: ConsumerAPIV2::Entities::SupplierType, &:supplier_type
  expose :address, if: ->(object, _options) { object.address } do |object, _options|
    ConsumerAPIV2::Entities::Address.represent(object.address, supplier: true, show_phone: true)
  end
  expose :distance, if: ->(_object, _options) { can_calculate_distance? }

  expose :delivery_methods, with: ConsumerAPIV2::Entities::ShippingMethod
  expose :timezone, as: :time_zone
  # DEPRICATED!
  # These are currently used by Cider and Minibar Web (and parsed in the old iOS app)
  # for messaging of delivery expectation. When we implement shipping, these should
  # be removed and dependant logic changed to use the selected shipping method.
  expose :best_delivery_minimum do |_supplier|
    delivery_methods.first.delivery_minimum if delivery_methods.any?
  end
  expose :best_delivery_fee do |_supplier|
    delivery_methods.first.delivery_fee if delivery_methods.any?
  end
  expose :best_delivery_estimate do |_supplier|
    delivery_methods.first.get_delivery_expectation if delivery_methods.any?
  end

  expose :logo_url do |supplier|
    supplier.get_supplier_logo&.logo&.image&.url(:original)
  end

  # These are used in various places, but we really should be using their
  # counterparts on the individual shipping methods.
  expose :opens_at, format_with: :iso_timestamp
  expose :closes_at, format_with: :iso_timestamp
  # END DEPRICATION

  expose :category_integers, as: :categories
  expose :alternatives, if: :alternative_suppliers
  expose :supported_payment_methods, with: ConsumerAPIV2::Entities::SupportedPaymentMethods

  expose :vineyard_select, &:vineyard_select?

  expose :delivery_hours do |_supplier|
    options[:delivery_hours]&.sort_by(&:wday)&.map do |hours|
      {
        ends_at: hours.ends_at,
        starts_at: hours.starts_at,
        wday: hours.wday
      }
    end
  end

  private

  def can_calculate_distance?
    options[:customer_address]&.geocoded? &&
      object.address&.geocoded? &&
      object.address.respond_to?(:distance_to)
  end

  def distance
    object.address.distance_to(options[:customer_address], :mi)
  end

  def supplier_type
    object.supplier_type.name
  end

  def supported_payment_methods
    object.profile
  end

  def alternatives
    options[:alternative_suppliers].select { |s| s.supplier_type_id == object.supplier_type_id && s.id != object.id }.map(&:id).uniq
  end

  def delivery_methods
    return [] unless options[:shipping_methods]

    supplier_options = options[:shipping_methods].select { |sm| sm.supplier_id == object.id && !sm.supplier.on_break?(sm.id) }

    return supplier_options if options[:filter_best_shipping_method] == false

    BestShippingMethodService.new(supplier_options).best_shipping_methods
  end

  def category_integers
    object.categories.transform_values(&:to_i)
  end
end
