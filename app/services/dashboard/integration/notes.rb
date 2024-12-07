module Dashboard
  module Integration
    class Notes
      def initialize(prefix, user_id)
        @prefix = prefix
        @user_id = user_id
      end

      def add_note(shipment, note, critical = false, asana_tags = [])
        comment = shipment.comments.create(
          note: "#{@prefix}: #{note}",
          created_by: @user_id
        )
        add_asana_ticket(shipment, comment, asana_tags) if critical
      end

      def add_asana_ticket(shipment, comment, tags = [])
        InternalAsanaNotificationWorker.perform_async(
          tags: tags,
          name: "Order #{shipment.order_number} - #{shipment.user_name}",
          notes: "#{shipment.supplier_name}: \n\n #{comment.note}\n\n Order: #{ENV['ADMIN_SERVER_URL']}/admin/fulfillment/orders/#{shipment.order_id}/edit"
        )
      end
    end
  end
end
