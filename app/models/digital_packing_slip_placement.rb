# == Schema Information
#
# Table name: digital_packing_slip_placements
#
#  id                 :integer          not null, primary key
#  storefront_id      :integer
#  title              :string
#  link               :string
#  tag                :string           not null
#  description        :text
#  image_file_name    :string
#  image_content_type :string
#  image_file_size    :bigint(8)
#  image_updated_at   :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_digital_packing_slip_placements_on_storefront_id          (storefront_id)
#  index_digital_packing_slip_placements_on_tag_and_storefront_id  (tag,storefront_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (storefront_id => storefronts.id)
#

class DigitalPackingSlipPlacement < ActiveRecord::Base
  belongs_to :storefront, optional: false

  has_attached_file :image, BASIC_PAPERCLIP_OPTIONS.merge(path: 'digital_packing_slip_placements/:id/:style/:basename.:extension')
  validates_attachment :image, content_type: { content_type: ['image/jpg', 'image/jpeg', 'image/png', 'image/gif'] }

  validates :tag, presence: true
  validates :tag, uniqueness: { scope: :storefront_id }

  enum tag: {
    storefront_spot_1: 'storefront_spot_1',
    storefront_spot_2: 'storefront_spot_2',
    storefront_spot_3: 'storefront_spot_3',
    header_spot_1: 'header_spot_1',
    brand_spot_1: 'brand_spot_1',
    brand_spot_2: 'brand_spot_2',
    brand_spot_3: 'brand_spot_3',
    brand_spot_4: 'brand_spot_4',
    qa_spot: 'qa_spot'
  }

  scope :by_storefront_id, ->(storefront_id) { where(storefront_id: storefront_id) }
  scope :by_title, ->(title) { where('title ILIKE :title', title: "%#{title}%") }

  def image_url
    image&.url
  end
end
