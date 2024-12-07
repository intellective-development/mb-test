class ShipEngineAdapter::Requests::EstimateRate
  class ShipmentAddressNotProvidedError < StandardError; end

  def initialize(conn:, package:)
    @conn = conn
    @shipment = package.shipment

    raise ShipmentAddressNotProvidedError.new, "Shipment's address cannot be nil" if @shipment.address.nil?

    carrier = package.carrier.downcase

    raise ShipEngineAdapter::UnsupportedCarrierError.new, 'Unsupported carrier' unless carrier.in?(ShipEngineAdapter::SUPPORTED_CARRIERS)

    carrier_acc = @shipment.supplier.ship_engine_carrier_accounts.find_by(carrier: carrier)

    raise ShipEngineAdapter::CarrierAccountNotConnectedError.new, "Supplier does not have a connected #{carrier.capitalize} carrier account" if carrier_acc.nil?

    ship_engine_detail = package.ship_engine_detail

    raise ShipEngineAdapter::ShipEngineDetailMissingError.new, 'ShipEngine details are missing. Please create a ShipEngineDetail record associated with this package' if ship_engine_detail.nil?

    @carrier_id = carrier_acc.uuid
    @weight = ship_engine_detail.weight.symbolize_keys
    @dimensions = ship_engine_detail.dimensions.symbolize_keys
  end

  def call
    @conn.post do |req|
      req.url '/v1/rates/estimate'
      req.headers['API-Key'] = ENV['SHIP_ENGINE_API_KEY']
      req.body = estimate_rate_params
    end
  end

  private

  def estimate_rate_params
    {
      carrier_ids: [
        @carrier_id
      ],
      from_country_code: 'US',
      from_postal_code: @shipment.supplier_address.zip_code,
      to_country_code: 'US',
      to_postal_code: @shipment.address.zip_code,
      to_city_locality: @shipment.address.city,
      to_state_province: @shipment.address.state_name,
      weight: @weight,
      dimensions: {
        unit: 'inch',
        length: @dimensions.fetch(:length),
        width: @dimensions.fetch(:width),
        height: @dimensions.fetch(:height)
      }
    }
  end
end
