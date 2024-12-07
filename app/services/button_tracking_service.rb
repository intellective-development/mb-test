class ButtonTrackingService
  attr_reader :order

  def initialize(order)
    @order = order
  end

  def perform
    response = connection.post do |req|
      req.url '/v1/order'
      req.headers['Authorization'] = "Basic #{Settings.button.auth_token}"
      req.headers['Content-Type']  = 'application/json'
      req.body = request_params.to_json
    end

    Rails.logger.error("Button Tracking Event Failed: #{response.inspect}") unless response.success?

    response
  end

  def cancel
    response = connection.delete do |req|
      req.url "/v1/order/#{order.number}"
      req.headers['Authorization'] = "Basic #{Settings.button.auth_token}"
    end

    Rails.logger.error("Button Cancellation Event Failed: #{response.inspect}") unless response.success?

    response
  end

  private

  def request_params
    {
      advertising_id: order.device_udid,
      btn_ref: order.button_referrer_token,
      currency: 'USD',
      order_id: order.number,
      total: format_currency(order.sub_total),
      customer: {
        id: order.user.referral_code,
        email_sha256: Digest::SHA256.hexdigest(String(order.user.email).downcase)
      },
      line_items: order_line_items
    }.compact
  end

  def order_line_items
    order.order_items.map do |order_item|
      {
        identifier: order_item.product.permalink,
        amount: format_currency(order_item.price),
        quantity: order_item.quantity,
        description: order_item.product.product_size_grouping.name,
        attributes: {
          upc: order_item.product.upc
        }
      }
    end
  end

  def format_currency(value)
    (value * 100).to_i
  end

  def connection
    require 'faraday'
    require 'faraday/detailed_logger'
    require 'typhoeus'
    require 'typhoeus/adapters/faraday'

    Faraday.new(url: 'https://api.usebutton.com') do |faraday|
      faraday.response :detailed_logger, Rails.logger, 'Button Request'
      faraday.adapter  :typhoeus
    end
  end
end
