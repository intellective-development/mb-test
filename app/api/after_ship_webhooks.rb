require 'openssl'
require 'base64'

class AfterShipWebhooks < BaseAPI
  format :json

  helpers do
    def authenticate!
      error!('Unauthorized', 401) if headers['Aftership-Hmac-Sha256'].nil? || !signature_verified?
    end

    private

    def signature_verified?
      request_signature == valid_signature
    end

    def request_signature
      headers['Aftership-Hmac-Sha256'].encode('utf-8')
    end

    def valid_signature
      Base64.encode64(OpenSSL::HMAC.digest('SHA256', ENV['AFTER_SHIP_WEBHOOK_SECRET'], request.body.read)).strip.encode('utf-8')
    end
  end

  before do
    authenticate!
  end

  desc 'Webhook endpoint for AfterShip to update the tracking status.'
  params do
    requires :event
    requires :msg
  end
  post do
    msg = params[:msg]
    tracking_number = msg.fetch('tracking_number')
    package = Package.find_by(tracking_number: tracking_number)

    status 200 and return if package.nil?

    package.update(carrier_tracking_url: msg.fetch('courier_tracking_link')) if package.carrier_tracking_url.blank?

    case params[:event]
    when 'tracking_update'
      AfterShip::EventHandlers::TrackingUpdate.new(package: package, params: params).handle
    when 'edd_revise'
      AfterShip::EventHandlers::EddRevise.new(package: package, params: params).handle
    end

    status 200
  end
end
