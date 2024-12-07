class ProductGroupingMergeService
  attr_reader :source, :destination

  POINT_AWARD = 10

  DEFAULT_OPTIONS = {
    activate: false,
    award_points: true,
    merge_properties: true,
    replace_name: false,
    replace_description: false,
    replace_image: false,
    replace_category: false,
    update_permalinks: true,
    validate_mergeable: true
  }.freeze

  PRODUCT_GROUPING_ATTRIBUTES = %w[name description product_type_id state].freeze

  # TODO: Remove duplicate variants option! (remnant from product_merge_service.rb)

  def initialize(source_grouping_id, destination_grouping_id, options = {}, user_id = nil)
    @options = DEFAULT_OPTIONS.merge(options.symbolize_keys)

    @source = ProductSizeGrouping.active.find_by(id: source_grouping_id)
    @destination = ProductSizeGrouping.active.find_by(id: destination_grouping_id)
    @user = User.find_by(id: user_id)

    raise MergeError::NoPossibleMergeError.new(source_grouping_id, false), "Source Product Grouping #{source_grouping_id || 'nil'} not found." if @source.nil?
    raise MergeError::NoPossibleMergeError.new(destination_grouping_id, true), "Destination Product Grouping #{destination_grouping_id || 'nil'} not found." if @destination.nil?
    raise MergeError::NoPossibleMergeError.new(source_grouping_id, false), 'Cannot merge product grouping into itself.' if @source.id == @destination.id
    raise MergeError::NoPossibleMergeError.new(destination_grouping_id, true), 'Cannot merge master product grouping with pending product grouping.' if @source.master? && @destination.products.pending.present?

    @total_points = POINT_AWARD * @source.products.size
  end

  def merge!
    # call validation unless flag for skip validation is set on call, should throw RuntimeError and abort merge if fails validation
    validate_product_groupings_mergeable if @options[:validate_mergeable]

    log_merge

    copy_products

    update_attribute(:name)            if @options[:replace_name]
    update_attribute(:description)     if @options[:replace_description]
    update_images                      if @options[:replace_image]
    update_attribute(:product_type_id) if @options[:replace_category]

    update_permalinks                  if @options[:update_permalinks]

    merge_properties                   if @options[:merge_properties]

    copy_tags

    award_points if @user && @options[:award_points]

    @source.merge
    @destination.activate if @options[:activate]
  end

  def validate_product_groupings_mergeable
    raise 'One or more of these product groupings have already been merged or are otherwise inactive and cannot be merged at this time.' unless @source.mergeable? && @destination.mergeable?

    # check against current products for uniqueness of [Vol unit, Vol num, container, count]
    products_need_merging = []

    @source.products.active_or_pending.each do |source_product|
      product_match = check_product_for_match(source_product)
      products_need_merging << product_match if product_match
    end

    raise MergeError::ProductsNeedMergingError.new(products_need_merging), 'There are some products in the grouping that need merging.' if products_need_merging.any?
  end

  private

  def log_merge
    ProductMerge.create(
      destination: @destination,
      source: @source,
      user: @user,
      options: @options,
      original_attributes: @destination.attributes.select { |k, _v| PRODUCT_GROUPING_ATTRIBUTES.include?(k) },
      source_children: @source.products.pluck(:id)
    )

    # vestigial portion from product_merge_service
    # ProductSizeGrouping.first.attributes.map { |hash| hash.select { |k, v| [:name].include? k } }
  end

  def award_points
    Count.increment("hunger_games##{@user.id}", @total_points)
  end

  def update_permalinks
    FriendlyId::Slug.where(sluggable_type: 'ProductSizeGrouping', sluggable_id: @source.id).each do |slug|
      slug.sluggable_id = @destination.id
      slug.save
    end
  end

  def merge_properties
    # Simple product merge, we don't overwrite existing properties.
    @source.product_properties.each do |product_property|
      existing_property = @destination.product_properties.find_by(property_id: product_property.property_id)

      product_property.update(product_id: @destination.id) if existing_property.nil?
    end
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

  def copy_products
    @source.products.each do |product|
      product.update(product_size_grouping: @destination)

      Rails.logger.error("Error: Unable to move product #{product.id} to grouping #{@destination.id}: #{product.errors.inspect}") unless product.save
      product.reload
      source.reload
    end

    raise 'Some products in the source grouping were not copied over.' unless @source.products.empty?
  end

  def copy_tags
    @source.tag_list.each do |tag|
      @destination.tag_list.add(tag)
    end
  end

  def check_product_for_match(source_product)
    matched_product = @destination.products.active_or_pending.find do |destination_product|
      destination_product.volume_unit == source_product.volume_unit &&
        destination_product.volume_value == source_product.volume_value &&
        destination_product.container_type == source_product.container_type &&
        destination_product.container_count == source_product.container_count
    end

    if matched_product
      {
        destination:
          { name: matched_product.name, id: matched_product.id },
        source:
          { name: source_product.name, id: source_product.id },
        volume: matched_product.item_volume
      }
    end
  end
end
