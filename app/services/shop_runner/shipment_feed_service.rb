module ShopRunner
  class ShipmentFeedService
    require 'savon'

    attr_reader :order

    def initialize(order)
      @order = order
    end

    def call
      return unless order.shoprunner_token

      client.call(:shipment, message: message)
    end

    private

    def client
      @client ||= Savon.client do |config|
        config.convert_request_keys_to :camelcase
        config.endpoint ENV['SHOPRUNNER_SHIPMENT_FEED_URL']
        config.log true
        config.log_level :debug
        config.namespace 'http://www.shoprunner.com/schema/ShipmentWS'
        config.namespace_identifier :ord
        config.pretty_print_xml true
        config.wsdl ENV['SHOPRUNNER_SHIPMENT_FEED_WSDL']
        config.wsse_auth ENV['SHOPRUNNER_WSDL_USER'], ENV['SHOPRUNNER_WSDL_PASSWORD'], :digest
      end
    end

    def message
      {
        partner: ENV['SHOPRUNNER_PARTNER_ID'],
        shipment: {
          retailer_order_number: order.number,
          carrier_code: 'MINIBAR',
          tracking_number: "#{order.number}-LOCAL",
          number_of_items: order.order_items.sum(:quantity),
          number_of_s_r_items: order.order_items.sum(:quantity)
        }
      }
    end
  end
end
