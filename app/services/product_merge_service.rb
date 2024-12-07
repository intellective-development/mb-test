class ProductMergeService
  attr_reader :source, :destination

  POINT_AWARD = 10

  DEFAULT_OPTIONS = {
    activate: false,
    award_points: true,
    merge_properties: true,
    merge_volume: true,
    replace_name: false,
    replace_description: false,
    replace_image: false,
    replace_category: false,
    remove_upc: false,
    update_permalinks: true,
    update_tax_category: true,
    validate_mergeable: true
  }.freeze

  PRODUCT_ATTRIBUTES = %w[name upc product_type_id tax_category_id volume_value volume_unit container_type container_count state].freeze

  # TODO: Remove duplicate variants option!

  def initialize(source_product_id, destination_product_id, options = {}, user_id = nil)
    @options = DEFAULT_OPTIONS.merge(options.symbolize_keys)

    @source = Product.find_by(id: source_product_id)
    @destination = Product.find_by(id: destination_product_id)
    @user = User.find_by(id: user_id)

    @should_activate = @options[:activate] || (@source&.state == 'active' && @destination&.state != 'active')

    raise MergeError::NoPossibleMergeError.new(source_product_id, false), "Source Product #{source_product_id || 'nil'} not found." if @source.nil?
    raise MergeError::NoPossibleMergeError.new(destination_product_id, true), "Destination Product #{destination_product_id || 'nil'} not found." if @destination.nil?
    raise MergeError::NoPossibleMergeError.new(source_product_id, false), 'Cannot merge product into itself.' if @source.id == @destination.id
    raise MergeError::NoPossibleMergeError.new(destination_product_id, true), 'Cannot merge master product with pending product.' if @source.master? && @destination.pending?

    @total_points = POINT_AWARD * @source.variants.self_active.size
  end

  def merge!
    validate_products_mergeable if @options[:validate_mergeable]

    log_merge

    update_attribute(:name)                     if @options[:replace_name]
    update_grouping_attribute(:name)            if @options[:replace_name]
    update_grouping_attribute(:description)     if @options[:replace_description]
    update_images                               if @options[:replace_image]
    update_grouping_attribute(:product_type_id) if @options[:replace_category]
    update_upc
    update_tax_category                         if @options[:update_tax_category]
    update_permalinks                           if @options[:update_permalinks]
    merge_volume                                if @options[:merge_volume]
    merge_properties                            if @options[:merge_properties]

    copy_variants

    award_points if @user && @options[:award_points]

    @source.merge!
    @destination.activate! if @should_activate
  end

  def validate_products_mergeable
    raise 'One or more of these products have already been merged or are otherwise inactive and cannot be merged at this time.' unless @source.mergeable? && @destination.mergeable?
  end

  private

  def log_merge
    ProductMerge.create(
      destination: @destination,
      source: @source,
      user: @user,
      options: @options,
      original_attributes: @destination.attributes.select { |k, _v| PRODUCT_ATTRIBUTES.include?(k) },
      source_children: @source.variants.pluck(:id)
    )

    Product.first.attributes.map { |hash| hash.select { |k, _v| [:name].include? k } }
  end

  def award_points
    Count.increment("hunger_games##{@user.id}", @total_points)
  end

  def update_permalinks
    FriendlyId::Slug.where(sluggable_type: 'Product', sluggable_id: @source.id).each do |slug|
      slug.sluggable_id = @destination.id
      slug.save
    end
  end

  def update_tax_category
    # Only update tax category if one has not been set
    update_attribute(:tax_category_id) if no_tax_category?
  end

  def no_tax_category?
    # Currently we assume that a nil category is the default rate for alcohol.
    @destination.tax_category_id.nil?
  end

  def merge_properties
    # Simple product merge, we don't overrite existing properties.
    @source.product_properties.each do |product_property|
      existing_property = @destination.product_properties.find_by(property_id: product_property.property_id)

      product_property.update(product_id: @destination.id) if existing_property.nil? && product_property.description.present? && !ProductProperty::DESCRIPTION_BLACKLIST.include?(String(product_property.description).downcase)
    end
  end

  def update_upc
    if @options[:remove_upc]
      @destination.update(upc: nil)
    elsif @source.upc.present?
      # Need to remove UPC from source prior to update to avoid any uniqueness validation errors.
      upc = @source.upc
      @source.update(upc: nil)

      update_attribute(:upc, upc)
    end
  end

  def merge_volume
    @destination.volume_unit     = @source.volume_unit     if @destination.volume_unit.blank?
    @destination.volume_value    = @source.volume_value    if @destination.volume_value.blank?
    @destination.container_count = @source.container_count if @destination.container_count.blank?
    @destination.container_type  = @source.container_type  if @destination.container_type.blank?
    @destination.save
  end

  def update_images
    @destination.images.map(&:delete)
    @source.images.each do |image|
      image.imageable_id = @destination.id
      image.save
    end
  end

  def update_attribute(attribute, value = false)
    @destination.update_attribute(attribute, value || @source.attributes[attribute.to_s])
  end

  def update_grouping_attribute(attribute, value = false)
    @destination.product_size_grouping.update_attribute(attribute, value || @source.product_size_grouping.attributes[attribute.to_s])
  end

  def copy_variants
    @source.variants.each do |variant|
      variant.product = @destination

      # We are saving without validation here to prevent the merge failing if
      # an active variant with the same SKU (and the same supplier) exists on
      # the destination product - normally this would cause model validations
      # to fail.
      #
      # We could check here, however this gets somewhat complex and also has
      # implications if we want to undo the merge as we also need to track any
      # changes we might make to variants.
      #
      # In terms of dealing with these invalid variants, we'll use a combination
      # of API code to suppress multiple variants being returned for the same product
      # and cleanup scripts aimed at identifying and fixing these (hopefully diminishing)
      # set of cases.
      Rails.logger.error("Error: Unable to move variant #{variant.id} to product #{@destination.id}: #{variant.errors.inspect}") unless variant.save(validate: false)
    end
  end
end
