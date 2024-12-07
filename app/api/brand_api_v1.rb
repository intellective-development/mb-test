require 'doorkeeper/grape/helpers'

class BrandAPIV1 < BaseAPIV1
  format :json
  prefix 'api/brand'
  version 'v1', using: :path

  helpers Doorkeeper::Grape::Helpers

  helpers do
    # Find the user that owns the access token
    def resource_owner
      User.find_by(account_id: doorkeeper_token.resource_owner_id) if doorkeeper_token&.resource_owner_id
    end

    def validate_brand_content_manager!
      error!('Unauthorized', 401) unless resource_owner&.has_role?(:brand_content_manager)
      error!('User does not have any brand associations.', 400) unless resource_owner.brand
    end

    def current_brands_product_groupings
      @current_brands_product_groupings ||= current_brand.active_self_and_descendents_product_groupings
    end

    def current_brand
      @current_brand ||= resource_owner&.brand
    end

    def clean_params(params)
      ActionController::Parameters.new(params)
    end
  end

  mount BrandAPIV1::MeEndpoint
  mount BrandAPIV1::ProductSizeGroupingsEndpoint
  mount BrandAPIV1::ProductTypesEndpoint
end
