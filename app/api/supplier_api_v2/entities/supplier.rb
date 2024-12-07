class SupplierAPIV2::Entities::Supplier < Grape::Entity
  expose :name
  expose :id
  expose :channel_id
  expose :timezone, as: :time_zone
  expose :metrics do
    expose :product_count do |supplier|
      supplier.variants.active.size
    end
    expose :product_in_stock_count do |supplier|
      supplier.variants.active.available.size
    end
    expose :score do |supplier|
      supplier.score.to_f.round_at(2)
    end
  end
  expose :partner_config do |supplier|
    supplier.config['partners']
  end
  expose :shipping_methods
  expose :shipping_providers
  expose :feature_items
  expose :current_break, with: SupplierAPIV2::Entities::SupplierBreak
  expose :accepts_back_orders
  expose :presale_eligible

  private

  def shipping_providers
    # For now we are hardcoding strings, later on we may wish to model shipping
    # providers and expose globally or on a per-supplier basis.
    # Some providers such as Uber may need special activation, similarly others
    # may only be available in certain locations.
    ['FedEx', 'UPS', 'GSO', '7 Day Express Shipping', 'GIO Express', 'Local Courier']
  end

  def shipping_methods
    ids = object.delegate_supplier_ids.unshift(object.id)
    ShippingMethod.active.where(supplier_id: ids).group_by(&:shipping_type).map do |shipping_type, shipping_methods|
      {
        type: shipping_type,
        opens_at: shipping_methods.map(&:opens_at).min.iso8601,
        closes_at: shipping_methods.map(&:closes_at).max.iso8601
      }
    end
  end

  def feature_items
    feature_array = []
    feature_array << { feature: 'Substitution' } if object.allow_substitution?
    feature_array.concat object.feature_items
  end
end
