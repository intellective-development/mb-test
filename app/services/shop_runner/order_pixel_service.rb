module ShopRunner
  class OrderPixelService
    require 'faraday'
    require 'faraday/detailed_logger'
    require 'typhoeus'
    require 'typhoeus/adapters/faraday'

    attr_reader :order

    def initialize(order)
      @order = order
    end

    def call
      return unless order.shoprunner_token

      client.get do |request|
        request.params = pixel_params
      end
    end

    private

    def client
      @client ||= Faraday.new(url: ENV['SHOPRUNNER_PIXEL_URL']) do |faraday|
        faraday.response :detailed_logger, Rails.logger, 'ShopRunner Pixel'
        faraday.adapter  :typhoeus
      end
    end

    def pixel_params
      {
        version: 4,
        rID: ENV['SHOPRUNNER_PARTNER_ID'],
        oID: order.number,
        tID: order.shoprunner_token,
        prd: shoprunner_products.join('|'),
        toa: order.taxed_total.to_f.round_at(2),
        billingsubtotal: (order.sub_total - order.discounts_total).to_f.round_at(2),
        ttype: ShopRunner::OrderFeedService::SHOPRUNNER_PAYMENT_TYPES[order.payment_profile.cc_type]
      }
    end

    def shoprunner_products
      order.order_items.map do |order_item|
        [
          order_item.variant.sku,
          order_item.quantity,
          order_item.price,
          'OTHER',
          true
        ].join('~')
      end
    end
  end
end
