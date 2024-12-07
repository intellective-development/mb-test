require 'doorkeeper/grape/helpers'

class PackagingAPIV1 < BaseAPIV1
  format :json
  version 'v1', using: :path
  prefix 'api/packaging'

  helpers Doorkeeper::Grape::Helpers

  before do
    authenticate!
  end

  helpers do
    def authenticate!
      error!('Unauthorized', 401) unless doorkeeper_token
    end

    def storefront
      return @storefront if @storefront.present?

      app = doorkeeper_token&.application
      @storefront = Storefront.find_by(oauth_application_id: app.id) if app.present?

      error!('Unauthorized', 401) if @storefront.nil?

      @storefront
    end
  end

  mount PackagingAPIV1::OrdersEndpoint
  mount PackagingAPIV1::StorefrontsEndpoint
  mount PackagingAPIV1::StorefrontsEndpoint::OrderEndpoint::PreviewsEndpoint
  mount PackagingAPIV1::StorefrontEndpoint
  mount PackagingAPIV1::StorefrontEndpoint::DigitalPackingSlipPlacementsEndpoint
end
