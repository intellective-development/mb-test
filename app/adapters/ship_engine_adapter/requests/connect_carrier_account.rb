class ShipEngineAdapter::Requests::ConnectCarrierAccount
  class AccountAlreadyConnectedForCarrierError < StandardError; end

  CARRIERS_REQUIRING_ADDRESS = %w[fedex ups].freeze

  def initialize(conn:, supplier:, carrier:, account_details:)
    raise ArgumentError.new, 'Supplier cannot be nil' if supplier.nil?
    raise ArgumentError.new, 'Carrier cannot be nil' if carrier.nil?
    raise ArgumentError.new, "Supplier's address cannot be nil" if supplier.address.nil?

    account_details = OpenStruct.new(account_details)

    carrier = carrier.downcase.squish
    @carrier = carrier if carrier.in?(ShipEngineAdapter::SUPPORTED_CARRIERS)

    raise ShipEngineAdapter::UnsupportedCarrierError.new, 'Unsupported carrier' if @carrier.nil?
    raise AccountAlreadyConnectedForCarrierError.new, 'Account already connected for this carrier' if supplier.ship_engine_carrier_accounts.exists?(carrier: @carrier)

    @conn = conn
    @supplier = supplier
    @first_name = account_details.first_name
    @last_name = account_details.last_name
    @account_number = account_details.account_number
    @username = account_details.username
    @password = account_details.password
    @api_key = account_details.api_key

    if @carrier.in?(CARRIERS_REQUIRING_ADDRESS)
      @address = supplier.address if account_details.address.nil?
      @address ||= OpenStruct.new(account_details.address)

      raise ArgumentError.new, 'Address should contain the following keys: address1, city, state_name, zip_code and phone' if %i[address1 city state_name zip_code phone].any? { |key| @address.send(key).nil? }
    end
  end

  def call
    @conn.post do |req|
      req.url "/v1/connections/carriers/#{@carrier}"
      req.headers['API-Key'] = ENV['SHIP_ENGINE_API_KEY']
      req.body = send("#{@carrier}_account_params".to_sym)
    end
  end

  private

  def fedex_account_params
    {
      nickname: build_unique_name,
      account_number: @account_number,
      company: build_unique_name,
      first_name: @first_name,
      last_name: @last_name,
      country_code: 'US',
      email: @supplier.email,
      agree_to_eula: true
    }.merge(account_address_params)
  end

  def ups_account_params
    {
      nickname: build_unique_name,
      account_number: @account_number,
      company: build_unique_name,
      first_name: @first_name,
      last_name: @last_name,
      country_code: 'US',
      email: @supplier.email,
      account_country_code: 'US',
      account_postal_code: @address.zip_code,
      agree_to_technology_agreement: true
    }.merge(account_address_params)
  end

  def gls_us_account_params
    {
      nickname: build_unique_name,
      account_number: @account_number.to_i,
      username: @username,
      password: @password
    }
  end

  def better_trucks_account_params
    {
      nickname: build_unique_name,
      api_key: @api_key
    }
  end

  def account_address_params
    return {} if @address.nil?

    {
      address1: @address.address1,
      address2: @address.address2,
      city: @address.city,
      state: @address.state_name,
      postal_code: @address.zip_code,
      phone: @address.phone
    }
  end

  def build_unique_name
    "#{@supplier.id}: #{@supplier.display_name[0..25].strip}"
  end
end
