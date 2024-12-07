# frozen_string_literal: true

class ConsumerAPIV2::PingEndpoint < BaseAPIV2
  format :json

  namespace :ping do
    desc 'Returns client API keys, feature toggles and minimum client versions (for update prompting).  Clients should refresh this endpoint regularly - ideally upon launch. This is also a good endpoint to use for connectivity checks.', ConsumerAPIV2::DOC_AUTH_HEADER
    params do
      optional :id,   type: String, desc: 'iOS device UUID'
      optional :pong, type: String, desc: 'Message to return with response.'
    end
    get do
      key = headers['X-Minibar-Device-Os'].to_s =~ /Android/ ? Settings.google.android_api_key : Settings.google.ios_api_key
      features = {
        app_disabled: DeviceBlacklist.blacklisted?(params[:id] || device_id) ? 'There is a problem with your account. Please contact help@minibardelivery.com. (Error Code: -451)' : false,
        shoprunner: Feature[:shoprunner_backend].enabled?
      }
      # returning all flipper features
      flipper_features = Rails.cache.fetch('api::v2::ping::get::features', expires_in: 60.minutes) do
        Feature.flipper.features.map { |feature| { name: feature.name, enabled: feature.enabled? } }
      end

      flipper_features.each do |feature|
        features[feature[:name]] = feature[:enabled]
      end

      banner_coupon = BannerCoupon.find_by(key: BannerCoupon::INSTALL_APP_KEY)
      {
        ping: params[:pong] || 'pong',
        minimum_client_version: {
          android: Settings.minimum_android_client_version,
          ios: Settings.minimum_ios_client_version,
          iphone: Settings.minimum_client_version
        },
        keys: {
          geo_api_key: key,
          braintree_cse_key: Settings.braintree.cse_key
        },
        features: features,
        install_app_code: banner_coupon&.coupon&.code
      }
    end
  end
end
