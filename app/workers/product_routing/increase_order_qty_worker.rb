class ProductRouting::IncreaseOrderQtyWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'internal',
                  lock: :until_and_while_executing

  def perform_with_error_handling(shipment_id, date_time)
    Shipment.find(shipment_id).tap do |shipment|
      supplier_product_routings = get_supplier_product_routings(shipment.supplier, date_time)

      break if supplier_product_routings.blank?

      shipment.order_items.each do |item|
        product_routing = supplier_product_routings.find { |pr| pr.product_id == item.variant.product_id }

        next if product_routing.nil?

        product_routing.increment!(:current_order_qty, item.quantity)

        inactive_product_routing(product_routing) if product_routing.current_order_qty >= product_routing.order_qty_limit
      end
    end
  end

  private

  def get_supplier_product_routings(supplier, date_time)
    ProductRouting.where(active: true)
                  .where(supplier: supplier)
                  .where('(:date BETWEEN starts_at AND ends_at) OR (starts_at < :date AND ends_at IS NULL)', date: date_time)
  end

  def inactive_product_routing(product_routing)
    ::ProductRoutings::Update.new(product_routing, { active: false }).call
  end
end
