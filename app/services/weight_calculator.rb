class WeightCalculator
  WEIGHT_TYPE = {
    oz: 0.065,
    ml: 0.00220462
  }.freeze

  CONTAINER_WEIGHT = {
    bottle: 0.418878,
    can: 0.03
  }.freeze

  # TECH-6236
  DEFAULT_VALUES = {
    volume: 12,
    type: WEIGHT_TYPE.fetch(:oz),
    container: CONTAINER_WEIGHT.fetch(:can),
    count: 6
  }.freeze

  PACKAGING_MODIFIER = 0.75

  def weight_of_shipment(shipment)
    shipment.order_items.sum { |ci| weight_of_order_item(ci) } + PACKAGING_MODIFIER
  end

  def weight_of_order_item(order_item)
    weight_of_product(order_item.variant.product) * order_item.quantity
  end

  def weight_of_cart_items(cart_items)
    cart_items.sum { |ci| weight_of_cart_item(ci) } + PACKAGING_MODIFIER
  end

  def weight_of_cart_item(cart_item)
    weight_of_product(cart_item.variant.product) * cart_item.quantity
  end

  def weight_of_product(product)
    unit_volume = product.volume_value || DEFAULT_VALUES.fetch(:volume)
    weight_type = WEIGHT_TYPE[product.volume_unit&.downcase&.to_sym] || DEFAULT_VALUES.fetch(:type)
    container_weight = CONTAINER_WEIGHT[product.container_type&.downcase&.to_sym] || DEFAULT_VALUES.fetch(:container)
    unit_count = product.container_count || DEFAULT_VALUES.fetch(:count)

    ((unit_volume * weight_type) + container_weight) * unit_count
  end
end
