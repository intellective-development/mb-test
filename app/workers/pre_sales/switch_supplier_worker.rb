# frozen_string_literal: true

module PreSales
  # Switches the supplier for pre-sale shipments. It only works for not confirmed/paid pre-sale shipments.
  class SwitchSupplierWorker
    include Sidekiq::Worker
    include WorkerErrorHandling

    sidekiq_options retry: false,
                    queue: 'backfill',
                    lock: :until_executed

    def perform_with_error_handling(shipment_id, new_supplier_id, current_user_id = nil)
      new_supplier = Supplier.find(new_supplier_id)
      shipment = Shipment.find(shipment_id)
      current_user = User.find_by(id: current_user_id)

      return unless shipment.pre_sale_eligible_for_supplier_switching?(new_supplier)

      ActiveRecord::Base.transaction do
        Dashboard::DashboardService.cancel_shipment(shipment)

        old_supplier = shipment.supplier

        shipment.update(supplier: new_supplier)
        shipment.reload

        Dashboard::DashboardService.redo_place_pre_sale_shipment(shipment)

        shipment.comments.create(
          note: "The supplier_id of the shipment with uuid '#{shipment.uuid}' was updated from '#{old_supplier.id}' to '#{new_supplier.id}'.",
          created_by: current_user&.id,
          user_id: shipment.order.user_id,
          posted_as: :minibar
        )
      end
    end
  end
end
