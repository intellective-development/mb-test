class ConfirmUnconfirmedShipmentsJob
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: 5,
                  queue: 'default'

  def perform_with_error_handling
    Shipment.where(state: 'paid').where('created_at < ?', 72.hours.ago).find_each do |shipment|
      shipment.transition_to!(:confirmed)
    end
  end
end
