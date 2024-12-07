class AfterShipAdapter
  class UnsuccessfulResponseError < StandardError; end

  BASE_URL = 'https://api.aftership.com'.freeze

  def initialize
    @conn = faraday_conn
  end

  def create_tracking(package:)
    resp = Requests::CreateTracking.new(
      conn: @conn,
      package: package
    ).call

    raise UnsuccessfulResponseError.new, unsuccessful_response_error_message(resp) unless resp.success?

    resp.body
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
    "#{resp.status}: #{resp.reason_phrase} (#{resp.body.fetch('meta').fetch('type')}: #{resp.body.fetch('meta').fetch('message')})"
  end
end
