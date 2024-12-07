class ConsumerAPIV2::StorefrontsEndpoint < BaseAPIV2
  format :json

  helpers Shared::Helpers::StorefrontHelper,
          Shared::Helpers::StorefrontParamHelper

  resource :storefronts do
    desc 'Returns active Storefronts hostnames', ConsumerAPIV2::DOC_AUTH_HEADER

    params do
      optional :hostname, type: String, allow_blank: false
    end
    get :hostnames do
      search = Storefront.active
                         .where.not(hostname: nil)
                         .includes(%i[oauth_application storefront_links storefront_fonts success_screen business])
      search = search.by_hostname_union_default(params[:hostname]) if params[:hostname].present?

      storefront_endpoints = search.each_with_object({}) do |storefront, memo|
        storefront_json = ConsumerAPIV2::Entities::Storefront.represent(storefront).as_json
        storefront.hostname&.split(',')&.each do |hostname|
          memo[hostname] = storefront_json
        end
      end

      present storefront_endpoints
    end
  end
end
