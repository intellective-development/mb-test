# == Schema Information
#
# Table name: assets
#
#  id                :integer          not null, primary key
#  file_file_name    :string(255)
#  file_content_type :string(255)
#  file_file_size    :integer
#  file_updated_at   :datetime
#  key               :string(255)
#  file_fingerprint  :string(255)
#  owner_id          :integer
#  owner_type        :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#  dimensions        :string
#  pixel_density     :integer          default(2)
#

# This is intended as a more flexible alternative to the Image model. An Asset
# is an attached file of any type, with shared Paperclip options.
#
# Note that since this model may have an attached file of any type there is no
# post processing or resizing of attachments - they should be scaled/optimized
# prior to upload.
class Asset < ActiveRecord::Base
  belongs_to :owner, polymorphic: true

  has_attached_file :file, BASIC_PAPERCLIP_OPTIONS.merge(
    path: 'assets/:fingerprint.:extension',
    aws_region: ENV['AWS_REGION']
  )

  validates_attachment_presence :file
  validates_attachment_size :file, less_than: 5.megabytes
  do_not_validate_attachment_file_type :file

  validates :owner_type,    presence: true, on: :update
  validates :owner_id,      presence: true, on: :update
  validates :pixel_density, inclusion: { in: [1, 2, 3] }

  after_post_process :extract_dimensions
  before_save :guess_pixel_density

  serialize :dimensions

  def image?
    file_content_type.include?('image')
  end

  def width
    return unless image_has_dimensions?

    Integer(dimensions.split('x')[0]) / pixel_density
  end

  def height
    return unless image_has_dimensions?

    Integer(dimensions.split('x')[1]) / pixel_density
  end

  private

  def image_has_dimensions?
    image? && dimensions
  end

  def extract_dimensions
    return unless image?

    tempfile = file.queued_for_write[:original]
    unless tempfile.nil?
      geometry = Paperclip::Geometry.from_file(tempfile)
      self.dimensions = [geometry.width.to_i, geometry.height.to_i].join('x')
    end
  end

  def guess_pixel_density
    self.pixel_density = if file_file_name.include?('1x')    then 1
                         elsif file_file_name.include?('2x') then 2
                         elsif file_file_name.include?('3x') then 3
                         else
                           2 # default is @2x
                         end
  end
end
