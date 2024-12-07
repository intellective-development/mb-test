class Order
  module SegmentSerializer
    extend ActiveSupport::Concern
    def as_segment_order
      {
        id: number,
        date: created_at.strftime(Segments::SegmentService::TIME_FORMAT),
        products: segment_serialized_products,
        revenue: order_amount&.taxed_total.to_f,
        tax: order_amount&.taxed_amount.to_f,
        total: order_amount&.taxed_total.to_f,
        shipping_method_id: shipments&.first&.shipping_method_id,
        total_value: order_amount&.taxed_total,
        items: segment_serialized_items,
        source: client_source
      }
    end

    def shipments_as_segment_object(email_delivery_date)
      # email_delivery_date: date of when the iterable email will be sent to client
      # used to know what message we show as delivery_expectation
      shipments.map do |shipment|
        shipment.as_segment_object(email_delivery_date)
      end
    end

    def segment_most_relevant_shipment
      # Rules defined based off TECH-3423
      # pick any non scheduled on demand first
      on_demand_regular = shipments.find { |ship| ship.shipping_method.shipping_type == 'on_demand' && ship.scheduled_for.blank? }
      return on_demand_regular if on_demand_regular

      shipments.min_by(&:segment_delivery_date)
    end

    private

    def segment_serialized_products
      order_items.collect do |item|
        {
          brand: item.brand&.name,
          name: item.product&.name,
          price: item.price&.to_f,
          product_id: item.product_size_grouping&.id,
          sku: item.variant_sku,
          quantity: item.quantity,
          variant: item.product&.id
        }
      end
    end

    def segment_serialized_items
      order_items.collect do |item|
        {
          category: item.product&.hierarchy_category&.name,
          name: item.product_name,
          quantity: item.quantity,
          unit_price: item.price
        }
      end
    end
  end
end
