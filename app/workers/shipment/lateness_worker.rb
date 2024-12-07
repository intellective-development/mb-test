class Shipment::LatenessWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal', lock: :until_and_while_executing

  def perform_with_error_handling(shipment_id)
    ActiveRecord::Base.transaction do
      shipment = Shipment.joins(:supplier).find(shipment_id)

      return if shipment.late?

      shipment.update!(late: true)
      shipment.supplier.add_strike!
    end
  end
end
