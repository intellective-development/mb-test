module Dashboard
  module Integration
    class MinibarDashboard
      extend DashboardInterface

      REDIS_PREFIX = 'SupplierDashboardNotificationWorker'.freeze

      def place_order(shipment)
        notify_supplier_dashboard(shipment)
      end

      def cancel_order(shipment)
        notify_supplier_dashboard(shipment)
      end

      def change_order_status(shipment, _state)
        notify_supplier_dashboard(shipment)
      end

      private

      def notify_supplier_dashboard(shipment)
        return if shipment.order&.verifying?

        shipment.receipt_url if instant_receipt_activated?(shipment.supplier_id)
        service = EntityNotificationService.new(shipment, 'fetch')
        service.call
      end

      def instant_receipt_activated?(supplier_id)
        # Activate suppliers with: Redis.current&.sadd("SupplierDashboardNotificationWorker:instant_receipt_activated_suppliers", supplier_id)
        Redis.current&.sismember("#{REDIS_PREFIX}:instant_receipt_activated_suppliers", supplier_id)
      end
    end
  end
end
