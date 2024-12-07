class ConsumerAPIV2::Entities::ElasticSearchProductGrouping < Grape::Entity
  expose :product_grouping_id, as: :id
  expose :name
  expose :product_name
  expose :sponsored
  expose :description
  expose :tags
  ### ITEMS BELOW CAN BE REMOVED ONCE BRAND PLPS SHIP ###
  expose :hierarchy_type_name, as: :type
  expose :hierarchy_category_name, as: :category
  expose :brand
  ### END DEPRECATION ###################################
  expose :hierarchy_category do
    expose :hierarchy_category_permalink, as: :permalink
    expose :hierarchy_category_name, as: :name
  end
  expose :hierarchy_type do
    expose :hierarchy_type_permalink, as: :permalink
    expose :hierarchy_type_name, as: :name
  end
  expose :hierarchy_subtype do
    expose :hierarchy_subtype_permalink, as: :permalink
    expose :hierarchy_subtype_name, as: :name
  end
  expose :brand_data do # TODO: rename this "brand"... eventually
    expose :brand_permalink, as: :permalink
    expose :brand, as: :name
  end
  expose :thumb_url
  expose :image_url do |grouping_view, options|
    # TODO: Would it be better to do this based on Doorkeeper Application ID? (YES!)
    image_style =
      case options[:platform]
      when 'ios', 'iphone', 'ipad', 'ipod', 'android'
        :ios_product
      else
        :product
      end
    image_style == :ios_product ? grouping_view['image_url_mobile'] : grouping_view['image_url_web']
  end
  expose :properties do |grouping_view|
    grouping_view['properties'] || []
  end
  expose :permalink
  expose :product_content do |grouping_view|
    grouping_view['product_content_id'].present?
  end
  expose :variants do |grouping_view|
    variants = options[:exclude_variants] ? [] : grouping_view['variants']
    ConsumerAPIV2::Entities::ElasticSearchProductGroupingVariant.represent(variants, options.merge({ grouping_view: grouping_view }))
  end
  expose :external_products, with: ConsumerAPIV2::Entities::ElasticSearchProductGroupingExternalProduct do |grouping_view|
    options[:include_products] ? grouping_view['external_products'] : []
  end
  expose :supplier_id, if: ->(_status, _options) { !external_context? } do |grouping_view|
    grouping_view['supplier_id'] unless options[:exclude_variants]
  end
  expose :deals, with: ConsumerAPIV2::Entities::ElasticSearchDeal, if: ->(_status, _options) { !external_context? } do |grouping_view|
    options[:exclude_variants] ? [] : grouping_view['deals']
  end
  expose :browse_type do |_grouping_view|
    options[:include_products] ? 'EXTERNAL' : 'INTERNAL'
  end

  def external_context?
    options[:include_products] && options[:exclude_variants]
  end

  def sponsored
    object[:sponsored] || false
  end
end
