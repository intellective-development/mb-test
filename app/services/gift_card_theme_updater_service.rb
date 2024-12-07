class GiftCardThemeUpdaterService
  GIFT_CARD_PRICES = [25, 50, 75, 100, 150, 200, 250, 300, 350, 500, 1].freeze
  attr_accessor :theme, :product_grouping

  def initialize(theme)
    @theme = theme
    @product_grouping = theme.product_size_grouping
  end

  def update!
    update_products!
    set_products_active_or_inactive!
    reindex!
  end

  def update_products!
    if @product_grouping.products.empty?
      variants_values.each do |variant_values|
        product = create_product!(variant_values[:name])
        create_variant!(product, variant_values)
      end
    else
      products = @product_grouping.products
      variants_values.each do |variant_values|
        product = products.find { |prod| prod.variants[0].price == variant_values[:price] }
        update_product!(product, variant_values)
      end
    end
  end

  def create_product!(name)
    Product.create(name: name, product_size_grouping: @product_grouping, searchable: false)
  end

  def create_variant!(product, values)
    Variant.create(supplier: supplier, product: product, sku: product.permalink, name: product.name, original_price: values[:price], price: values[:price], product_active: true, options_type: :gift_card, overridable: values[:overridable], inventory: Inventory.create(count_on_hand: 1000))
  end

  def update_product!(product, values)
    product.update(name: values[:name])
    product.variants[0].update(name: values[:name])
  end

  def set_products_active_or_inactive!
    @product_grouping.products.each do |product|
      product.activate!   if product.state != 'active' && @theme.active?
      product.deactivate! if product.state == 'active' && !@theme.active?
    end
  end

  def reindex!
    @product_grouping.reload.reindex_async
    @product_grouping.products.each(&:reindex_async)
    @product_grouping.variants.each(&:reindex_async)
  end

  def supplier
    @supplier ||= Supplier.find_by(permalink: @theme.storefront.business.product_supplier_permalink)
  end

  def variants_values
    GIFT_CARD_PRICES.map do |price|
      price_text  = price == 1 ? 'Custom' : "$#{price}"
      overridable = price == 1
      { name: "#{@theme.name} #{price_text}", price: price, overridable: overridable }
    end
  end
end
