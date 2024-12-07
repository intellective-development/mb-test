class ShipEngineAdapter::Requests::ValidateAddress
  class InvalidAddressError < StandardError
    attr_reader :resp_body

    def initialize(resp_body)
      super
      @resp_body = resp_body
    end
  end

  class AddressUnverifiedError < InvalidAddressError; end
  class AddressWarningError < InvalidAddressError; end
  class AddressError < InvalidAddressError; end

  def initialize(conn:, address:)
    @conn = conn
    @address = address
  end

  def call
    @conn.post do |req|
      req.url '/v1/addresses/validate'
      req.headers['API-Key'] = ENV['SHIP_ENGINE_API_KEY']
      req.body = [address_params]
    end
  end

  private

  def address_params
    {
      address_line1: @address.address1,
      city_locality: @address.city,
      state_province: @address.state_name,
      postal_code: @address.zip_code,
      country_code: 'US'
    }
  end
end
