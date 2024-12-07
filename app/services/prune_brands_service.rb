class PruneBrandsService
  def initialize; end

  def call
    Brand.not_parent_brand.find_each do |brand|
      next if brand.product_size_groupings.where('product_groupings.state != ?', 'merged').exists?

      brand.destroy
    end
  end
end
