# frozen_string_literal: true

class Auth0Client
  attr_reader :storefront

  def initialize(storefront, use_storefront_api_domain = false)
    @storefront = storefront
    @use_storefront_api_domain = use_storefront_api_domain
  end

  def call
    Faraday.new(api_endpoint) do |client|
      client.request :url_encoded
      client.adapter Faraday.default_adapter
      client.use Faraday::Response::RaiseError
    end
  end

  private

  def api_endpoint
    "https://#{@use_storefront_api_domain ? storefront.auth0_api_domain : storefront.auth0_domain}"
  end
end
