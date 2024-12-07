# == Schema Information
#
# Table name: product_contents
#
#  id                         :integer          not null, primary key
#  template                   :integer
#  primary_background_color   :string(255)
#  secondary_background_color :string(255)
#  active                     :boolean          default(FALSE), not null
#  created_at                 :datetime
#  updated_at                 :datetime
#  video_mp4_file_name        :string(255)
#  video_mp4_content_type     :string(255)
#  video_mp4_file_size        :integer
#  video_mp4_updated_at       :datetime
#  video_poster_file_name     :string(255)
#  video_poster_content_type  :string(255)
#  video_poster_file_size     :integer
#  video_poster_updated_at    :datetime
#

class ProductContent < ActiveRecord::Base
  enum template: {
    video: 0
  }

  has_many :product_size_groupings

  has_attached_file :video_mp4, BASIC_PAPERCLIP_OPTIONS.merge(path: 'product_content/:id/video.:extension')
  has_attached_file :video_poster, BASIC_PAPERCLIP_OPTIONS.merge(path: 'product_content/:id/poster.:extension')

  validates_attachment_content_type :video_poster, content_type: %r{\Aimage/.*\Z}

  scope :active, -> { where(active: true) }
end
