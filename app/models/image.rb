# frozen_string_literal: true

# == Schema Information
#
# Table name: images
#
#  id                 :integer          not null, primary key
#  imageable_id       :integer
#  imageable_type     :string(255)
#  image_height       :integer
#  image_width        :integer
#  position           :integer
#  caption            :string(255)
#  photo_file_name    :string(255)
#  photo_content_type :string(255)
#  photo_file_size    :integer
#  photo_updated_at   :datetime
#  updated_at         :datetime
#  created_at         :datetime
#  photo_processing   :boolean
#  photo_fingerprint  :string(255)
#
# Indexes
#
#  idx_images_type_id                               (id,imageable_id,imageable_type)
#  index_images_on_imageable_id_and_imageable_type  (imageable_id,imageable_type)
#  index_images_on_imageable_type                   (imageable_type)
#

require 'paperclip'

class Image < ActiveRecord::Base
  belongs_to :imageable, polymorphic: true, touch: true

  has_attached_file :photo,
                    PAPERCLIP_STORAGE_OPTS ##  this constant is in /config/environments/*.rb
  process_in_background :photo, processing_image_url: '/images/processing.png'

  validates_attachment_presence :photo
  validates_attachment_size :photo, less_than: 5.megabytes
  validates_attachment_content_type :photo, content_type: ['image/jpeg', 'image/jpg', 'image/png', 'image/gif']

  validates :imageable_type,  presence: true, on: :update
  validates :imageable_id,    presence: true, on: :update
  validate :validate_photo

  attr_accessor :photo_link

  default_scope -> { order('position') }

  # save the w,h of the original image (from which others can be calculated)
  after_post_process :find_dimensions
  MAIN_LOGO = 'logo'

  def photo_from_link=(val)
    if val.present?
      self.photo_link = val
      begin
        uri = URI.parse(val)
        self.photo = uri.open(allow_redirections: true, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
        photo.instance_write :file_name, "#{File.basename(val).slice(0, 10)}#{File.extname(val).slice(0, 4)}"
      rescue StandardError
        errors.add(:attachment, 'Invalid URL')
      end
    end
  end

  def photo_from_link
    photo_link || ''
  end

  # this will be called after an image is uploaded.
  # => it will set the width and height of the image.
  # => It will not save the object
  #
  # @param [none]
  # @return [none] but does set the height and width
  def find_dimensions
    temporary = photo.queued_for_write[:original]
    filename = temporary.path unless temporary.nil?
    filename = photo.path if filename.blank?
    geometry = Paperclip::Geometry.from_file(filename)
    self.image_width  = geometry.width
    self.image_height = geometry.height
  end

  # if there are errors from the plugin, then add a more meaningful message
  def validate_photo
    unless photo.errors.empty?
      # uncomment this to get rid of the less-than-useful interrim messages
      # errors.clear
      errors.add :attachment, "Paperclip returned errors for file '#{photo_file_name}' - check ImageMagick installation or image source file."
      false
    end
  end
end
