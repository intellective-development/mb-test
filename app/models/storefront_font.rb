# == Schema Information
#
# Table name: storefront_fonts
#
#  id                     :integer          not null, primary key
#  storefront_id          :integer
#  name                   :string
#  font_type              :integer          default("serif")
#  font_file_file_name    :string
#  font_file_content_type :string
#  font_file_file_size    :bigint(8)
#  font_file_updated_at   :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
class StorefrontFont < ActiveRecord::Base
  belongs_to :storefront

  enum font_type: { serif: 0, sans_serif: 1 }

  has_attached_file :font_file, validate_media_type: false
  validates_attachment :font_file, content_type: { content_type: ['font/woff'] }

  validates :name, presence: true
  validates :font_type, presence: true

  scope :by_name, ->(name) { where('name ILIKE :name', name: "%#{name}%") }
  scope :by_storefront_id, ->(storefront_id) { where(storefront_id: storefront_id) }
end
