# == Schema Information
#
# Table name: reporting_types
#
#  id         :integer          not null, primary key
#  name       :string(255)      not null
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_reporting_types_on_name  (name) UNIQUE
#

class ReportingType < ActiveRecord::Base
  has_many :coupons

  validates :name, presence: true, uniqueness: true
end
