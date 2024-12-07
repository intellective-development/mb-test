class Shipment
  module SegmentSerializer
    extend ActiveSupport::Concern

    def as_segment_object(email_delivery_date)
      {
        delivery_expectation: delivery_expectation_based_on_type(email_delivery_date),
        shipping_type: shipping_method.shipping_type,
        tracking_url: delivery_tracking_url,
        products: order_items.map do |order_item|
          product = order_item.product
          {
            name: product.name,
            product_image: product.featured_image(:product),
            product_page: product.product_size_grouping.product_page_url,
            price: order_item.price.to_f,
            quantity: order_item.quantity.to_f
          }
        end
      }
    end

    def delivery_expectation_based_on_type(email_delivery_date)
      # We use email_delivery_date for when it's a multi-shipment with different shipping methods order
      shipping_method.delivery_expectation
      if on_demand? && scheduled_for.blank?
        'Expected delivery under an hour'
      elsif on_demand? && scheduled_for.to_date == email_delivery_date
        "Expected delivery between #{format_scheduling_window}"
      else
        'Expected delivery between 3 to 7 business days'
      end
    end

    def segment_delivery_date
      # Rules defined based off TECH-3423
      return scheduled_for.to_date if on_demand? && scheduled_for
      return Date.today if on_demand?

      Date.today + 2.days # all shipped shipments will be notified after today + 2 days
    end

    def delivery_tracking_url
      if delivery_service_order
        delivery_service_order['tracking_url'] || delivery_service_order['delivery_tracking_url']
      else
        tracking_detail&.tracking_url
      end
    end
  end
end
