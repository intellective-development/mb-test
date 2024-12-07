class PackagingAPIV1::StorefrontEndpoint < PackagingAPIV1
  desc 'Exposes the current storefront'
  get :storefront do
    status 200
    present storefront, with: PackagingAPIV1::Entities::Storefront
  end
end
