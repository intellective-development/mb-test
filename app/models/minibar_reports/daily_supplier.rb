module MinibarReports
  class DailySupplier
    attr_reader :supplier, :orders, :shipments

    def initialize(supplier_id, starts_at = Date.yesterday.beginning_of_day, ends_at = Date.yesterday.end_of_day)
      @supplier = Supplier.find(supplier_id)

      # FIXME: Not the most efficient process - we may wish to either fetch shipments (since we can filter by
      #        supplier_id) and then retrieve orders, or use one of the queries shared by Supplier Dash.
      @orders = Order.finished
                     .where('completed_at > ?', starts_at)
                     .where('completed_at < ?', ends_at)
                     .select { |o| o.shipments.where(supplier_id: @supplier.id).any? && !o.canceled? }
      @shipments = @orders.flat_map { |o| o.shipments.where(supplier_id: @supplier.id) }
    end

    def total_sales
      @shipments.map(&:shipment_total_amount).sum(&:to_f)
    end

    def total_orders
      @orders.length
    end
  end
end
