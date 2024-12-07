class Shipment
  module Decorator
    include CustomerNotifierHelper # for format_time_range

    def order_is_shipped
      order_items.any? { |oi| oi.shipping_method&.shipping_type == 'shipped' }
    end

    def order_is_chilled
      order_items.any? { |oi| oi.variant.hierarchy_type && (oi.variant.hierarchy_type.is_type?('white', 'wine') || oi.variant.hierarchy_type.is_type?('champagne & sparkling', 'wine')) }
    end

    def supplier_allows_automatic_notes
      region = Region.find_by(name: 'Vineyard Select')
      return true if region.blank?

      order_items.any? { |oi| oi.supplier&.region_id != region.id }
    end

    def supplier_delivery_notes
      notes = []
      notes << order_delivery_notes if order_delivery_notes
      notes << 'Please send white and sparkling wine chilled if possible.' if !order.delivery_notes && !order_is_shipped && order_is_chilled && supplier_allows_automatic_notes
      notes.map { |n| n.to_s.strip }.compact.join("\n\n")
    end

    def format_scheduling_window
      window_size = shipping_method.try(:scheduled_interval_size) || 120
      format_time_range(scheduled_for, window_size, supplier.try(:timezone))
    end

    def supplier_dash_state
      case state
      when 'ready_to_ship', 'paid'
        'paid'
      when 'pending'
        'paid'
      else
        state
      end
    end
  end
end
