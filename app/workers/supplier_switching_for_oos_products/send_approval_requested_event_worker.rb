# frozen_string_literal: true

module SupplierSwitchingForOosProducts
  # SupplierSwitchingForOosProducts::SendApprovalRequestedEventWorker
  class SendApprovalRequestedEventWorker
    include Sidekiq::Worker
    include WorkerErrorHandling

    sidekiq_options \
      queue: 'internal',
      retry: false,
      lock: :until_executing

    def perform_with_error_handling(old_shipment_id, new_order_id, approve_url)
      return if Feature[:disable_oos_availability_check].enabled?
      return if approve_url.blank?

      old_shipment = Shipment.find(old_shipment_id)
      new_order = Order.find(new_order_id)
      storefront = new_order.storefront

      return unless storefront.enable_oos_availability_check

      Segments::SegmentService.from(storefront).approval_for_moving_products_between_retailers_requested(old_shipment: old_shipment, new_order: new_order, approve_url: approve_url)
    end
  end
end
