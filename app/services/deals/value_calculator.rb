module Deals
  class ValueCalculator
    extend Forwardable
    def_delegators :@restrictions, :allows_alcohol_discounts?, :allows_shipping_discounts?

    def initialize(restrictions, order_items: [])
      @restrictions = restrictions
      @order_items  = order_items
    end

    def call(shipment, deal)
      case deal
      when FreeShipping
        # TODO: JM: This should become @shipment.shipping_charges when Shipment has been aligned with Order::Amounts
        shipping_charges_or_limit(deal, shipment.shipment_shipping_charges || shipment.delivery_fee)
      when VolumeDiscount
        if deal.discount_type == 'Percentage'
          percentage_or_limit(deal, case_eligible_total(shipment.order_items))
        else
          split_value_or_limit(case_eligible_total(shipment.order_items), case_eligible_total(@order_items), deal.amount)
        end
      when Percentage
        percentage_or_limit(deal, eligible_total(shipment.order_items))
      when MonetaryValue
        split_value_or_limit(eligible_total(shipment.order_items), eligible_total(@order_items), deal.amount)
      when TwoForOneDiscount
        two_for_one_total(two_for_one_items(shipment.order_items, deal), deal)
      else
        0
      end
    end

    def call_for_item(item, deal)
      case deal
      when VolumeDiscount
        if deal.discount_type == 'Percentage'
          percentage_or_limit(deal, case_eligible_total([item]))
        else
          split_value_or_limit(case_eligible_total([item]), case_eligible_total(@order_items), deal.amount)
        end
      when Percentage
        percentage_or_limit(deal, eligible_total([item]))
      when MonetaryValue
        split_value_or_limit(eligible_total([item]), eligible_total(@order_items), deal.amount)
      when TwoForOneDiscount
        two_for_one_total(two_for_one_items([item], deal), deal)
      else
        0
      end
    end

    def two_for_one_items(order_items, deal)
      order_items
        .select { |item| allows_alcohol_discounts? || !item.alcohol? }
        .select { |item| !item.two_for_one.nil? && item.quantity >= deal.minimum_units.to_i }
    end

    def two_for_one_discount(item, deal)
      if item.two_for_one == deal.amount
        (item.price - deal.amount) * (item.quantity / 2).floor
      else
        0
      end
    end

    def two_for_one_total(two_for_one_items, deal)
      two_for_one_items.sum { |item| BigDecimal(two_for_one_discount(item, deal), 15) }
    end

    def case_eligible_total(order_items)
      eligible_total order_items.select(&:case_eligible?)
    end

    def eligible_total(order_items)
      order_items
        .select { |item| allows_alcohol_discounts? || !item.alcohol? }
        .sum    { |item| BigDecimal(item.total, 15) }
    end

    def shipping_charges_or_limit(deal, shipping_charges)
      value_or_limit (allows_shipping_discounts? ? shipping_charges : shipping_charges - 1.0), deal.maximum_value
    end

    def percentage_or_limit(deal, total)
      value_or_limit((deal.percentage / 100) * total, deal.maximum_value)
    end

    def value_or_limit(value, limit)
      BigDecimal(value > limit ? limit : value, 15).round(2)
    end

    def split_value_or_limit(shipment_total, order_total, amount)
      value_or_limit(percentage_of_order(shipment_total, order_total) * order_total, percentage_of_order(shipment_total, order_total) * amount)
    end

    def percentage_of_order(shipment_total, order_total)
      order_total.zero? ? 0 : shipment_total / order_total
    end
  end
end
