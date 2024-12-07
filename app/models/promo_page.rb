# == Schema Information
#
# Table name: promo_pages
#
#  id                            :integer          not null, primary key
#  name                          :string(255)
#  description                   :text
#  promo_code                    :string(255)
#  blurb                         :string(255)
#  created_at                    :datetime
#  updated_at                    :datetime
#  logo_file_name                :string(255)
#  logo_content_type             :string(255)
#  logo_file_size                :integer
#  logo_updated_at               :datetime
#  slug                          :string(255)
#  background_image_file_name    :string(255)
#  background_image_content_type :string(255)
#  background_image_file_size    :integer
#  background_image_updated_at   :datetime
#  direct_link                   :string(255)
#  deleted_at                    :datetime
#

class PromoPage < ActiveRecord::Base
  extend FriendlyId

  scope :active,      -> { where(deleted_at: nil) }

  friendly_id :name,  use: %i[slugged finders]

  has_attached_file :logo, {
    path: 'promo_pages/:id/:style/logo.:extension',
    styles: {
      retina: '1088x160>',
      standard: '544x80>'
    },
    default_url: 'homepage/promo_logo_missing.png'
  }.merge(BASIC_PAPERCLIP_OPTIONS)

  has_attached_file :background_image, {
    path: 'promo_pages/:id/:style/bg.:extension',
    styles: {
      standard: '1200x1800>'
    }
  }.merge(BASIC_PAPERCLIP_OPTIONS)

  validates_attachment_content_type :logo, content_type: %r{\Aimage/.*\Z}
  validates_attachment_content_type :background_image, content_type: %r{\Aimage/.*\Z}

  def promo?
    promo_code.present?
  end

  def logo?
    logo.present?
  end

  def background_image?
    background_image.present?
  end
end
