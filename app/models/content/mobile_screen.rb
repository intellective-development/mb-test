# == Schema Information
#
# Table name: content_mobile_screens
#
#  id          :integer          not null, primary key
#  name        :string           not null
#  description :string
#  active      :boolean          default(TRUE), not null
#  created_at  :datetime
#  updated_at  :datetime
#  platform    :integer
#

class Content::MobileScreen < ActiveRecord::Base
  has_many :modules, class_name: 'Content::MobileModule', foreign_key: 'content_mobile_screen_id', inverse_of: 'screen'
  enum platform: {
    mobile: 0,
    web: 1
  }

  validates :name, presence: true, uniqueness: true

  scope :active, -> { where(active: true) }

  accepts_nested_attributes_for :modules, reject_if: proc { |attributes| attributes['internal_name'].blank? }, allow_destroy: true
end
