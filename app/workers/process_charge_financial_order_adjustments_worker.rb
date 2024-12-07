# TODO: remove this after the deployment (Not removing now to avoid error on already scheduled jobs...)
class ProcessChargeFinancialOrderAdjustmentsWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: false,
                  queue: 'internal',
                  lock: :until_and_while_executing

  def perform_with_error_handling(charge_gid)
    charge = GlobalID.find(charge_gid)
    return unless charge.shipment

    charge.shipment.order_adjustments.waiting_charge_settlement.each do |adjustment|
      ProcessFinancialOrderAdjustmentWorker.perform_async String(adjustment.to_global_id)
    end
  end
end
