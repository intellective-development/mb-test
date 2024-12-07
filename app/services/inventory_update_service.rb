class InventoryUpdateService
  attr_accessor :supplier, :file_url, :options, :products, :sku_list

  def initialize(params)
    Rails.logger.info("Updating inventory: #{params}")
    @supplier = Supplier.find_by(id: params['supplier_id'])
    @options  = params['options']&.with_indifferent_access
    @file_url = params['file_url']

    raise 'Invalid Supplier ID' if @supplier.nil?
    raise 'Invalid File URL'    if (@file_url =~ /\A#{URI::DEFAULT_PARSER.make_regexp(%w[http https])}\z/).nil?
  end

  def process!
    load_data
    ActiveRecord::Base.transaction do
      check_and_update_sale_hours if @supplier.dashboard_type == Supplier::DashboardType::SEVEN_ELEVEN

      replace_inventory if options[:replace_inventory]
      create_product_update_jobs
      remove_items_not_present if options[:remove_items_not_present]
      update_supplier
    end
  end

  private

  # TODO: Consider https://github.com/dgraham/json-stream or https://github.com/brianmario/yajl-ruby to improve performance when loading large JSON files.
  def load_data
    uri = URI.parse(file_url)
    @products = JSON.parse(uri.open.read)
    @sku_list = []
    @sale_hours = []
    @products.each do |p|
      @sku_list << p['sku']
      @sale_hours += JSON.parse(p['sale_hours']) if p['sale_hours'].present?
    end
  end

  def replace_inventory
    # UPDATE "variants" SET deleted_at = :time, sku = sku || '-old' WHERE "variants"."supplier_id" = $1 AND "variants"."deleted_at" IS NULL AND ("variants"."frozen_inventory" = 'f' OR "variants"."frozen_inventory" IS NULL)  [["supplier_id", :supplier_id]]
    variants = supplier.variants.where(deleted_at: nil, frozen_inventory: [nil, false])
    sql_fragment = Supplier.send(:sanitize_sql_for_assignment, ["deleted_at = :time, sku = sku || '-old'", { time: Time.zone.now }])
    variants.update_all(sql_fragment)

    # We need to reindex the variants which we have just deleted in order to
    # remove them from our indices.
    # we are delaying the execution a bit because the query might take sometime to finish.
    VariantRecentlyDeletedReindexWorker.perform_at(2.minutes.from_now, supplier.id)
  end

  def remove_items_not_present
    # UPDATE "variants" SET "updated_at" = :time WHERE "variants"."supplier_id" = $1 AND "variants"."deleted_at" IS NULL AND ("variants"."protected" = 'f' OR "variants"."protected" IS NULL) AND ("variants"."sku" NOT IN (:sku_list))  [["supplier_id", :supplier_id]]
    variants = supplier.variants.where(deleted_at: nil, protected: [nil, false]).where.not(sku: sku_list)
    variants.update_all(updated_at: Time.zone.now)

    # UPDATE "inventories" SET "count_on_hand" = 0 WHERE "inventories"."id" IN (SELECT "variants"."inventory_id" FROM "variants" WHERE "variants"."supplier_id" = $1 AND "variants"."deleted_at" IS NULL AND ("variants"."protected" = 'f' OR "variants"."protected" IS NULL) AND ("variants"."sku" NOT IN (:sku_list)) AND ("variants"."frozen_inventory" = 'f' OR "variants"."frozen_inventory" IS NULL))  [["supplier_id", :supplier_id]]
    inventories = Inventory.where(id: variants.where(frozen_inventory: [nil, false]).select(:inventory_id))
    inventories.update_all(count_on_hand: 0)

    # We need to reindex the variants which we have just updated in order to reindex them.
    # we are delaying the execution a bit because the query might take sometime to finish.
    VariantNotPresentReindexWorker.perform_at(2.minutes.from_now, supplier.id)
  end

  def create_product_update_jobs
    # Shuffling input products to minimize any concurrency related issues with
    # permalink creation.
    products.shuffle.each do |product|
      InventoryProductUpdateJob.perform_in(1.minute, product, supplier.id, options.slice(:update_products))
    end
  end

  def update_supplier
    supplier.update_columns(last_inventory_update_at: Time.zone.now)
  end

  ##############################
  # Seven Eleven specific code #
  # ############################
  def check_and_update_sale_hours
    most_restrictive = get_most_restrictive_sale_hours(@sale_hours)

    SevenEleven::UpdateAlcoholSaleHoursJob.perform_async(@supplier.id, most_restrictive.to_json) if most_restrictive.present?
  end

  def get_most_restrictive_sale_hours(sale_hours)
    new_sale_hours = organize_sale_hours_hash(sale_hours)
    new_sale_hours.each_key do |day|
      new_sale_hours[day] = clean_hour_overlaps(remove_outsiders(new_sale_hours[day]))
    end

    new_sale_hours
  end

  # Removes the hours that doesn't represent more than 10% of the products
  def remove_outsiders(hours)
    count_hash = {}

    hours.each do |hour|
      # Ignores periods in the early morning
      next if Time.zone.parse(hour[1]) <= Time.zone.parse('6:00')

      key = "#{hour[0]}-#{hour[1]}"
      count_hash[key] ||= 0
      count_hash[key] += 1
    end

    count_hash = count_hash.filter do |_key, count|
      count / hours.size.to_f > 0.1
    end

    count_hash.keys.map { |k| k.split('-') }
  end

  def clean_hour_overlaps(hours)
    output = []

    until hours.empty?
      first_period = hours[0]

      next if first_period.nil?

      fp_start_time = Time.zone.parse(first_period[0])
      fp_end_time = Time.zone.parse(first_period[1])

      overlaps = hours.select do |period|
        start_time = Time.zone.parse(period[0])
        end_time = Time.zone.parse(period[1])

        (start_time >= fp_start_time && start_time <= fp_end_time) ||
          (fp_start_time >= start_time && fp_start_time <= end_time) ||
          (end_time >= fp_start_time && end_time <= fp_end_time) ||
          (fp_end_time >= start_time && fp_end_time <= end_time)
      end

      if overlaps.size == 1
        output << first_period
        hours.delete(first_period)
        next
      end

      hours -= overlaps

      mrp = most_restrictive_period(overlaps)
      output << mrp unless mrp[0] == mrp[1]
    end

    output
  end

  def most_restrictive_period(periods)
    max_start_time = periods[0][0]
    min_end_time = periods[0][1]

    periods.each do |period|
      start_time = period[0]
      end_time = period[1]
      max_start_time = start_time if Time.zone.parse(start_time) > Time.zone.parse(max_start_time)
      min_end_time = end_time if Time.zone.parse(end_time) < Time.zone.parse(min_end_time)
    end

    [max_start_time, min_end_time]
  end

  def organize_sale_hours_hash(sale_hours)
    new_sale_hours = {}

    sale_hours.each do |sale_hour|
      key = sale_hour['day_index'].downcase.to_sym

      next if sale_hour['hours'].nil?

      sale_hour['hours'].as_json.each do |hour|
        new_sale_hours[key] ||= []
        start_time = SevenEleven::ServiceHelper.convert_ampm_to_24h(hour['start_time'])
        end_time = SevenEleven::ServiceHelper.convert_ampm_to_24h(hour['end_time'])

        new_sale_hours[key] << [start_time, end_time]
      end
    end

    new_sale_hours
  end
end
