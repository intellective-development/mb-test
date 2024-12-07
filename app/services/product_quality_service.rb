class ProductQualityService
  attr_accessor :product, :grouping

  # TODO: multibyte chars break ruby regex, figure out how to test for them
  WEIRD_CHAR_TEST = Regexp.new('[&\+=\\/\.\$%\(\)!\-:#“”\?,\*\|©ª@‰№;√\[\]™±¾‘"馘�]+')
  DIACRITIC_CHAR_TEST = Regexp.new('[âüéóñôèëçäêúöîàáÁÜòãõûìïā¡ÇÀÚėùØšč]+')
  TOO_MANY_NUMBERS_TEST = Regexp.new('\d{5,}') # 5 or more numbers in a row

  # TODO: consider accepting product_id as param?
  def initialize(product_id, options = {})
    default_options = {
      safe_mode: true,
      verbose: false
    }
    @options = default_options.merge(options)
    @product = Product.includes(:product_size_grouping).find(product_id)
    raise 'Product does not exist' if @product.nil?

    @grouping = product.product_size_grouping
  end

  def process!
    ActiveRecord::Base.transaction do
      auto_activation_prerequisite_checks = { has_categorization: categorized?, has_volume: full_volume?, clean_name: well_formed_name? }

      # NOTE: the below checks will provide a guide for further product quality cleaning services
      # through a ProductQualityMetadata model
      #
      # general_quality_checks = {
      #   has_image: has_product_or_grouping_image,
      #   clean_description: has_well_formed_description,
      #   clean_categorization: is_properly_categorized,
      #   clean_volume: has_proper_volume_attributes,
      #   has_properties: has_basic_properties,
      # }
      # @product.quality_metadata.update(auto_activation_prerequisite_checks.merge(general_quality_checks))
      activatable = false
      not_active = @product.inactive? || @product.pending? || @product.flagged?
      if not_active && auto_activation_prerequisite_checks.values.all? && @product.ready_for_activation?
        activatable = true
        ProductActivationWorker.perform_async(@product.id) unless @options[:safe_mode]
      end
      check_map = Hash[auto_activation_prerequisite_checks]
      log_results(check_map, activatable)
      activatable
    end
  end

  private

  ####################
  ## Helper Methods ##
  ####################

  def log_results(check_map, activatable)
    base_info = { name: @grouping.name, state: @product.state, p_id: @product.id, g_id: @grouping.id }
    message = 'Not Activatable'
    message = (@options[:safe_mode] ? 'Activatable' : 'Activated') if activatable
    prefix = activatable ? '💰' : '🛁'
    full = @options[:verbose] ? "#{prefix} #{base_info.merge(check_map).to_json} #{message}" : "#{prefix} #{base_info.to_json} #{message}"
    Rails.logger.info(full)
  end

  ####################
  ## Quality Checks ##
  ####################
  # NOTE: these should all return true or false, not just truthy or falsey values

  def categorized?
    !(@grouping.hierarchy_category && @grouping.hierarchy_type).nil?
  end

  # TODO: uniq part?
  def full_volume?
    !(@product.container_type &&
      @product.container_count &&
      @product.volume_unit &&
      @product.volume_value).nil?
  end

  def well_formed_name?
    return false if @grouping.name =~ WEIRD_CHAR_TEST # has weird chars
    return false if @grouping.name =~ TOO_MANY_NUMBERS_TEST # too many numbers in a row

    diacritics_removed = @grouping.name.sub(DIACRITIC_CHAR_TEST, '')
    # has non-diacritic multi byte characters
    return false if diacritics_removed.length != diacritics_removed.bytes.length

    # NOTE: for now just toss anything suspicious into a check quality pile
    true
  end
end
