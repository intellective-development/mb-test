# TODO: JM: decompose this into individual cleaners and don't make concerns out of them.
# they bloat so much of the app.
module DataCleaner
  extend ActiveSupport::Concern

  require 'data_cleaners'

  def parse_volume(parsable, category = '')
    if %w[beer mixers].include?(category)
      parse_beer_volume_from_name(parsable)
    else
      DataCleaners::Parser::Volume.parse(parsable)
    end
  end

  def parse_beer_volume_from_name(parsable)
    # we removed strict mode as it should always be "strict",
    # and only fill in the volume fields that are available.
    name = String(parsable).downcase
    name = name.gsub(/(fl|fluid)\b?(oz|z)\.?/, 'oz')
    name = clean_beer_pint_vols(name)

    volume = {
      item_volume: name, # let's keep the original string and store it on item_volume.
      container_count: nil,
      container_type: nil,
      volume_value: nil,
      volume_unit: nil
    }

    unit_volume = DataCleaners::Parser::Volume.identify_volume_set(name)
    container = DataCleaners::Parser::Volume.identify_container_type(name)
    bottle_count = DataCleaners::Parser::Volume.identify_container_count(name)

    merger = {
      item_volume: name, # for merge_volume sanity
      container_count: bottle_count.nil? ? nil : bottle_count.to_i,
      container_type: container,
      volume_value: unit_volume[0].nil? ? nil : unit_volume[0].to_f,
      volume_unit: unit_volume[1]
    }
    DataCleaners::Parser::Volume.merge_volumes(volume, merger)
  end

  def clean_beer_pint_vols(name)
    name = name.downcase
    name = name.gsub(/1\s*(pt|pint)(\s|\.)?(9|9\.4)\s*((fl|fluid)?(\.|\s)?oz)/, '750ml')
    name = name.gsub(/1\s*(pt|pint)(\s|\.)?6\s*((fl|fluid)?(\.|\s)?oz)/, '22oz')
    name.gsub(/1\s*(pt|pint)(\s|\.)?8\s*((fl|fluid)?(\.|\s)?oz)/, '24oz')
  end

  def parse_type(parsable)
    parsable.downcase
  rescue StandardError
    nil
  end

  # Moves all products from one brand to another and deletes one.
  def consolidate_brand(new_brand_id, old_brand_id)
    new_brand = Brand.find(new_brand_id)
    old_brand = Brand.find(old_brand_id)

    unless new_brand.nil? || old_brand.nil?
      old_brand.products.each do |p|
        p.brand_id = new_brand.id
        p.save
      end
      old_brand.delete if Brand.find(old_brand_id).products.empty?
    end
  end

  def parse_type_hierarchy(name, categories = []) # I HIGHLY recommend that you specify categories
    category_types = {
      wine: ProductType.find_by(permalink: 'wine').children.pluck(:name),
      beer: ProductType.find_by(permalink: 'beer').children.pluck(:name),
      liquor: ProductType.find_by(permalink: 'liquor').children.pluck(:name)
    }
    name = String(name).downcase
    categories = Array(categories)
    categories = category_types.keys if categories.empty? # use all if none specified
    hierarchy = { category: nil, type: nil, subtype: nil }

    categories.each do |category|
      type_list = category_types[category.to_sym]
      t_s = parse_type_and_subtype(name, type_list)
      hierarchy = { category: category.to_s, type: t_s[:type], subtype: t_s[:subtype] } if t_s[:subtype] || (t_s[:type] && !hierarchy[:subtype]) # false if you have a subtype already and new data doesn't
    end

    hierarchy
  end

  def parse_type_and_subtype(name, type_list)
    type, subtype = nil
    type_list = Array(type_list)

    type_list.each do |type_name|
      ProductType.find_by(name: type_name).descendants.pluck(:name).each do |subtype_name|
        next unless subtype.nil? && name =~ /\b#{Regexp.quote(subtype_name).downcase}\b/ # if a subtype has been found, don't redo it

        type = type_name
        subtype = subtype_name
        subtype = nil if type.present? && type == subtype
      end
    end
    { type: type, subtype: subtype }
  end

  # Checks product name against set of canonical wine varietals and re-assigns if neccessary.
  def set_varietal(product)
    ProductType::BLESSED_VARIETALS.each do |v|
      next unless product.name.downcase.include?(v)

      product_type = ProductType.find_by(name: v)
      unless product_type.nil?
        product.product_size_grouping.product_type_id = product_type.id
        Rails.logger.info "Moved #{product.name} to #{v}" if product.save
      end
    end
  end

  def parse_varietal(parsable)
    found = nil
    ProductType::BLESSED_VARIETALS.each do |v|
      if parsable.downcase.include?(v)
        found = v
        break
      end
    end
    found
  end
end
