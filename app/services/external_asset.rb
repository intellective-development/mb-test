class ExternalAsset
  def self.apis_to_run
    {
      'wine' => [Snooth],
      'whiskey' => [Distiller],
      'beer' => [Brewdega, Anybeer]
    }
  end

  def self.run(product, product_type)
    external_assets = apis_to_run[product_type]
    external_assets.each do |asset|
      api = asset.new
      api.fetch(product, true)
      if api.found_something?
        api.update_product(product)
      else
        product.update_apis_accessed(api.api_name)
      end
    end
  end
end
