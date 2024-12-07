module Fraud
  class CreateOrderEvent < Event
    def initialize(order)
      super(order.user, nil, nil)
      @order = order
    end

    def self.event_type
      '$create_order'
    end

    def properties
      # Note on custom fields:
      # - CAN'T start with $
      # - Can only be strings or numbers (floats/ints)
      # - Can only be on the top level (this properties method)
      # - If you have the same custom field name in another event, they both need to have the same data
      # - Anything else causes failure
      super.merge(
        '$order_id' => @order.number,
        '$user_email' => @user.guest_by_email? ? @order.email : @user.email,
        '$ip' => @order.ip_address,
        '$amount' => currency_amount(@order.taxed_total),
        '$currency_code' => 'USD',
        '$billing_address' => address_properties(@order.bill_address),
        '$payment_methods' => [payment_profile_properties(@order.payment_profile)],
        '$shipping_address' => address_properties(@order.ship_address),
        '$shipping_method' => @order.digital? ? '$electronic' : '$physical',
        '$items' => order_items_array(@order.order_items),
        '$seller_user_id' => @order.suppliers.limit(1).pluck(:permalink).pop,
        '$promotions' => promotions_array(@order.coupon),

        'channel' => @order.doorkeeper_application_name,
        'order_notes' => @order.delivery_notes,
        'gift' => @order.gift?,
        'product_risk_score' => product_risk_score(@order.fraud_score),
        'same_day_orders' => same_day_orders(@order.user),
        'tip_amount' => tip_amount,
        'business_address' => !@order.ship_address&.company&.nil?,
        'on_demand' => @order.shipments.any? { |shipment| shipment.shipping_method.on_demand? },
        'pickup' => @order.shipments.any? { |shipment| shipment.shipping_method.pickup? },
        'shipped' => @order.shipments.any? { |shipment| shipment.shipping_method.shipped? },
        'shoprunner' => @order.shoprunner_token.present?,
        'button' => @order.button_referrer_token.present?,
        'shipping_types' => shipping_types.join(','),

        'business_id' => @order.storefront.business.id.to_s,
        'storefront_name' => @order.storefront.name,
        'storefront_pim_name' => @order.storefront.pim_name,

        # if the storefront has sift fraud checks disabled we want to bypass sift check
        'storefront_fraud_bypass' => !@order.storefront.enable_sift_fraud
      ).tap do |properties|
        if @order.gift?
          properties['gift_notes']           = @order.gift_detail&.message
          properties['gift_recipient_phone'] = @order.gift_detail&.recipient_phone
        end
        properties.delete('$shipping_address') if @order.digital?
      end
    end

    def order_items_array(order_items)
      order_items.map { |order_item| order_item_properties(order_item) }
    end

    def shipping_types
      @order.shipments.map { |sh| sh.shipping_method&.shipping_type }.compact.uniq
    end

    def order_item_properties(order_item)
      {
        '$item_id' => order_item.product_id.to_s,
        '$product_title' => order_item.product_name,
        '$price' => currency_amount(order_item.price),
        '$currency_code' => 'USD',
        '$upc' => order_item.product_upc,
        '$sku' => order_item.variant_sku, # TODO: Consider removing?
        '$brand' => order_item.brand_name,
        '$category' => order_item.product_type_hierarchy.map(&:name).join(' > '),
        '$tags' => order_item.product_grouping_tag_list,
        '$quantity' => order_item.quantity,
        '$size' => order_item.product_admin_item_volume
      }
    end

    def promotions_array(coupon)
      [].tap { |promotions| promotions << promotion_properties(coupon) if coupon }
    end

    def promotion_properties(coupon)
      {
        '$promotion_id' => coupon.code,
        '$status' => '$success',
        '$discount' => {
          '$amount' => currency_amount(coupon.value(@order)),
          '$currency_code' => 'USD',
          '$minimum_purchase_amount' => currency_amount(coupon.minimum_value)
        }
      }
    end

    def product_risk_score(fraud_score)
      fraud_score&.results&.dig('check_products') || 0
    end

    def same_day_orders(user)
      user.orders.finished.where('completed_at > ?', Time.current.beginning_of_day).count
    end

    def tip_amount
      # The rescue prevents a divide by zero error in cases where the order total
      # is 0.0 - this occasionally occurs with some of our high value coupons and gift
      # cards.
      return 0.0 if @order.taxed_total.zero?

      Integer(@order.tip_amount / @order.taxed_total * 100)
    end

    def call_and_run_workflow
      response = notify_sift(
        self.class.event_type,
        properties,
        return_workflow_status: true,
        abuse_types: ['payment_abuse']
      )
      result = response&.body&.dig('score_response', 'workflow_statuses')&.first&.dig('history')&.first
      decision = case result&.dig('app')
                 when 'decision'
                   result.dig('config', 'decision_id') # looks_bad_payment_abuse, looks_ok_payment_abuse
                 when 'review queue'
                   'review_queue'
                 end
      {
        score: response&.body&.dig('score_response', 'scores', 'payment_abuse', 'score'),
        decision: decision
      }
    end
  end
end
