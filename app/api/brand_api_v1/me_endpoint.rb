class BrandAPIV1::MeEndpoint < BaseAPIV1
  namespace :me do
    desc 'Returns information on the current user.'
    get do
      validate_brand_content_manager!

      present resource_owner, with: BrandAPIV1::Entities::User
    end
  end
end
