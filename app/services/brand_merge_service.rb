class BrandMergeService
  attr_reader :source, :destination

  POINT_AWARD = 10

  DEFAULT_OPTIONS = {
    award_points: true,
    replace_name: false,
    replace_description: false,
    update_permalinks: true,
    validate_mergeable: true
  }.freeze

  PRODUCT_ATTRIBUTES = %w[name permalink state].freeze

  def initialize(source_brand_id, destination_brand_id, options = {}, user_id = nil)
    @options = DEFAULT_OPTIONS.merge(options.symbolize_keys)

    @source = Brand.find_by(id: source_brand_id)
    @destination = Brand.find_by(id: destination_brand_id)
    @user = User.find_by(id: user_id)
    raise MergeError::NoPossibleMergeError.new(source_brand_id, false), "Source Brand #{source_brand_id || 'nil'} not found." if @source.nil?
    raise MergeError::NoPossibleMergeError.new(destination_brand_id, true), "Destination Brand #{destination_brand_id || 'nil'} not found." if @destination.nil?
    raise MergeError::NoPossibleMergeError.new(source_brand_id, false), 'Cannot merge brand into itself.' if @source.id == @destination.id

    @total_points = POINT_AWARD * @source.products.size
  end

  def merge!
    log_merge

    move_groupings
    move_sub_brands

    update_attribute(:name)                     if @options[:replace_name]
    update_attribute(:description)              if @options[:replace_description]
    update_permalinks                           if @options[:update_permalinks]

    award_points if @user && @options[:award_points]

    @source.merge!
  end

  private

  def log_merge
    BrandMerge.create(
      destination: @destination,
      source: @source,
      user: @user,
      options: @options,
      original_attributes: @destination.attributes.select { |k, _v| PRODUCT_ATTRIBUTES.include?(k) },
      source_subbrands: @source.sub_brands.pluck(:id),
      source_groupings: @source.product_size_groupings.pluck(:id)
    )

    Brand.first.attributes.map { |hash| hash.select { |k, _v| [:name].include? k } }
  end

  def award_points
    Count.increment("hunger_games##{@user.id}", @total_points)
  end

  def update_permalinks
    FriendlyId::Slug.where(sluggable_type: 'Brand', sluggable_id: @source.id).each do |slug|
      slug.sluggable_id = @destination.id
      slug.save
    end
  end

  def update_attribute(attribute, value = false)
    @destination.update_attribute(attribute, value || @source.attributes[attribute.to_s])
  end

  def move_groupings
    @source.product_size_groupings.each do |product_grouping|
      product_grouping.update(brand: @destination)

      Rails.logger.error("Error: Unable to move grouping #{product_grouping.id} to brand #{@destination.id}: #{product_grouping.errors.inspect}") unless product_grouping.save
      product_grouping.reload
      source.reload
    end

    raise 'Some product groupings in the source brand were not moved over.' unless @source.product_size_groupings.empty?
  end

  def move_sub_brands
    @source.sub_brands.each do |sub_brand|
      sub_brand.update(parent_brand: @destination)

      Rails.logger.error("Error: Unable to move brand #{sub_brand.id} to new parent brand #{@destination.id}: #{sub_brand.errors.inspect}") unless sub_brand.save
      sub_brand.reload
      source.reload
    end

    raise 'Some sub brands in the source brand were not moved over.' unless @source.sub_brands.empty?
  end
end
