class ShipEngineAdapter::Requests::CreateLabel
  def initialize(conn:, package:)
    raise ArgumentError.new, 'Package cannot be nil' if package.nil?

    @conn = conn
    @package = package
    @shipment = @package.shipment
    @supplier = @package.supplier

    raise ArgumentError.new, "Package's supplier cannot be nil" if @supplier.nil?
    raise ArgumentError.new, "Shipment's address cannot be nil" if @shipment.address.nil?
    raise ArgumentError.new, "Supplier's address cannot be nil" if @supplier.address.nil?

    @carrier = @package.carrier.downcase.strip
    @ship_engine_detail = ship_engine_detail

    raise ArgumentError.new, 'Label for this package was already created on ShipEngine.' if @ship_engine_detail.ship_engine_label_id.present?

    @carrier_service_code = carrier_service_code
    @carrier_acc = carrier_acc
  end

  def call
    @conn.post do |req|
      req.url '/v1/labels'
      req.headers['API-Key'] = ENV['SHIP_ENGINE_API_KEY']
      req.body = shipment_params
    end
  end

  private

  def shipment_params
    {
      shipment: build_shipment
    }
  end

  def build_shipment
    dimensions = @ship_engine_detail.dimensions
    weight = @ship_engine_detail.weight
    confirmation = @ship_engine_detail.confirmation

    {
      validate_address: 'no_validation',
      service_code: @carrier_service_code,
      carrier_id: @carrier_acc.uuid,
      ship_to: {
        name: @shipment.recipient_name,
        phone: @shipment.recipient_phone,
        address_line1: @shipment.address.address1,
        address_line2: @shipment.address.address2,
        city_locality: @shipment.address.city,
        state_province: @shipment.address.state_name,
        postal_code: @shipment.address.zip_code,
        country_code: 'US'
      },
      ship_from: {
        company_name: @supplier.id,
        name: @supplier.address.company || @supplier.name[0..49],
        phone: @supplier.address.phone,
        address_line1: @supplier.address.address1,
        address_line2: @supplier.address.address2,
        city_locality: @supplier.address.city,
        state_province: @supplier.address.state_name,
        postal_code: @supplier.address.zip_code,
        country_code: 'US'
      },
      confirmation: confirmation,
      advanced_options: {
        contains_alcohol: confirmation == 'adult_signature'
      },
      packages: [
        {
          dimensions: {
            length: dimensions.fetch('length'),
            width: dimensions.fetch('width'),
            height: dimensions.fetch('height'),
            unit: 'inch'
          },
          weight: weight,
          label_messages: {
            reference1: @package.order.number,
            reference2: @supplier.id
          }
        }
      ]
    }
  end

  def ship_engine_detail
    @package.ship_engine_detail || (raise ShipEngineAdapter::ShipEngineDetailMissingError.new, 'ShipEngine details are missing. Please create a ShipEngineDetail record associated with this package')
  end

  def carrier_service_code
    ShipEngineAdapter::SUPPORTED_CARRIER_SERVICE_CODES[@carrier.to_sym] || (raise ShipEngineAdapter::UnsupportedCarrierError.new, 'Unsupported carrier')
  end

  def carrier_acc
    @supplier.ship_engine_carrier_accounts.find_by(carrier: @carrier) || (raise ShipEngineAdapter::CarrierAccountNotConnectedError.new, "Supplier does not have a connected #{@carrier.capitalize} carrier account")
  end
end
