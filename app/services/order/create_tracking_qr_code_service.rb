class Order::CreateTrackingQrCodeService
  def initialize(order_id:)
    @order = Order.find(order_id)
  end

  def call
    qr_code = RQRCode::QRCode.new(qr_url)

    png = qr_code.as_png(
      color_mode: ChunkyPNG::COLOR_GRAYSCALE,
      color: 'black',
      file: nil,
      fill: 'white',
      resize_exactly_to: false,
      resize_gte_to: false,
      size: 180,
      module_px_size: 6,
      border_modules: 4
    )

    Base64.strict_encode64(png.to_s)
  end

  def qr_url
    uri = order.base_tracking_uri
    uri.query = qr_url_params

    uri.to_s
  end

  private

  attr_reader :order

  def qr_url_params
    {
      hash: order_tracking_hash,
      utm_medium: 'qrcode',
      utm_source: 'packing+slip',
      utm_campaign: 'RB+%7C+2022+%7C+launch'
    }.map { |k, v| "#{k}=#{v}" }.join('&')
  end

  def order_tracking_hash
    Order::Hasher.new(order: order).encode
  end
end
