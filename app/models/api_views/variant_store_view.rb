# == Schema Information
#
# Table name: variant_stores
#
#  variant_id                :integer          primary key
#  product_id                :integer
#  inventory_id              :integer
#  product_type_id           :integer
#  display_name              :string
#  price                     :float
#  original_price            :float
#  description               :text
#  sku                       :string(255)
#  case_eligible             :boolean
#  volume                    :string(255)
#  volume_value              :decimal(, )
#  volume_unit               :text
#  container_count           :integer
#  container_type            :text
#  brand_name                :string(255)
#  product_name              :text
#  in_stock                  :integer
#  tag_names                 :string           is an Array
#  category_name             :string(255)
#  product_type_name         :string(255)
#  properties                :hstore           is an Array
#  supplier_id               :integer
#  permalink                 :string(255)
#  image_id                  :integer
#  image_file_name           :string(255)
#  imageable_product_type_id :integer
#

module ApiViews
  class VariantStoreView < ActiveRecord::Base
    self.table_name  = 'variant_stores'
    self.primary_key = 'variant_id'

    belongs_to :variant
    belongs_to :product
    belongs_to :inventory
    # belongs_to :image, foreign_key: :product_image_id
    # belongs_to :product_type, foreign_key: :image_product_type_id

    delegate :permalink_with_grouping, to: :product, allow_nil: true
    delegate :product_size_grouping_permalink, to: :product, allow_nil: true

    def image_url(size = :product)
      if image_id && image_file_name
        # this takes about 1/3 of the time when generating entity
        # If we ever do make the image filepaths more manageable, it would be nice
        # to refactor this out.
        image_file_name_jpg = "#{File.basename(image_file_name, '.*')}.jpg"
        "#{image_url_base}/products/#{image_id}/#{size}/#{image_file_name_jpg}"
      elsif imageable_product_type_id
        "#{image_url_base}/product_types/#{imageable_product_type_id}/#{size}.jpg"
      else
        "#{ENV['AWS_BUCKET']}/assets/product_defaults/#{size}.jpg"
      end
    end

    def image_url_base
      paperclip_options = Paperclip::Attachment.default_options
      if paperclip_options[:s3_host_alias]
        "#{paperclip_options[:s3_protocol]}://#{paperclip_options[:s3_host_alias]}"
      else
        paperclip_options[:fog_host].to_s
      end
    end

    def entity
      Entity.new(self)
    end

    def to_hash
      JSON.parse(entity.to_json)
    end

    # DO NOT add anything to this that is now in the postgres view.
    # Your puny ruby associations will slow down my SQL.
    class Entity < Grape::Entity
      expose :id
      expose :display_name, as: :name
      expose :brand_name, as: :brand
      expose :product_name, as: :product_name
      expose :price
      expose :original_price
      expose :description
      expose :sku
      expose :volume do |variant_view|
        String(variant_view.volume)
      end
      expose :volume_attributes do
        expose :volume_value, &:volume_value
        expose :volume_unit, &:volume_unit
        expose :container_count, &:container_count
        expose :container_type, &:container_type
      end
      expose :in_stock do |variant_view|
        variant_view.product&.max_quantity_per_order&.positive? ? variant_view.product.max_quantity_per_order : variant_view.in_stock
      end
      expose :tags do |variant_view|
        variant_view.tag_names || []
      end
      expose :category_name, as: :category
      expose :product_type_name, as: :type
      expose :product_type_id, as: :type_id
      expose :thumb_url do |variant_view|
        variant_view.image_url(:small)
      end
      expose :image_url do |variant_view|
        variant_view.image_url(:product)
      end
      expose :properties do |variant_view|
        variant_view.properties || []
      end
      expose :supplier_id
      expose :permalink
      expose :product_id
      expose :product_grouping_permalink do |variant_view|
        "https://#{ENV['ASSET_HOST']}/store/product/#{variant_view.product_size_grouping_permalink}".sub('https://https://', 'https://')
      end
      expose :product_permalink do |variant_view|
        "https://#{ENV['ASSET_HOST']}/store/product/#{variant_view.permalink_with_grouping}".sub('https://https://', 'https://')
      end
    end
  end
end
