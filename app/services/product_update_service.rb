class ProductUpdateService
  POINT_MULTIPLIER = 1

  # TODO: Alert on Col not found!
  COL_ID          = :id
  COL_STATE       = :state
  COL_TO_DELETE   = :to_delete
  COL_TO_MERGE    = :to_merge_with
  COL_TO_ACTIVATE = :to_activate
  COL_NAME        = :name
  COL_VOLUME_VAL  = :volume_val
  COL_VOLUME_UNIT = :volume_unit
  COL_CONT_COUNT  = :container_count
  COL_CONT_TYPE   = :container_type
  COL_PROD_TYPE   = :product_type_id
  COL_BRAND_NAME  = :brand_name
  COL_DESCRIPTION = :description
  COL_ABV         = :abv
  COL_COUNTRY     = :country
  COL_REGION      = :region
  COL_IMAGE       = :image_url

  MERGE_OPTIONS = {}.freeze

  SMARTER_CSV_OPTIONS = {
    convert_values_to_numeric: { only: %i[id product_type_id to_merge volume_value container_count] }
  }.freeze

  def initialize(url, user_id = nil)
    @url = url
    @point_count = 0
    @user_id = user_id
    @updated_product_ids = []

    raise 'URL is required' if @url.nil?

    uri = URI.parse(url)
    @csv = SmarterCSV.process(uri.open('r:iso-8859-1'), SMARTER_CSV_OPTIONS)
  end

  def process!
    @csv.each do |row|
      product_id = row[COL_ID]
      @current_product = Product.find_by(id: product_id)
      @current_brand = Brand.find_or_create_by(name: row[COL_BRAND_NAME])
      @current_product_type = ProductType.find_by(id: row[COL_PROD_TYPE])

      next unless @current_product

      if row[COL_TO_DELETE] == '1'
        delete_product(product_id)
      else
        update_attribute(:name, DataCleaners::Cleaner::Name.clean(row[COL_NAME])) if @current_product.name != DataCleaners::Cleaner::Name.clean(row[COL_NAME])
        update_grouping_attribute(:name, DataCleaners::Cleaner::Name.clean(row[COL_NAME])) if @current_product.name != DataCleaners::Cleaner::Name.clean(row[COL_NAME])
        update_grouping_attribute(:name, DataCleaners::Cleaner::Name.clean(row[COL_NAME])) if @current_product.name != DataCleaners::Cleaner::Name.clean(row[COL_NAME])
        update_grouping_attribute(:product_type, @current_product_type, false)  if @current_product.product_type&.id != @current_product_type&.id
        update_grouping_attribute(:brand, @current_brand, false)                if @current_product.brand&.id != @current_brand&.id
        update_grouping_attribute(:description, row[COL_DESCRIPTION])    if @current_product.description != row[COL_DESCRIPTION] && !row[COL_DESCRIPTION].nil?
        update_attribute(:volume_value, row[COL_VOLUME_VAL].to_f)     if @current_product.volume_value != row[COL_VOLUME_VAL].to_f && !row[COL_VOLUME_VAL].nil?
        update_attribute(:volume_unit, row[COL_VOLUME_UNIT])          if @current_product.volume_unit != row[COL_VOLUME_UNIT] && !row[COL_VOLUME_UNIT].nil?
        update_attribute(:container_count, row[COL_CONT_COUNT].to_i)  if @current_product.container_count != row[COL_CONT_COUNT].to_i && !row[COL_CONT_COUNT].nil?
        update_attribute(:container_type, row[COL_CONT_TYPE])         if @current_product.container_type != row[COL_CONT_TYPE] && !row[COL_CONT_TYPE].nil?

        update_property('alcohol', row[COL_ABV])      unless row[COL_ABV].nil?
        update_property('region', row[COL_REGION])    unless row[COL_REGION].nil?
        update_property('country', row[COL_COUNTRY])  unless row[COL_COUNTRY].nil?
        update_image(row[COL_IMAGE])                  unless row[COL_IMAGE].nil?

        save_product

        merge_product(product_id, row[COL_TO_MERGE]) unless row[COL_TO_MERGE].nil?
        activate_product(product_id)                 if row[COL_TO_ACTIVATE] == '1'
      end
    end

    award_points unless @user_id.nil?
  end

  private

  def log(message)
    Rails.logger.info(message)
  end

  def award_points
    log("Awarding #{@point_count * POINT_MULTIPLIER} points.")
    Count.increment("hunger_games##{@user_id}", @point_count * POINT_MULTIPLIER)
  end

  def save_product
    if @current_product.save
      log("Saved #{@current_product.name}!")
    else
      @current_product.upc = nil
      if @current_product.save
        log("Saved #{@current_product.name}!")
      else
        log("Unable to save #{@current_product.name}")
        log(@current_product.errors.messages.inspect)
      end
    end
  end

  def update_image(url)
    @current_product.images.delete_all
    @current_product.images.create(photo_from_link: url)
  end

  def update_attribute(attribute, value, fix_encoding = true)
    value = DataCleaners::Cleaner::Name.fix_encoding(value) if fix_encoding
    @current_product.update_attribute(attribute, value)
    log("Updated #{@current_product.name} '#{attribute}' to '#{value}'")
    @point_count += 1
  end

  def update_grouping_attribute(attribute, value, fix_encoding = true)
    return unless @current_product.product_size_grouping

    value = DataCleaners::Cleaner::Name.fix_encoding(value) if fix_encoding
    @current_product.product_size_grouping.update_attribute(attribute, value)
    log("Updated #{@current_product.name} Grouping '#{attribute}' to '#{value}'")
    @point_count += 1
  end

  def update_property(name, value, fix_encoding = true)
    return unless @current_product.product_size_grouping

    value = DataCleaners::Cleaner::Name.fix_encoding(value) if fix_encoding
    unless @current_product.product_size_grouping.get_property(name) == value
      @current_product.product_size_grouping.set_property(name, value)
      @updated_product_ids << @current_product.id
      log("Updated #{@current_product.name} Property #{name}: '#{value}'")
      @point_count += 1
    end
  end

  def activate_product(id)
    log("Activating #{@current_product.name}")
    product = Product.active.find_by(id: id)
    product.activate! if product && product.state != 'active'
  end

  def delete_product(id)
    product = Product.active.find_by(id: id)
    if product
      product.deactivate!
      log "Deactivated Product ID #{id}"
      @point_count += 1
    end
  end

  def merge_product(source_product_id, destination_product_id)
    merge_service = begin
      ProductMergeService.new(source_product_id, destination_product_id, MERGE_OPTIONS, @user_id)
    rescue StandardError
      nil
    end
    begin
      merge_service.merge!
    rescue StandardError
      nil
    end
  end
end
