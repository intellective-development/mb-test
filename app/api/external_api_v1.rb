# ExternalAPIV1
class ExternalAPIV1 < BaseAPIV1
  format :json
  version 'v1', using: :path
  prefix 'api/external'

  helpers AuthenticateWithApiKey

  before do
    authenticate_with_api_key!
  end

  helpers do
    def current_user
      @current_user ||= api_key&.user
    end
  end

  mount ExternalAPIV1::AddressValidationEndpoint
  mount ExternalAPIV1::OrdersEndpoint
  mount ExternalAPIV1::OrdersEndpoint::CancellationsEndpoint
  mount ExternalAPIV1::OrderItemsEndpoint
  mount ExternalAPIV1::Shipments::CancellationsEndpoint
  mount ExternalAPIV1::UsersEndpoint
  mount ExternalAPIV1::CommentEndpoint
  mount ExternalAPIV1::StorefrontsEndpoint
  mount ExternalAPIV1::StorefrontOrdersEndpoint
  mount ExternalAPIV1::OrderAdjustmentReasonsEndpoint
  mount ExternalAPIV1::Shipments::OrderAdjustmentsEndpoint
end
