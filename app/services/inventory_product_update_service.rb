class InventoryProductUpdateService
  require 'upc'

  def initialize(data, supplier_id, options)
    @supplier = Supplier.find_by(id: supplier_id)
    @options  = options.deep_symbolize_keys
    @data     = data.deep_symbolize_keys

    raise 'Invalid Supplier ID' if @supplier.nil?
  end

  def process!
    clean_data
    return false unless valid?

    @variant = find_or_initialize_variant
    unless @variant.frozen_inventory
      @product  = find_or_create_product
      @grouping = @product.product_size_grouping

      update_product_size_grouping
      update_product
      update_variant
    end

    SevenEleven::CheckProductsAlcoholSaleHoursCompatibility.new(@supplier, @variant, @data[:sale_hours]).call

    true
  end

  private

  def valid?
    @data[:sku].present? && @data[:quantity]&.between?(0, 100_000) && @data[:price]&.between?(0, 100_000)
  end

  def clean_data
    @data[:price] = Float(@data[:price])
    @data[:upc] = nil unless UPC.valid?(@data[:upc])
    @data[:volume][:volume_value]    = Float(@data[:volume][:volume_value])      if @data[:volume][:volume_value]
    @data[:volume][:container_count] = Integer(@data[:volume][:container_count]) if @data[:volume][:container_count]
  end

  def find_or_initialize_variant
    @supplier.variants.eager_load(:inventory).where(sku: @data[:sku]).first_or_initialize(
      name: @data[:name],
      protected: false
    )
  end

  def find_or_create_product
    product   = @variant.product
    product ||= Product.where(state: 'active').find_by(permalink: @data[:permalink]) if @data[:permalink].present?
    product ||= Product.find_by(upc: @data[:upc]) if @data[:upc].present?
    product ||= Product.find_by('additional_upcs @> ?', "{#{@data[:upc]}}") if @data[:upc].present?
    product ||= Product.where('lower(products.name) = ?', String(@data[:name]).downcase)
                       .find_by(@data[:volume].select { |key, value| value.present? && %i[volume_unit volume_value container_type container_count].include?(key) })
    # Since wine and liquor are primarily sold in single containers we first check for a match here.
    product ||= Product.where('lower(products.name) = ?', String(@data[:name]).downcase)
                       .joins(product_size_grouping: [:hierarchy_category]).where('product_types.name IN (?)', %w[wine liquor])
                       .find_by(volume_unit: @data[:volume][:volume_unit], volume_value: @data[:volume][:volume_value])
    product ||= Product.create(
      name: @data[:name],
      item_volume: @data[:volume][:item_volume],
      volume_unit: @data[:volume][:volume_unit],
      volume_value: @data[:volume][:volume_value],
      container_type: @data[:volume][:container_type],
      container_count: @data[:volume][:container_count],
      prototype: find_prototype
    )
    # If product is created, ProductSizeGrouping is created too at `after_create`
    product = find_not_merged_product(product) if product.state == 'merged'
    product
  end

  def update_product_size_grouping
    return unless @grouping

    @grouping.product_type = find_product_type if @grouping.needs_categorization?
    @grouping.brand        = find_brand        unless @grouping.brand
    # We set initial properties to newly created @grouping. Afterwards, most properties are frozen and we need an option at import.
    @grouping.description = @data[:description] if grouping_should_update? && @grouping.description.blank?
    assign_properties if grouping_should_update?
    @grouping.save! if @grouping.changed?
    update_grouping_image if @grouping.images.empty?
  end

  def update_product
    assign_upc if @data[:upc].present?
    @product.save if @product.changed? # Can fail if UPC is already assigned to another product
    update_image if product_should_update? && @product.images&.empty?
  end

  def update_variant_inventory
    if @variant.inventory
      # Doing updates directly on SQL to avoid triggering a reindex immediately after the update.
      @variant.inventory.update(count_on_hand: @data[:quantity], variant_id: @variant.id)
    else
      @variant.create_inventory(count_on_hand: @data[:quantity], variant_id: @variant.id)
    end
  end

  def update_variant_sale_price
    @variant.sale_price              = 0                     if @data[:price] <= @variant.sale_price
    @variant.sale_price              = @data[:sale_price]    if @data[:sale_price].present? && Float(@data[:sale_price]) < Float(@data[:price])
  end

  def update_variant
    @variant.case_eligible           = @data[:case_eligible] if @data[:case_eligible].present?
    @variant.original_name           = @data[:original_name] if @data[:original_name].present?
    @variant.name                    = @data[:name] if @data[:name].present?
    @variant.original_item_volume    = @data[:original_item_volume] if @data[:original_item_volume].present?
    @variant.original_upc            = @data[:upc] if @data[:upc].present?
    @variant.price                   = @data[:price]
    @variant.original_price          = @data[:original_price] if @data[:original_price].present?
    @variant.external_brand_key      = @data[:brand_key] if @data[:brand_key].present?
    @variant.tax_exempt              = tax_exempt_truthy(@data[:tax_exempt]) if @data[:tax_exempt].present?
    update_variant_sale_price
    has_custom_promo = @data[:custom_promo_type].present? && @data[:custom_promo_amount].present?
    @variant.custom_promo = has_custom_promo ? { type: @data[:custom_promo_type], amount: @data[:custom_promo_amount] } : nil

    update_variant_inventory

    @variant.product = @product
    @variant.deleted_at = Time.zone.now if PreSale.active.exists?(product_id: @variant.product_id)
    @variant.deleted_at = Time.zone.now if Feature[:limited_time_offer_feature].enabled? && @product.limited_time_offer

    if @variant.changed?
      @variant.skip_reindex = true
      @variant.save!

      # Reindexing variants 2 minutes after it is updated to compensate for db replicas sync lag
      VariantReindexWorker.perform_at(2.minutes.from_now, @variant.id)
    elsif @data[:quantity] != @variant.inventory&.count_on_hand
      # Reindexing variants if inventory count_on_hand has changed
      VariantReindexWorker.perform_at(2.minutes.from_now, @variant.id)
    end
  end

  def find_prototype
    prototype   = Prototype.find_by(name: find_category.name)
    prototype ||= Prototype.first
    prototype
  end

  def find_category
    @category   = ProductType.roots.where('lower(name) = ?', String(@data[:category]).downcase).first if @data[:category].present?
    @category ||= ProductType.find_by(name: ProductType::UNIDENTIFIED_TYPE)
    @category
  end

  def find_product_type
    product_type   = ProductType.find_by(permalink: @data[:suggested_category]) if @data[:suggested_category].present?
    product_type ||= find_category.descendants.where('lower(name) = ?', String(@data[:type]).downcase).limit(1).first if @data[:type].present?
    product_type ||= find_category

    if product_type
      if find_category == 'wine'
        subtype   = product_type.descendants.where('lower(name) = ?', String(@data[:varietal]).downcase).limit(1).first
        subtype ||= product_type.descendants.where('lower(name) = ?', String(@data[:subtype]).downcase).limit(1).first
      else
        subtype = product_type.descendants.where('lower(name) = ?', String(@data[:subtype]).downcase).limit(1).first
      end
    end

    product_type ||= subtype
  end

  def find_brand
    brand ||= Brand.where('lower(name) = ?', String(@data[:brand_name]).downcase).first if @data[:brand_name].present?
    brand ||= guess_brand
    brand ||= Brand.find_by(name: 'Unknown Brand')
    brand
  end

  def guess_brand
    name_array = String(@data[:name]).split(' ')

    Brand.find_by("lower(brands.name) = lower(:first) OR lower(brands.name) = lower(:first) || ' ' || lower(:second) OR lower(brands.name) = lower(:first) || ' ' || lower(:second) || ' ' || lower(:third)", first: name_array[0], second: name_array[1], third: name_array[2])
  end

  def assign_properties
    @grouping.set_property('alcohol',     @data[:alcohol])
    @grouping.set_property('appellation', @data[:appellation])
    @grouping.set_property('country',     @data[:country])
    @grouping.set_property('gluten_free', @data[:gluten_free])
    @grouping.set_property('kosher',      @data[:kosher])
    @grouping.set_property('organic',     @data[:organic])
    @grouping.set_property('region',      @data[:region])
    @grouping.set_property('varietal',    @data[:varietal])
    @grouping.set_property('year',        @data[:year])
  end

  def assign_upc
    if !@product.upc
      @product.upc = @data[:upc]
    elsif @product.upc != @data[:upc] && !@product.additional_upcs.include?(@data[:upc])
      upc_product = Product.find_by(upc: @data[:upc])
      # We are setting the upc as additional upc only it is not the main upc on other product
      # or if it is the main upc of a product that was merged into the current product
      if upc_product
        merged = Product.joins(:source_merges).where(id: upc_product.id, product_merges: { destination_id: @product.id }) if upc_product.state == 'merged'
        @product.additional_upcs.push(@data[:upc]) unless merged.nil?
      else
        @product.additional_upcs.push(@data[:upc])
      end
    end
  end

  def update_image
    ImageCreationWorker.perform_async('Product', @product.id, @data[:image_url]) if @data[:image_url].present?
  end

  def update_grouping_image
    ImageCreationWorker.perform_async('ProductSizeGrouping', @grouping.id, @data[:image_url]) if @data[:image_url].present?
  end

  def get_destination_product(product)
    product.source_merges.last&.destination
  end

  def find_not_merged_product(product)
    dest_product = get_destination_product(product)
    return product if dest_product.nil?

    dest_product = find_not_merged_product(dest_product) if dest_product.state == 'merged'
    dest_product
  end

  def product_should_update?
    @options[:update_products] || @product.created_at == @product.updated_at
  end

  def grouping_should_update?
    @options[:update_products] || @grouping.created_at == @grouping.updated_at
  end

  def tax_exempt_truthy(value)
    value == 'TRUE'
  end
end
