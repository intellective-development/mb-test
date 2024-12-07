# == Schema Information
#
# Table name: gift_card_themes
#
#  id            :integer          not null, primary key
#  name          :string
#  display_name  :string
#  active        :boolean
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  is_custom     :boolean          default(FALSE)
#  storefront_id :integer          not null
#  sellable_type :string
#  sellable_ids  :integer          default([]), is an Array
#
# Indexes
#
#  index_gift_card_themes_on_storefront_id  (storefront_id)
#
# Foreign Keys
#
#  fk_rails_...  (storefront_id => storefronts.id)
#
class GiftCardTheme < ActiveRecord::Base
  has_many :images, as: :imageable, dependent: :destroy
  has_one :product_size_grouping
  belongs_to :storefront

  accepts_nested_attributes_for :product_size_grouping
  accepts_nested_attributes_for :images, reject_if: proc { |t| (t['photo'].nil? && t['photo_from_link'].blank?) }, allow_destroy: true

  validates :name, presence: true, uniqueness: true
  validates :display_name, presence: true

  after_save :update_grouping!

  def update_grouping!
    if product_size_grouping.present?
      product_size_grouping.update(name: name, meta_description: name)
    else
      ProductSizeGrouping.create(name: name, meta_description: name, brand: gift_card_brand, product_type: gift_card_type, hierarchy_category: gift_card_type, searchable: false, gift_card_theme_id: id)
    end
    GiftCardThemeUpdaterWorker.perform_async(id)
  end

  def theme_image_url
    Rails.cache.fetch("gift_card_theme::#{id}::theme_image_url::#{updated_at}", expires_in: 24.hours) do
      product_size_grouping&.featured_image(:original)
    end
  end

  def thumb_image_url
    Rails.cache.fetch("gift_card_theme::#{id}::thumb_image_url::#{updated_at}", expires_in: 24.hours) do
      images.empty? ? '' : images.first.photo.url(:original)
    end
  end

  def gift_card_type
    ProductType.find_by(name: 'gift card') || ProductType.create(name: 'gift card', searchable: false, permalink: 'gift-card')
  end

  def gift_card_brand
    Brand.find_or_create_by(name: 'Minibar')
  end
end
