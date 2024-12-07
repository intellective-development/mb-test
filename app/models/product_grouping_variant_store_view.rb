# == Schema Information
#
# Table name: product_grouping_suppliers_variants
#
#  variant_id               :integer          primary key
#  permalink                :string(255)
#  product_grouping_view_id :text
#  product_grouping_id      :integer
#  supplier_id              :integer
#  product_id               :integer
#  upc                      :string(255)
#  in_stock                 :integer
#  price                    :float
#  original_price           :float
#  case_eligible            :boolean
#  two_for_one              :decimal(8, 2)
#  image_id                 :integer
#  image_file_name          :string(255)
#  item_volume              :string(255)
#  short_pack_size          :string(255)
#  short_volume             :string(255)
#  container_type           :string(255)
#  overridable              :boolean
#  sku                      :string(255)
#  custom_promo             :json
#

# module ApiViews
class ProductGroupingVariantStoreView < ActiveRecord::Base
  include ProductPriorityScope
  self.table_name  = 'product_grouping_suppliers_variants'
  self.primary_key = 'variant_id'

  belongs_to :grouping_view, class_name: 'ProductGroupingStoreView', foreign_key: 'product_grouping_id'
  has_one :product_type, through: :grouping_view
  belongs_to :variant
  belongs_to :supplier
  belongs_to :product
  has_many :deals, through: :supplier
  has_many :volume_discounts, through: :supplier
  has_one  :address, through: :supplier

  delegate :permalink_with_grouping, to: :product, allow_nil: true

  scope :where_groupings_and_suppliers, lambda { |product_grouping_ids, supplier_ids|
    where(product_grouping_id: product_grouping_ids, supplier_id: supplier_ids)
  }
  scope :order_by_price_asc, -> { order(price: :asc) }
  scope :order_by_price_desc, -> { order(price: :desc) }

  def in_stock
    return read_attribute(:in_stock) if Feature[:skip_max_quantity_per_order_feature].enabled? || product.max_quantity_per_order.nil?

    [read_attribute(:in_stock), product.max_quantity_per_order].min
  end

  def entity
    Entity.new(self)
  end

  def to_hash
    entity.as_json
  end

  def image_url(size = :product)
    ProductImageUrlService.get_product_image_url(image_id, image_file_name, size) if image_id && image_file_name
  end

  def image_url_with_fallback(size = :product)
    image_url(size) || grouping_view.image_url(size)
  end

  def presentable_deal_picker
    @picker = Deals::PresentableDealPicker.new(deals.available_and_active, is_alcohol: product_type.is_alcohol?, state_abbreviation: address.state_abbr_name)
  end

  def presentable_deals(is_reindex = false)
    deals = []
    if case_eligible?
      if is_reindex
        volume_discounts = presentable_deal_picker.all_of_type(VolumeDiscount)
        deals.concat(volume_discounts) unless volume_discounts.nil?
      else
        deal = presentable_deal_picker.first_of_type(VolumeDiscount)
        deals << deal unless deal.nil?
      end
    end
    deals.concat(add_two_for_one_to_deals) unless two_for_one.nil?
    deals
  end

  def equal_amount?(deals, two_for_one_deal)
    deals.any? { |deal| deal.amount == two_for_one_deal.amount }
  end

  def add_two_for_one_to_deals
    deals = []
    presentable_deal_picker.all_of_type(TwoForOneDiscount).each do |two_for_one_deal|
      # two_for_one_deal.amount - two_for_one.to_f - check if the deal match for variant
      # equal_amount?(deals, two_for_one_deal) - check if exist two_for_one deals with duplicate amount
      deals << two_for_one_deal if !two_for_one_deal.nil? && two_for_one_deal.amount == two_for_one.to_f && !equal_amount?(deals, two_for_one_deal)
    end
    deals
  end

  # DO NOT add anything to this that is not in the postgres view.
  # Your puny ruby associations will slow down my SQL.
  class Entity < Grape::Entity
    expose :variant_id, as: :id
    expose :price do |view, options|
      # We expect business object to be passed in options.
      business = options[:business]

      BusinessVariantPriceService.new(
        view.price,
        view.variant.real_price,
        view.supplier_id,
        business,
        view.variant
      ).call
    end
    expose :original_price
    expose :in_stock do |view|
      view.variant&.product&.max_quantity_per_order&.positive? ? view.variant.product.max_quantity_per_order : view.in_stock
    end
    expose :container_type
    expose :subgroup_id, &:container_type
    expose :item_volume, as: :volume
    expose :short_pack_size
    expose :short_volume
    expose :thumb_url do |variant_view|
      variant_view.product&.product_trait&.main_image_url.presence || variant_view.image_url_with_fallback(:small)
    end
    expose :image_url do |variant_view, options|
      # TODO: Would it be better to do this based on Doorkeeper Application ID?
      image_style =
        case options[:platform]
        when 'ios', 'iphone', 'ipad', 'ipod', 'android'
          :ios_product
        else
          :product
        end

      variant_view.product&.product_trait&.main_image_url.presence || variant_view.image_url_with_fallback(image_style)
    end
    expose :permalink
    expose :supplier_id
    expose :product_id
    expose :presentable_deals, as: :deals, with: ConsumerAPIV2::Entities::Deal
    expose :two_for_one
    expose :upc
    expose :overridable
    expose :sku
    expose :custom_promo
    expose :product_permalink do |variant_view|
      "https://#{ENV['ASSET_HOST']}/store/product/#{variant_view.permalink_with_grouping}".sub('https://https://', 'https://')
    end

    expose :pre_sale_expectation
    expose :weight
    expose :engraving_location
  end

  def pre_sale_expectation
    product&.product_trait&.pre_sale_expectation
  end

  def weight
    product&.product_trait&.weight
  end

  def engraving_location
    product&.product_trait&.engraving_location
  end

  def subgroup_id
    container_type
  end
end
