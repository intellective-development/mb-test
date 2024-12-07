# == Schema Information
#
# Table name: product_grouping_stores
#
#  permalink                    :string(255)
#  product_grouping_id          :integer          primary key
#  product_content_id           :integer
#  product_type_id              :integer
#  brand_id                     :integer
#  brand_permalink              :string(255)
#  brand_name                   :string
#  product_name                 :string
#  hierarchy_category_name      :string(255)
#  hierarchy_category_permalink :string
#  hierarchy_type_name          :string(255)
#  hierarchy_type_permalink     :string
#  hierarchy_subtype_name       :string(255)
#  hierarchy_subtype_permalink  :string
#  display_name                 :string(255)
#  description                  :text
#  tag_names                    :string           is an Array
#  properties                   :hstore           is an Array
#  image_id                     :integer
#  image_file_name              :string(255)
#  imageable_product_type_id    :integer
#  state                        :string(255)
#

class ProductGroupingStoreView < ActiveRecord::Base
  self.table_name  = 'product_grouping_stores'
  self.primary_key = 'product_grouping_id'

  has_many :variant_views, class_name: 'ProductGroupingVariantStoreView', foreign_key: 'product_grouping_id'
  has_many :product_views, class_name: 'ProductGroupingExternalProductView', foreign_key: 'product_grouping_id'
  belongs_to :product_size_grouping, foreign_key: 'product_grouping_id'
  belongs_to :product_type
  # Those 3 methods will return nil always
  belongs_to :hierarchy_category, class_name: 'ProductType'
  belongs_to :hierarchy_subtype,  class_name: 'ProductType'
  belongs_to :hierarchy_type,     class_name: 'ProductType'
  belongs_to :brand

  scope :retrieve_with_variants, lambda { |product_grouping_ids, supplier_ids, variant_order_type = 'volume'|
    variant_order_scope = "order_by_#{variant_order_type}"

    includes(:variant_views).joins(:variant_views)
                            .merge(input_grouping_order(product_grouping_ids))
                            .merge(ProductGroupingVariantStoreView.send(variant_order_scope).where_groupings_and_suppliers(product_grouping_ids, supplier_ids))
                            .where(product_grouping_id: product_grouping_ids)
                            .where('product_grouping_suppliers_variants.product_grouping_id in (?)', product_grouping_ids)
                            .where('product_grouping_suppliers_variants.supplier_id in (?)', supplier_ids)
  }

  scope :retrieve_from_variants, lambda { |product_grouping_ids, variant_ids, supplier_ids, variant_order_type = 'volume'|
    v_ids = variant_ids.map(&:to_i)
    variant_order_scope = "order_by_#{variant_order_type}"

    includes(:variant_views).joins(:variant_views)
                            .merge(ProductGroupingVariantStoreView.send(variant_order_scope).order(:price))
                            .where(product_grouping_id: product_grouping_ids)
                            .where('product_grouping_suppliers_variants.variant_id in (?)', variant_ids)
                            .where('product_grouping_suppliers_variants.supplier_id in (?)', supplier_ids)
                            .index_by { |view| view.variant_views[0].variant_id }
                            .values_at(*v_ids)
                            .compact
  }

  scope :retrieve_without_variants, lambda { |product_grouping_ids|
    where(product_grouping_id: product_grouping_ids).input_grouping_order(product_grouping_ids)
  }

  scope :retrieve_with_products, lambda { |product_grouping_ids|
    includes(:product_views).joins(:product_views)
                            .merge(input_grouping_order(product_grouping_ids))
                            .merge(ProductGroupingExternalProductView.order_by_volume)
                            .where(product_grouping_id: product_grouping_ids)
                            .where('product_grouping_external_products.product_grouping_id in (?)', product_grouping_ids)
  }

  # I'm assuming this and the one in orderByVolume concern can be improved with pure SQL
  scope :input_grouping_order, lambda  { |product_grouping_ids|
    sorting = product_grouping_ids.map do |value|
      "#{table_name}.product_grouping_id='#{value}' desc"
    end
    order(Arel.sql(sorting.join(', ')))
  }

  def readonly?
    true
  end

  def entity(options = {})
    Entity.new(self, options)
  end

  def to_hash
    entity.as_json
  end

  def image_url(size = :product)
    ProductImageUrlService.get_url(image_id, image_file_name, imageable_product_type_id, size)
  end

  def deals_query_params
    Hash.new.tap do |hash| # rubocop:disable Style/EmptyLiteral
      hash[:product_groupings] = Array(product_grouping_id)
      hash[:product_types] = product_type.self_and_ancestor_ids if product_type
      hash[:brands] = Deal.for_types('Brand').where("subject_id IN (#{Brand.parent_subquery(brand_id)})") if brand_id
    end
  end

  def deals
    @deals ||= Deals::QueryBuilder.new(deals_query_params).call
  end

  def deal_picker(supplier)
    @deal_picker ||= {}
    @deal_picker[supplier&.id] ||= Deals::PresentableDealPicker.new(deals.available_and_active, is_alcohol: product_type&.is_alcohol?, state_abbreviation: supplier.nil? ? first_supplier_address&.state_abbr_name : supplier.address&.state_abbr_name)
    @picker = @deal_picker[supplier&.id]
  end

  def presentable_deals(is_reindex = false, supplier = nil)
    @presentable_deals = [
      deal_picker(supplier).public_send(is_reindex ? :all_of_type : :first_of_type, FreeShipping),
      deal_picker(supplier).all_of_type(Percentage),
      deal_picker(supplier).all_of_type(MonetaryValue)
    ].each_with_object([]) { |deals, array| array.concat(Array(deals)) if deals.present? }
  end

  def first_supplier_id
    @first_supplier_id ||= variant_views.first&.supplier_id
  end

  # TODO: potential performance bottleneck
  # TODO: do we want to use the most common supplier id?
  def first_supplier_variants
    variant_views.select { |v| v.supplier_id == first_supplier_id }
  end

  def first_supplier_address
    @first_supplier_address = Address.supplier.find_by(addressable_id: first_supplier_id)
  end

  def gift_card?
    product_type&.is_gift_card?
  end

  # DO NOT add anything to this that is now in the postgres view.
  # Your puny ruby associations will slow down my SQL.
  class Entity < Grape::Entity
    expose :product_grouping_id, as: :id
    expose :display_name, as: :name do |grouping_view, options|
      options[:product]&.product_trait&.title.presence || grouping_view.display_name
    end
    expose :product_name do |grouping_view, options|
      options[:product]&.product_trait&.title.presence || grouping_view.product_name
    end
    expose :description
    expose :tags do |grouping_view|
      grouping_view.tag_names || []
    end
    ### ITEMS BELOW CAN BE REMOVED ONCE BRAND PLPS SHIP ###
    expose :hierarchy_type_name, as: :type
    expose :hierarchy_category_name, as: :category
    expose :brand_name, as: :brand
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
      expose :brand_name, as: :name
    end
    expose :thumb_url do |grouping_view, options|
      options[:product]&.product_trait&.main_image_url.presence || grouping_view.image_url(:small)
    end
    expose :image_url do |grouping_view, options|
      # TODO: Would it be better to do this based on Doorkeeper Application ID? (YES!)
      image_style =
        case options[:platform]
        when 'ios', 'iphone', 'ipad', 'ipod', 'android'
          :ios_product
        else
          :product
        end

      options[:product]&.product_trait&.main_image_url.presence || grouping_view.image_url(image_style)
    end
    expose :properties do |grouping_view|
      grouping_view.properties || []
    end
    expose :permalink
    expose :product_content do |grouping_view|
      grouping_view.product_content_id.present?
    end
    expose :gift_card_theme, if: ->(instance, _options) { instance.gift_card? } do |grouping_view|
      ConsumerAPIV2::Entities::GiftCardTheme.new(grouping_view.product_size_grouping.gift_card_theme)
    end
    expose :variants do |grouping_view, options|
      records = options[:exclude_variants] ? [] : grouping_view.variant_views
      ProductGroupingVariantStoreView::Entity.represent records, business: options[:business]
    end
    expose :external_products, with: ProductGroupingExternalProductView::Entity do |grouping_view|
      options[:include_products] ? grouping_view.product_views : []
    end
    expose :supplier_id, if: ->(_status, _options) { !external_context? } do |grouping_view|
      grouping_view.first_supplier_id unless options[:exclude_variants]
    end
    expose :deals, with: ConsumerAPIV2::Entities::Deal, if: ->(_status, _options) { !external_context? } do |grouping_view|
      options[:exclude_variants] ? [] : grouping_view.presentable_deals
    end
    expose :browse_type do |_grouping_view|
      options[:include_products] ? 'EXTERNAL' : 'INTERNAL'
    end
    expose :product_grouping_permalink do |grouping_view|
      "https://#{ENV['ASSET_HOST']}/store/product/#{grouping_view.permalink}".sub('https://https://', 'https://')
    end

    def external_context?
      options[:include_products] && options[:exclude_variants]
    end
  end
end
