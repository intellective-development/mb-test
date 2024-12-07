# == Schema Information
#
# Table name: feature_items
#
#  id         :integer          not null, primary key
#  feature    :string           not null
#  status     :integer          default(0), not null
#  created_at :datetime
#  updated_at :datetime
#

class FeatureItem < ActiveRecord::Base
  has_many :suppliers, through: :supplier_feature_items
  has_many :supplier_feature_items, dependent: :destroy
end
