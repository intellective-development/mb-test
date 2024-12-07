class ConsumerAPIV2::Entities::MembershipBenefits < Grape::Entity
  expose :delivery_fee_label
  expose :shipping_fee_label
  expose :engraving_label
  expose :exclusive_offers_label

  def delivery_fee_label
    threshold = [object.free_on_demand_fulfillment_threshold, object.free_shipping_fulfillment_threshold].max
    "Unlimited Free Shipping or 2-Hour Delivery on #{build_free_fee_text(threshold)}"
  end

  def shipping_fee_label
    'Early access to new releases and limited editions'
  end

  def engraving_label
    return if object.engraving_percent_off.zero?

    "#{format('%g', object.engraving_percent_off)}% OFF custom bottle engravings"
  end

  def exclusive_offers_label
    "#{object.name} exclusive offers"
  end

  private

  def build_free_fee_text(value)
    value.zero? ? 'every order' : "orders over $#{format('%.2f', value)}"
  end
end
