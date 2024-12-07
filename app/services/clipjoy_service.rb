class ClipjoyService
  require 'faraday'

  def initialize(order)
    @order = order
    @conn = Faraday.new(url: api_url)
  end

  def notify_purchase
    call_clipjoy_endpoint
    save_gift_video_message
  end

  private

  def save_gift_video_message
    VideoGiftMessage.create(order: @order, record_video_url: record_video_url, qr_code_url: qr_code_url, video_tag_id: @video_tag_id)
  end

  def call_clipjoy_endpoint
    url = '/purchaseComplete'
    api_response = get(url, purchase_params)
    body = JSON.parse(api_response.body)
    @video_tag_id = body['objectId']
  end

  def record_video_url
    "#{watch_url}/?id=#{@video_tag_id}&record=true"
  end

  def qr_code_url
    "#{api_url}/getPrintCode?key=#{key}&orderid=#{@order.number}"
  end

  def purchase_params
    {
      "orderid": @order.number,
      "firstName": @order.user.first_name,
      "lastName": @order.user.last_name,
      "email": @order.user.email,
      "sendemail": false,
      "key": key
    }
  end

  def key
    case @order.storefront.permalink
    when 'reservebar' then ENV['CLIPJOY_API_KEY_RB']
    when 'get-stocked' then ENV['CLIPJOY_API_KEY_GET_STOCKED']
    else
      raise ArgumentError.new, "Please provide a Clipjoy API key for #{@order.storefront.name} storefront."
    end
  end

  def api_url
    ENV['CLIPJOY_API_URL']
  end

  def watch_url
    ENV['CLIPJOY_WATCH_URL']
  end

  def get(url, params)
    @conn.get do |req|
      req.url(url)
      req.headers['ACCEPTS'] = 'application/json'
      req.params = params
    rescue Faraday::Error => e
      raise
    end
  end
end
