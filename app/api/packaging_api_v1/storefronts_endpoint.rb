class PackagingAPIV1::StorefrontsEndpoint < PackagingAPIV1
  helpers Shared::Helpers::StorefrontHelper

  resource :storefronts do
    route_param :permalink do
      before do
        @storefront = Storefront.find_by(permalink: sanitize_permalink(params[:permalink]))

        error!('Storefront not found', 404) if @storefront.nil?
      end

      desc 'Returns a storefront by given permalink'
      params do
        requires :permalink, type: String, desc: 'Permalink', allow_blank: false
      end

      get do
        status 200
        present @storefront, with: PackagingAPIV1::Entities::Storefront
      end
    end
  end
end
