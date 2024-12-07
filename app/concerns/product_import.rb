class ProductImportBelowSafetyThreshold < StandardError; end

class ProductImportInconsistentFileSize < StandardError; end

class ProductImport
  include DataCleaner

  attr_accessor :etag, :import_record, :counts

  IMPORT_SAFETY_THRESHOLD = 0.15
  MAX_DELTA_PRODUCT_COUNT = 0.2 # product count from pull to pull decreases by %40

  def initialize(feed, force = false)
    @feed = feed
    @supplier = feed.supplier
    @import_record = @feed.inventory_imports.create(supplier: @supplier)

    @bypass_safety_check = force

    # TODO: Think about a better way to do this and general product type detection
    @liquor_root_id = ProductType.select(:id).root.find_by(name: 'liquor').id
    @wine_root_id = ProductType.select(:id).root.find_by(name: 'wine').id

    @products = load_products

    @updated_variant_ids = []
    @zeroed_variant_ids = []

    @success = false

    @counts = {
      active_variants_at_start: @supplier.variants.active.available.count,
      new_products: 0,
      new_variants: 0,
      total_records: @products.length,
      zeroed_products: 0,
      updated_variants: 0
    }
  end

  def process_feed
    raise ProductImportBelowSafetyThreshold unless safely_updatable? || @bypass_safety_check

    @products.each do |product|
      format_product!(product)
      # TODO: updatable_product? is a more lax version of valid_product, so really we're only checking skus here
      if valid_product?(product) || updatable_product?(product)
        begin
          process_product(product)
        rescue StandardError => e
          notify_sentry_and_log(e, e.message, { tags: { supplier: @supplier.id, feed: @feed.id } })
        end
      else
        # There is not enough data to process the product, skipping.
        @counts[:invalid_records] += 1
      end
    end

    # If the option is set, we will remove all products which have not been updated.
    remove_items_not_present if @feed.remove_items_not_present
  rescue ProductImportBelowSafetyThreshold => e
    notify_below_safety_threshold
  rescue StandardError => e
    notify_sentry_and_log(e, e.message, { tags: { supplier: @supplier.id, feed: @feed.id } })
  ensure
    @success = true
    log_import
  end

  private

  def safely_updatable?
    !(@supplier.active? && @feed.remove_items_not_present && !above_safety_threshold?)
  end

  def above_inventory_threshold?(quantity)
    quantity.to_i > @feed.inventory_threshold
  end

  def find_variant(sku)
    variant = @supplier.variants.self_active.find_by(sku: String(sku))
    variant ||= @supplier.variants.self_inactive.find_by(sku: String(sku))
    variant
  end

  def process_product(product)
    # TODO: We should attempt to update all the product metadata if missing, not just price/qty
    ActiveRecord::Base.transaction do
      # Product is valid, lets continue with the import.

      # Quantity of product exceeds the inventory threshold for the feed, lets proceed with
      # the import.

      # First we check if the variant exists and can be updated. This relies on the assumption
      # that a SKU is unique for a given supplier.

      variant = find_variant(product[:sku])

      if variant.nil? && creatable_product?(product)
        # There is not a variant for the product so we must create a new one. In order to create
        # a product, we need at least a name.

        # First, we look for a product based on UPC code, and if that fails we look for one
        # with the same name and value. Sorry, exact matches only.
        product_to_update = find_product(product)

        if product_to_update.nil?
          product_to_update = do_create product
          new_product_created = product_to_update.present?
          next unless new_product_created
        end

        # We create the variant.
        variant = create_variant(product_to_update, product)
      elsif product[:trusted] && variant.present?
        current_product = variant.product
        valid = current_product[:container_count] == product[:volume][:container_count] &&
                current_product[:container_type] == product[:volume][:container_type] &&
                current_product[:volume_unit] == product[:volume][:volume_unit] &&
                current_product[:volume_value] == product[:volume][:volume_value]
        if current_product.variants.all? { |x| x.sku == product[:sku] }
          update_product(variant.product, product)
        else
          product_to_update = do_create(product) unless valid
          new_product_created = product_to_update.present?
        end

        if new_product_created
          product_to_update.save!
          variant.product.reindex
          variant.product = product_to_update
          variant.save!
        end
      end

      # Ok, Now that the product and variant side of things should be sorted, we can do the
      # fun stuff!
      # []
      # Lets check that we actually have a variant - if it doesn't exist and the product isn't
      # creatable then we can't really update anything now can we?
      unless variant.nil?
        update_variant(variant, product)
        update_product(variant.product, product) unless new_product_created || !@feed.update_products

        if product[:trusted] && !variant.product.active? && !variant.product.ready_for_activation?
          variant.product.upc = nil
          return unless variant.product.save # TODO: check why we get so many `Validation failed: Product size grouping images photo can't be blank`
        end
        variant.product.activate if product[:trusted] && !variant.product.active?

        if bevmo_5_cents_deal?(variant)
          product_size_grouping = variant.product.product_size_grouping
          if product_size_grouping.tag_list.include?('5centdeal')
            product_size_grouping.tag_list.add('5centdeal')
            product_size_grouping.save
          end
        end

        @counts[:updated_variants] += 1
      end
    end
  end

  def do_create(product)
    # We couldn't find a UPC match, so lets continue creating a product.

    # If present, lets retrieve the fields corresponding to ProductType and try and find
    # a suitable place in the taxonomy for this product.
    #
    # NOTE: We are no longer creating a category if it doesn't exist - we should curate
    #       these manually on the backend.
    category = String(product[:category]).downcase

    # If we cannot find a matching category, the product is unidentified.
    product_category = find_product_category(category)

    new_product_type = choose_new_product_type(product, product_category)

    # Lets find a Prototype for the product. We don't necessarily care much about this,
    # but it may come into play later as we add more types of product.
    prototype = find_prototype(product, product_category)

    # We create a brand, or if its not present we declare it unknown.
    # TODO: Do we want to consider a pre-processing step on the "standard" hash which applies cleaners, sets
    # defaults and such?
    brand = Brand.find_or_create_by(name: product[:brand])

    # Now we have everything to create the product.
    product_to_update = create_product(product, prototype)
    return false unless product_to_update

    # Set a flag, we use this later
    new_product_created = true

    # Update Grouping Properties if this is new
    product_to_update.product_size_grouping.update(product_type: new_product_type) if product_to_update.product_type.nil?
    product_to_update.product_size_grouping.update(brand: brand) if product_to_update.product_type.nil?

    # If we have properties, lets set them
    update_product_properties(product_to_update, product)

    if product_to_update.save
      @counts[:new_products] += 1
    else
      Rails.logger.error "Unable to Save Product #{product_to_update}, Error: #{product_to_update.errors.inspect}"
    end
    product_to_update
  end

  def update_product(product, data)
    return unless product

    product.update(name: data[:name])
    if data[:volume].present? && data[:trusted]
      product.update(
        volume_unit: data[:volume][:volume_unit],
        volume_value: data[:volume][:volume_value],
        container_type: data[:volume][:container_type],
        container_count: data[:volume][:container_count]
      )
    end
    product.save!

    update_upc_code(product, data[:upc])

    product_size_grouping = product.product_size_grouping
    if product_size_grouping && data[:trusted]

      product_size_grouping.update(brand: Brand.find_or_create_by(name: data[:brand])) if (product_size_grouping.brand_name == 'Unknown Brand' || product_size_grouping.brand.nil?) && data[:brand].present?
      product_size_grouping.update(description: data[:description]) if product_size_grouping.description.blank? && data[:description].present?

      product_size_grouping.set_property('country', data[:country])
      product_size_grouping.set_property('region', data[:region])
      product_size_grouping.set_property('kosher', data[:kosher])
      product_size_grouping.set_property('gluten_free', data[:gluten_free])
      product_size_grouping.set_property('alcohol', data[:alcohol])

      product_size_grouping.set_image(data[:image_url]) if product_size_grouping.images.empty? && data[:image_url].present?
    end
  end

  # TODO: Make smarter!
  def choose_new_product_type(product, product_category)
    # We'll try and go as deep in the actual tree as we can find items. Its important
    # never to continue going deeper if a previous node cannot be found as some subtypes
    # or varietals may exist for multiple typles
    type = String(product[:type]).downcase
    product_type = product_category.descendants.find_by(name: type)

    # Wines use varietal, everything else uses subtype.
    if product_category == 'wine' && product_type
      varietal = String(product[:varietal]).downcase
      product_varietal = product_type.descendants.find_by(name: varietal)
    elsif product_type
      subtype = String(product[:subtype]).downcase
      product_subtype = product_type.descendants.find_by(name: subtype)
    end

    # Now we pick the new type
    new_product_type = product_category == 'wine' ? product_varietal : product_subtype
    new_product_type || product_type || product_category
  end

  def update_product_properties(product_to_update, product)
    update_product_property(product_to_update, 'alcohol', product[:alcohol])
    update_product_property(product_to_update, 'varietal', product[:varietal])
    update_product_property(product_to_update, 'region', product[:region])
    update_product_property(product_to_update, 'appellation', product[:appellation])
    update_product_property(product_to_update, 'country', product[:country])
    update_product_property(product_to_update, 'kosher', product[:kosher])
    update_product_property(product_to_update, 'year', product[:year])
    update_product_property(product_to_update, 'gluten_free', product[:gluten_free])

    # TODO: Think about how these also apply to the parent PSG...
    ImageCreationWorker.perform_async('Product', product_to_update.id, product[:image_url]) if product[:image_url].present? && (product[:image_url] && product_to_update.images.empty?)
  end

  def notify_below_safety_threshold
    Sentry.capture_message('Import below safety threshold', tags: {
                             supplier: @supplier.id,
                             feed: @feed.id,
                             overlap: @overlap
                           })
  end

  def notify_inconsistent_file_sizes(new_count, previous_count)
    Sentry.capture_message('Successive csv file pulls of different sizes', tags: {
                             supplier: @supplier.id,
                             feed: @feed.id,
                             overlap: @overlap,
                             new_count: new_count,
                             previous_count: previous_count
                           })
  end

  def log_import
    log_attributes = @counts.merge(
      active_variants_at_end: @supplier.variants.active.available.count,
      success: @success
    )
    if (@import_record[:total_records]).zero?
      log_attributes[:success] = false
      log_attributes[:has_changed] = false
    end
    @import_record.finish_import(log_attributes)
    InventoryImport.pending.where(data_feed: @feed).delete_all
    @supplier.inventory_updated!
  end

  def remove_items_not_present
    untouched_variants = @supplier.variants
                                  .self_active
                                  .where(protected: false)
                                  .where
                                  .not(id: @updated_variant_ids)

    untouched_variants.find_each do |variant|
      next unless variant&.count_on_hand&.positive?

      variant.inventory.update(count_on_hand: 0)

      @zeroed_variant_ids.push(variant.id)
      @counts[:zeroed_products] += 1
    end
  end

  def filter_products(products)
    # TODO: Can we remove the Square Update case?
    # We need to handle SQUARE_UPDATE as a special case as they only expose SKU and QTY
    products.select do |product|
      (product[:name].present? && (product[:price].present? && product[:sku].present?)) || @feed.mode == 'SQUARE_UPDATE'
    end
  end

  def update_upc_code(product, upc)
    return if upc.blank?

    cleaned_upc = DataCleaners::Parser::Upc.parse(upc)

    return if cleaned_upc.blank? || cleaned_upc == product.upc || product.additional_upcs.include?(cleaned_upc)

    if product.upc.present?
      product.additional_upcs += [cleaned_upc]
    else
      product.upc = cleaned_upc
    end

    Rails.logger.warn 'UPC already exists' unless product.save
  end

  def find_product_category(category)
    ProductType.find_by(name: category) || ProductType.find_by(name: ProductType::UNIDENTIFIED_TYPE)
  end

  def above_safety_threshold?
    variants = @supplier.variants.active.where(sku: @products.collect { |p| p[:sku] }).size
    @overlap = (1.0 / @supplier.variants.active.available.size) * variants
    @overlap > IMPORT_SAFETY_THRESHOLD
  end

  def find_prototype(_product, product_category)
    prototype = Prototype.find_by(name: product_category.name)
    prototype ||= Prototype.first
    prototype
  end

  def find_product(product)
    new_product = DataCleaners::Parser::Upc.parse(product[:upc]).nil? ? nil : find_upc_match(product[:upc])
    new_product ||= Product.where.not(state: 'merged').find_by(
      name: product[:name],
      item_volume: product[:volume][:item_volume]
    )
    if product[:trusted] && new_product.present? && (
      new_product.state != 'active' ||
        new_product.volume_unit != product[:volume][:volume_unit] ||
        new_product.volume_value != product[:volume][:volume_value] ||
        new_product.container_count != product[:volume][:container_count] ||
        new_product.container_type != product[:volume][:container_type])
      new_product = nil
    end
    new_product
  end

  def create_product(product, prototype)
    # Doing a fairly simple search here - ignoring container type/count since this is missing for a lot
    # of non-beer products.
    new_product = Product.active_or_pending
                         .joins(:product_size_grouping)
                         .where('product_groupings.hierarchy_category_id = ?', @wine_root_id)
                         .find_by(
                           name: product[:name],
                           volume_unit: product[:volume][:volume_unit],
                           volume_value: product[:volume][:volume_value]
                         )

    new_product ||= Product.active_or_pending
                           .joins(:product_size_grouping)
                           .where('product_groupings.hierarchy_category_id = ?', @liquor_root_id)
                           .find_by(
                             name: product[:name],
                             volume_unit: product[:volume][:volume_unit],
                             volume_value: product[:volume][:volume_value]
                           )

    new_product ||= Product.active_or_pending.find_by(
      name: product[:name],
      volume_unit: product[:volume][:volume_unit],
      volume_value: product[:volume][:volume_value],
      container_type: product[:volume][:container_type],
      container_count: product[:volume][:container_count]
    )

    return new_product if new_product

    new_product = Product.new(
      name: product[:name],
      item_volume: product[:volume][:item_volume],
      volume_unit: product[:volume][:volume_unit],
      volume_value: product[:volume][:volume_value],
      container_type: product[:volume][:container_type],
      container_count: product[:volume][:container_count],
      prototype: prototype
    )
    new_product.save
    new_product
  end

  def create_variant(product_to_update, product)
    variant = Variant.new(
      product: product_to_update,
      supplier: @supplier,
      sku: product[:sku],
      deleted_at: nil,
      price: product[:price],
      sale_price: product[:sale_price],
      case_eligible: product[:case_eligible],
      name: product_to_update.name,
      original_name: product[:original_name],
      original_item_volume: product[:volume][:item_volume]
    )

    if variant.save
      @counts[:new_variants] += 1

      variant
    else
      Rails.logger.error("Unable to create variant: #{variant.errors.inspect} #{product.inspect}")
      nil
    end
  end

  def update_variant(variant, product)
    variant.inventory.count_on_hand = above_inventory_threshold?(product[:quantity]) ? product[:quantity].to_i : 0
    variant.price = product[:price] if product[:price].present?
    variant.sale_price = product[:sale_price] if product[:sale_price].present?
    variant.original_name = product[:original_name] if product[:original_name].present?
    variant.case_eligible = product[:case_eligible] if product[:case_eligible].present?
    variant.ca_crv = product[:ca_crv] if product[:ca_crv].present?
    variant.two_for_one = product[:two_for_one] if product[:two_for_one].present?

    if variant.ca_crv && !variant.supplier.custom_ca_crv
      variant.supplier.custom_ca_crv = true
      variant.supplier.custom_ca_crv.save!
    end

    if variant.save
      @updated_variant_ids.push(variant.id)
    else
      Rails.logger.error("Unable to save variant: #{variant.errors.inspect} #{product.inspect}")
    end
  end

  def bevmo_5_cents_deal?(variant)
    variant.two_for_one_visible? &&
      variant.two_for_one.to_f == 0.05 &&
      (variant.supplier.name =~ /^BevMo/i).zero?
  end

  def update_product_property(product, property_name, value)
    product.update_property(property_name, value)
  end

  def valid_product?(product)
    product[:sku].present? && product[:quantity].present? && (product[:price].present? ? product[:price].to_f >= 0.01 : true)
  end

  def updatable_product?(product)
    product[:sku].present?
  end

  def creatable_product?(product)
    product[:name].present?
  end

  def find_upc_match(upc)
    states = @feed.active_only ? ['active'] : %w[active pending flagged]
    product = Product.where(state: states).find_by(upc: DataCleaners::Parser::Upc.parse(upc))
    product ||= Product.where(state: states).find_by('additional_upcs @> ?', "{#{upc}}")
    product
  end

  def translate_parser_name(to_translate)
    String(to_translate).titleize.delete(' ')
  end

  def load_products
    options = @feed.url
    options = { url: @feed.url, prices_url: @feed.prices_url, store_number: @feed.store_number } if @feed.store_number.present?
    products = "Parsers::#{translate_parser_name(@feed.mode)}".constantize.new(options).products
    if @feed.last_pull_count && @feed.remove_items_not_present && @feed.mode == 'MPOWER'
      delta_product_count = (@feed.last_pull_count - products.size) / @feed.last_pull_count.to_f
      raise ProductImportInconsistentFileSize if delta_product_count > MAX_DELTA_PRODUCT_COUNT
    end
    @feed.update(last_pull_count: products.size)

    @etag = calculate_md5(products)

    # Logging the pre-filtered products to S3 for future audits.
    # TODO: Clean up S3 code - this is shared with a few other components.
    save_to_s3(products)

    filter_products(products)
  rescue ProductImportInconsistentFileSize => e
    notify_inconsistent_file_sizes(products.size, @feed.last_pull_count)
  end

  def format_product!(product)
    product[:brand] = product[:brand].presence || 'Unknown Brand'
    product[:country] = DataCleaners::Cleaner::Country.clean(product[:country])
    product[:volume][:volume_value] = float_of(product[:volume][:volume_value]) if product[:volume]
    product[:volume][:container_count] = integer_of(product[:volume][:container_count]) if product[:volume]
    product[:sale_price] = float_of(product[:sale_price]) || 0
    product[:case_eligible] = product[:case_eligible].presence || false
  end

  def float_of(string)
    Float(string)
  rescue ArgumentError, TypeError
    nil
  end

  def integer_of(string)
    # Convert to Float first to support integers in decimal notation
    float = float_of(string)
    float&.to_i
  end

  def save_to_s3(products)
    require 'aws-sdk'

    unless ENV['AWS_INVENTORY_BUCKET'].nil?
      file_name = "#{@supplier.id}-#{Time.zone.now.strftime('%F-%H%M')}-#{@etag}.json"
      local_file_path = "./tmp/#{file_name}"

      File.open(local_file_path, 'w') do |file|
        file.write(products.to_json)
      end

      object = bucket.object("imports/#{@supplier.id}_#{@supplier.name.parameterize}/#{file_name}")
      object.upload_file(Pathname.new(local_file_path))
      File.delete(local_file_path)
    end
  end

  def s3
    Aws::S3::Resource.new(region: ENV['AWS_REGION'])
  end

  def bucket
    s3.bucket(ENV['AWS_INVENTORY_BUCKET'])
  end

  def calculate_md5(to_calc)
    Digest::MD5.hexdigest(String(to_calc))
  end
end
