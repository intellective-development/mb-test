class Admin::Content::HomepageProductsController < Admin::BaseController
  def index
    @products = ProductSizeGrouping.tagged_with('hp_placement')
                                   .page(params[:page] || 1)
                                   .per(params[:per_page] || 30)

    filters = ContentPlacement::BASE_SEARCH_FILTERS.merge(supplier_id: [10, 27],
                                                          search_volume: ['330ml', '720ml', '750ml', '6 pack', '1L'],
                                                          tags: { not: ['hp_placement'] })

    @eligible_products = Rails.cache.fetch('admin::content::homepage_featured::top_products', expires_in: 30.minutes) do
      Variant.search(includes: ContentPlacement::SEARCH_INCLUDES,
                     where: filters,
                     order: [{ popularity_60day: 'desc' }],
                     boost_by: [:popularity_60day],
                     limit: 500)
    end
  end

  def add
    product_size_grouping = Product.find(params[:homepage_products][:product_id])&.product_size_grouping
    if product_size_grouping
      product_size_grouping.tag_list.add('hp_placement')
      expire_fragment('homepage::top_products') if product_size_grouping.save
      flash[:notice] = 'Updated Product'
    else
      flash[:error] = 'Unable to update product.'

    end

    redirect_to admin_content_homepage_products_path
  end

  def remove
    product_size_grouping = Product.find(params[:homepage_product_id])&.product_size_grouping
    if product_size_grouping
      product_size_grouping.tag_list.remove('hp_placement')
      expire_fragment('homepage::top_products') if product_size_grouping.save
      flash[:notice] = 'Updated Product'
    else
      flash[:error] = 'Unable to update product.'
    end

    redirect_to admin_content_homepage_products_path
  end

  def expire
    expire_fragment('homepage::top_products')
    flash[:notice] = 'Cache Expired'
    redirect_to admin_content_homepage_products_path
  end
end
