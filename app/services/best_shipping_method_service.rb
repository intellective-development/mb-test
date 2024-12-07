# Given a collection of shipping methods, this service will choose the best
# options from each type.
#
# For on_demand types, "best" is defined as the shipping method with the shortest
# delivery expectation, followed by lowest minimum and lowest fee.
#
# For shipped types, "best" does not apply - different shipping methods may
# represent different delivery options with separate fee's and estimates (e.g.
# 3-5 day ground vs. next day air) - in these cases we want to present all options
# to the consumer so all are returned.
#
# For pickup, the expectation is that there will generally only be a single
# option per store.
#
# There is mention of a `next_day` type - this is legacy and should no longer
# be applicable.
#
# In the event that we have both `on_demand` and `shipped`, we will only return
# ondemand options.
class BestShippingMethodService
  attr_reader :shipping_methods

  EXCLUSIVE_TYPES = %w[on_demand next_day pickup].freeze

  def initialize(shipping_methods)
    @shipping_methods = shipping_methods.sort_by do |shipping_method|
      [shipping_method.shipping_type, shipping_method.maximum_delivery_expectation, shipping_method.delivery_minimum, shipping_method.delivery_fee]
    end
  end

  def best_shipping_methods
    grouped_shipping_methods = shipping_methods.group_by(&:shipping_type)
    grouped_shipping_methods.each do |shipping_type, shipping_methods|
      grouped_shipping_methods[shipping_type] = EXCLUSIVE_TYPES.include?(shipping_type) ? shipping_methods.first : shipping_methods
    end
    grouped_shipping_methods.values.flatten
  end
end
