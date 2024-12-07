module ShopRunner
  class OrderFeedService
    require 'savon'

    attr_reader :order

    SHOPRUNNER_PAYMENT_TYPES = {
      'MasterCard' => 'MC',
      'Visa' => 'VI',
      'American Express' => 'AX',
      'Discover' => 'DI'
    }.freeze

    def initialize(order)
      @order = order
    end

    def call
      return unless order.shoprunner_token

      soap_body = message
      soap_body[:order][:adjustment] = cancelation_adjustment if order.canceled?

      client.call(:order, message: soap_body)
    end

    private

    def client
      @client ||= Savon.client do |config|
        config.convert_request_keys_to :camelcase
        config.endpoint ENV['SHOPRUNNER_ORDER_FEED_URL']
        config.log true
        config.log_level :debug
        config.namespace 'http://www.shoprunner.com/schema/OrderWS'
        config.namespace_identifier :ord
        config.pretty_print_xml true
        config.wsdl ENV['SHOPRUNNER_ORDER_FEED_WSDL']
        config.wsse_auth ENV['SHOPRUNNER_WSDL_USER'], ENV['SHOPRUNNER_WSDL_PASSWORD'], :digest
      end
    end

    def cancelation_adjustment
      {
        adjustment_amount: order.taxed_total.to_f.round_at(2),
        adjustment_date: order.cancelled_at&.iso8601,
        adjustment_id: order.id,
        adjustment_type: 'CANCEL',
        billing_adjustment_amount: order.sub_total.to_f.round_at(2)
      }
    end

    def message
      {
        partner: ENV['SHOPRUNNER_PARTNER_ID'],
        version_number: '3.0.1',
        order: {
          billing_sub_total: order.canceled? ? 0.0 : (order.sub_total - order.discounts_total).to_f.round_at(2),
          currency_code: 'USD',
          order_date: order.completed_at&.iso8601,
          order_number: order.number,
          order_total: order.canceled? ? 0.0 : order.taxed_total.to_f.round_at(2),
          payment_tender_type: SHOPRUNNER_PAYMENT_TYPES[order.payment_profile.cc_type],
          s_r_authentication_token: order.shoprunner_token,
          total_number_of_items: Integer(order.order_items.sum(:quantity)),
          total_number_of_shop_runner_items: Integer(order.order_items.sum(:quantity))
        }
      }
    end
  end
end
