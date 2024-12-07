class ProcessFinancialOrderAdjustmentJob < ActiveJob::Base
  include SentryNotifiable

  queue_as :internal

  rescue_from(Statesman::GuardFailedError) do |exception|
    notify_sentry_and_log(exception,
                          "Order Adjustment process error. #{exception.message}",
                          { tags: { order_adjustment: arguments[0] } })
  end

  # GlobalID for the adjustment instantiates the adjustment for us.
  def perform(order_adjustment)
    order_adjustment = GlobalID.find(order_adjustment) if order_adjustment.instance_of? String
    # TECH-4381: Added some logs in case the issue happens again
    Rails.logger.warn("processing_order_adjustment_#{order_adjustment.id}")

    order_adjustment.process
  end

  def self.process_adjustments(charge_gid)
    charge = GlobalID.find(charge_gid)
    return unless charge.shipment

    charge.shipment.order_adjustments.waiting_charge_settlement.each do |adjustment|
      ProcessFinancialOrderAdjustmentJob.perform_later String(adjustment.to_global_id)
    end
  end
end
