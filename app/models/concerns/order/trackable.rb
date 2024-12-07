# frozen_string_literal: true

module Order::Trackable
  extend ActiveSupport::Concern

  def status_url
    [
      "https://#{storefront.tracking_page_hostname}", storefront.permalink, "order/#{number}?email=#{user.email}"
    ].delete_if(&:blank?).join('/')
  end

  def tracking_url
    uri = base_tracking_uri
    uri.query = tracking_url_params

    uri.to_s
  end

  def base_tracking_uri
    %w[sandbox staging master].include?(ENV.fetch('ENV_NAME', 'sandbox')) ? base_tracking_original_uri : base_tracking_feature_env_uri
  end

  private

  def base_tracking_original_uri
    URI::HTTPS.build(host: storefront.tracking_page_hostname, path: "/#{storefront.permalink}/order/#{number}")
  end

  def base_tracking_feature_env_uri
    URI::HTTPS.build(host: storefront.tracking_page_hostname, path: "/services/liquid-account/#{storefront.permalink}/order/#{number}")
  end

  def tracking_url_params
    {
      email: user_email
    }.map { |k, v| "#{k}=#{v}" }.join('&')
  end
end
