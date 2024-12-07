class SelectDeliveryEstimateService
  attr_reader :delivery_estimate, :maximum, :minimum

  def initialize(minimum, maximum)
    @minimum = Integer(minimum)
    @maximum = Integer(maximum)
  end

  def call
    # TODO: We are creating inactive DeliveryEstimates so they are not presented as an
    # option in SupplierDash v1. We should review in later 2017.
    DeliveryEstimate.find_or_create_by!(
      active: false,
      maximum: maximum,
      minimum: minimum
    )
  end
end
