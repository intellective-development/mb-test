class ShipEngineAdapter::Requests::DisconnectCarrierAccount
  def initialize(conn:, carrier:, carrier_id:)
    raise ArgumentError.new, 'Carrier cannot be nil' if carrier.nil?
    raise ArgumentError.new, 'Carrier ID cannot be nil' if carrier_id.nil?

    carrier.downcase!

    @conn = conn
    @carrier = carrier
    @carrier_id = carrier_id
  end

  def call
    @conn.delete do |req|
      req.url "/v1/connections/carriers/#{@carrier}/#{@carrier_id}"
      req.headers['API-Key'] = ENV['SHIP_ENGINE_API_KEY']
    end
  end
end
