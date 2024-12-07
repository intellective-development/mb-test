class ProcessShipmentFinancialOrderAdjustmentsWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: false,
                  queue: 'internal',
                  lock: :until_and_while_executing

  def perform_with_error_handling(shipment_id)
    shipment = Shipment.find shipment_id
    return unless shipment

    shipment.order_adjustments.waiting_charge_settlement.each do |adjustment|
      ProcessFinancialOrderAdjustmentWorker.perform_async String(adjustment.to_global_id)
    end
  end
end
