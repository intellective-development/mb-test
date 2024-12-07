class AfterShipAdapter::Requests::CreateTracking
  def initialize(conn:, package:)
    @conn = conn
    @package = package
  end

  def call
    @conn.post do |req|
      req.url '/v4/trackings'
      req.headers['aftership-api-key'] = ENV['AFTER_SHIP_API_KEY']
      req.body = tracking_params
    end
  end

  private

  def tracking_params
    {
      tracking: {
        tracking_number: @package.tracking_number,
        order_number: shipment.order.number,
        emails: [shipment.order.user.email],
        shipment_tags: [formatted_supplier_display_name],
        tracking_postal_code: destination_postal_code,
        origin_country_iso3: 'USA',
        origin_state: supplier.address.state_name,
        origin_city: supplier.address.city,
        origin_postal_code: supplier.address.zip_code,
        destination_country_iso3: 'USA',
        destination_state: shipment.address.state_name,
        destination_city: shipment.address.city,
        destination_postal_code: destination_postal_code
      }
    }
  end

  def formatted_supplier_display_name
    @shipment.supplier.display_name[0..31].strip
  end

  def shipment
    @shipment ||= @package.shipment
  end

  def supplier
    @supplier ||= @package.shipment.supplier
  end

  def destination_postal_code
    shipment.address.zip_code
  end
end
