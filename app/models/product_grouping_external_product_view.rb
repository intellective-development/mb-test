# == Schema Information
#
# Table name: product_grouping_external_products
#
#  product_id          :integer          primary key
#  permalink           :string(255)
#  product_grouping_id :integer
#  brand_id            :integer
#  min_price           :float
#  max_price           :float
#  image_id            :integer
#  image_file_name     :string(255)
#  item_volume         :string(255)
#  short_pack_size     :string(255)
#  short_volume        :string(255)
#  container_type      :string(255)
#  popularity          :integer
#  featured            :bigint(8)
#

class ProductGroupingExternalProductView < ActiveRecord::Base
  include ProductPriorityScope
  self.table_name  = 'product_grouping_external_products'
  self.primary_key = 'product_id'

  belongs_to :grouping_view, class_name: 'ProductGroupingStoreView', foreign_key: 'product_grouping_id'
  has_one :product_type, through: :grouping_view
  belongs_to :product
  belongs_to :product_groupings

  scope :where_groupings, lambda { |product_grouping_ids|
    where(product_grouping_id: product_grouping_ids)
  }

  def entity
    Entity.new(self)
  end

  def to_hash
    entity.as_json
  end

  def image_url(size = :product)
    ProductImageUrlService.get_product_image_url(image_id, image_file_name, size) if image_id && image_file_name
  end

  def external_product_data
    {
      product_id: product_id,
      permalink: permalink,
      min_price: min_price,
      max_price: max_price,
      container_type: container_type,
      volume: item_volume,
      short_volume: short_volume,
      short_pack_size: short_pack_size,
      thumb_url: image_url(:small),
      image_url_web: image_url(:product),
      image_url_mobile: image_url(:ios_product)
    }
  end

  # DO NOT add anything to this that is not in the postgres view.
  # Your puny ruby associations will slow down my SQL.
  class Entity < Grape::Entity
    expose :product_id, as: :id
    expose :permalink
    expose :min_price
    expose :max_price
    expose :container_type
    expose :item_volume, as: :volume
    expose :short_pack_size
    expose :short_volume
    expose :thumb_url do |product_view|
      product_view.image_url(:small)
    end
    expose :image_url do |product_view, options|
      # TODO: Would it be better to do this based on Doorkeeper Application ID?
      image_style =
        case options[:platform]
        when 'ios', 'iphone', 'ipad', 'ipod', 'android'
          :ios_product
        else
          :product
        end

      product_view.image_url(image_style)
    end
  end
end
