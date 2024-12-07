class ExternalAPIV1::StorefrontsEndpoint < ExternalAPIV1
  resource :storefronts do
    desc 'Returns all storefronts.'
    get do
      @storefronts = Storefront.all

      status 200
      present @storefronts, with: ExternalAPIV1::Entities::Storefront
    end
  end
end
