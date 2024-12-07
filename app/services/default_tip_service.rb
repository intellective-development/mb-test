class DefaultTipService
  attr_reader :order, :options

  def initialize(order, options = {})
    @order          = order
    @options        = options
  end

  def calculate
    @order.update(tip_amount: default_tip)
    @order.amounts.update(tip_amount: default_tip) if @order.amounts.respond_to?(:update)
  end

  private

  # Currently we assume the default tip is either $3 or 10% of the order
  # subtotal (rounded up to nearest whole), whichever is greater. We also
  # cap the maximum tip at $30 per supplier.
  #
  # TODO: Re-work the ValueSplitter service to handle the above case - if a
  #       suppliers shipping_method does not allow tipping then they do not
  #       get a piece of the pie.

  MINIMUM_SUGGESTED_TIP_VALUE = 3.0
  SUGGESTED_TIP = 1.10
  SUPPLIER_MAXIMUM = 30.0

  def default_tip
    return 0.0 if eligible_shipments.empty?

    [suggested_tip, MINIMUM_SUGGESTED_TIP_VALUE].max
  end

  def eligible_shipments
    @eligible_shipments ||= @order.shipments.select { |s| s.shipping_method.allows_tipping? }
  end

  def eligible_subtotal
    @eligible_subtotal ||= eligible_shipments.sum(&:sub_total)
  end

  def maximum_tip
    SUPPLIER_MAXIMUM * eligible_shipments.size
  end

  def calculated_tip
    ((eligible_subtotal.to_d * SUGGESTED_TIP) - eligible_subtotal).ceil
  end

  def suggested_tip
    # This is a poor mans clamp until we do Ruby 2.4!
    [0, calculated_tip, maximum_tip].sort[1]
  end
end
