class ShipEngineAdapter
  class UnsuccessfulResponseError < StandardError; end
  class UnsupportedCarrierError < StandardError; end
  class CarrierAccountNotConnectedError < StandardError; end
  class CarrierGroundServiceNotAvailableError < StandardError; end
  class ShipEngineDetailMissingError < StandardError; end
  class ShipEngineRedirectError < StandardError; end

  BASE_URL = 'https://api.shipengine.com'.freeze
  SUPPORTED_CARRIERS = %w[fedex ups better_trucks lso gls_us].freeze
  SUPPORTED_CARRIER_SERVICE_CODES = {
    fedex: 'fedex_ground',
    ups: 'ups_ground',
    better_trucks: 'economy_delivery_service',
    lso: 'lonestar_ground',
    gls_us: 'gls_us_ground'
  }.freeze

  def initialize
    @conn = faraday_conn
  end

  def validate_address(address:)
    resp = Requests::ValidateAddress.new(
      conn: @conn,
      address: address
    ).call

    raise UnsuccessfulResponseError.new, "#{resp.status}: #{resp.reason_phrase}" unless resp.success?

    resp_body = resp.body[0]
    status = resp_body.fetch('status')
    error_message = resp_body.fetch('messages')[0]&.fetch('message')

    case status
    when 'verified'
      raise Requests::ValidateAddress::AddressWarningError.new(resp_body), error_message if error_message.present?

      resp_body
    when 'unverified'
      raise Requests::ValidateAddress::AddressUnverifiedError.new(resp_body), error_message
    when 'error'
      raise Requests::ValidateAddress::AddressError.new(resp_body), error_message
    end
  end

  def connect_carrier_account(supplier:, carrier:, account_details:)
    resp = Requests::ConnectCarrierAccount.new(
      conn: @conn,
      supplier: supplier,
      carrier: carrier,
      account_details: account_details
    ).call

    raise ShipEngineRedirectError.new, resp['location'] if resp.status == 302
    raise UnsuccessfulResponseError.new, unsuccessful_response_error_message(resp) unless resp.success?

    resp.body
  end

  def disconnect_carrier_account(carrier:, carrier_id:)
    resp = Requests::DisconnectCarrierAccount.new(
      conn: @conn,
      carrier: carrier,
      carrier_id: carrier_id
    ).call

    raise UnsuccessfulResponseError.new, unsuccessful_response_error_message(resp) unless resp.success?

    resp.body
  end

  def estimate_rate(package:)
    resp = Requests::EstimateRate.new(
      conn: @conn,
      package: package
    ).call

    raise UnsuccessfulResponseError.new, unsuccessful_response_error_message(resp) unless resp.success?

    service = resp.body.find { |s| s.fetch('service_code') == SUPPORTED_CARRIER_SERVICE_CODES[package.carrier.downcase.to_sym] }
    service || (raise CarrierGroundServiceNotAvailableError.new, "Carrier's ground service not available for the given package details. Package may be over size or weight limits.")
  end

  def create_label(package:)
    resp = Requests::CreateLabel.new(
      conn: @conn,
      package: package
    ).call

    raise UnsuccessfulResponseError.new, unsuccessful_response_error_message(resp) unless resp.success?

    resp
  end

  private

  def faraday_conn
    require 'faraday'

    Faraday.new(url: BASE_URL) do |f|
      f.request :json
      f.response :json
      f.adapter :net_http
    end
  end

  def unsuccessful_response_error_message(resp)
    "#{resp.status}: #{resp.reason_phrase} (#{resp.body.fetch('errors').map { |e| e.fetch('message') }.to_sentence})"
  end
end
